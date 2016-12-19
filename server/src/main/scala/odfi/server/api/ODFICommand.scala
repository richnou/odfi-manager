package odfi.server.api

import edu.kit.ipe.adl.indesign.core.module.process.IDCommand
import edu.kit.ipe.adl.indesign.core.module.process.IDProcess
import edu.kit.ipe.adl.indesign.tcl.nx.NXObject
import odfi.server.ODFIInstallation
import java.io.File
import edu.kit.ipe.adl.indesign.tcl.TclValue
import edu.kit.ipe.adl.indesign.tcl.nx.NXObjectCacheFactory
import edu.kit.ipe.adl.indesign.core.heart.HeartTask
import edu.kit.ipe.adl.indesign.core.heart.Heart
import java.util.concurrent.Semaphore

class ODFICommand(val odfi: ODFIInstance, obj: NXObject) extends NXObject(obj) with NamedDescription {

  deriveFrom(odfi)

  // Parameters
  //---------------------
  def getState = this("getState").toString
  def isWaiting = this("isWaiting").toBoolean

  // Processes
  //----------

  var idCommand = new IDCommand(new File(this.findUpchainResource[ODFIInstallation].get.path.toFile, "bin" + File.separator + "odfi"))
  var runningProcesses = List[IDProcess]()

  def isRunning = {
    // !runningProcesses.isEmpty
    !this.getDerivedResources[ODFIInstance].isEmpty
  }

  /**
   * Create new ODFI Instance for this run
   */
  def prepareProcess = {
    /*println("Running using..."+getFullName)
    var process = idCommand.createToolProcess(getFullName)
    this.addDerivedResource(process)
    process*/

    var newODFI = this.findUpchainResource[ODFIInstallation].get.getODFIInstance(s"command-${getFullName}-run-${System.currentTimeMillis()}")
    this.addDerivedResource(newODFI)
    newODFI.onClean {

      this.removeDerivedResource(newODFI)
    }

    newODFI
  }

  def startNonBlocking = {

    var process: ODFIInstance = null

    //-- Create Task to submit for this command to run in background
    var createdBarrier = new Semaphore(0)
    var task : HeartTask[_] = new HeartTask[Option[CommandResult]] {
      
      
      def getId = s"command-${getFullName}-${hashCode}"
      def doTask = {
        try {
          //-- Prepare Process to get new ODFI instance for this command
          process = prepareProcess
       

          //-- Get Command from new ODFI
          var newProcessCommand = ODFICommand(process(s"resolveCommand ${getFullName}"), new ODFICommand(process, _)).head

          //-- Save task as derivative of the dedicated ODFI instance to be able to find it again
          process.addDerivedResource(newProcessCommand)
          
          
          //-- Signal ready
          createdBarrier.release()
          
          //-- Run
          var res = resultToCommandResult(newProcessCommand(s"run"))

          res
        } catch {
          case e: Throwable =>
            e.printStackTrace()
            throw e
        } finally {
          process.clean
        }

      }
    }

    //-- Start
    Heart.pump(task)
    
    
    //-- Wait for creation
    createdBarrier.acquire()
    println("Command ready let it run: "+process)
    process.addDerivedResource(task)
    process.getDerivedResources[ODFICommand].head

  }

  /**
   * Blocking
   */
  def startRedirectIO = {
    println("Running using..." + getFullName)
    var process = prepareProcess

    var res = resultToCommandResult(process(s"runCommand ${getFullName}"))

    //-- Clean
    process.clean

    res
    /*process.inheritIO
  
    process.startProcessAndWait*/
  }
  
  def startCurrentCommand = {
    
    var res = resultToCommandResult(this(s"run"))
    
    res
    
  }
  
  def startCurrentWithStdout(cl:String => Unit) = {
    
    var listener = this.interpreter.onWith("stream.write.stdout") {
      line : String => 
        cl(line)
    }
    try {
       resultToCommandResult(this(s"run"))
    } finally {
      this.interpreter.deregister(listener)
    }
    
  }

  def resultToCommandResult(v: TclValue): Option[CommandResult] = v match {

    case v if (v != null && v.isObjectValue && v.asObjectValue.isNXObject && v.asObjectValue.asNXObject.isNXClass("::odfi::CommandResult")) =>
      Some(new CommandResult(v.asObjectValue.asNXObject))
    case _ => None
  }

}

object ODFICommand extends NXObjectCacheFactory[ODFICommand] {

}
