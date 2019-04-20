package odfi.server

import java.io.File
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import java.nio.file.Path
import org.odfi.indesign.core.harvest.fs.FileSystemHarvester

import org.odfi.tcl.module.TCLPackageHarvester
import org.bridj.BridJ
import org.odfi.tcl.nx.NXObject
import org.odfi.tcl.integration.TclObject
import org.odfi.tcl.TclInterpreter
import org.odfi.tcl.module.TCLModule
import org.odfi.tcl.flextree.FlexNode
import odfi.server.api.ODFIInstance

object ODFIHarvester extends FileSystemHarvester {

  // this.addChildHarvester(new TCLPackageHarvester)

  /*val jvmStartFolder = new File("").getAbsoluteFile
  this.saveToAvailableResources(new HarvestedFile(jvmStartFolder.toPath()))*/

  override def doHarvest = {

    //-- Look for bin/odfi in search folders
    this.getResourcesOfExactType[HarvestedFile].foreach {
      baseFolder =>

        var odfiBin = new File(baseFolder.toPath().toFile(), "bin" + File.separator + "odfi").getAbsoluteFile
        //println("Testing ODFi for: " + odfiBin + " -- " + baseFolder)
        odfiBin.exists() match {
          case true =>
            gather(new ODFIInstallation(baseFolder.toPath()))
          case false =>
            //println("File does not exists: " + odfiBin)
        }

    }

    /* var installPath = new File(managerPath, "install")
    installPath.listFiles().filter(_.isDirectory()).foreach {
      mf =>
        var resource = gather(new Module(mf.toPath()))
       // println(s"Odfi gathering: "+resource)
      /*resource.onAdded {
          case h if(h==this) =>
            this.addPath(resource.path)
        }*/
    }*/

  }

}
class ODFIInstallation(p: Path) extends HarvestedFile(p.toAbsolutePath()) {

  //-- ODFI Instances
  var odfiInstances = Map[String, ODFIInstance]()

  def deleteAllODFIInstances = {
    odfiInstances.foreach {
      case (name,instance) => 
        this.removeDerivedResource(instance)
        instance.clean
        odfiInstances = odfiInstances - name
        
    }
  }
  
  def getODFIInstance(name: String) = odfiInstances.getOrElse(name, {

    //-- Get interpreter
    var interpreter = TCLModule.getInterpreter("odfi-" + name)
    try {

      //-- Load scripts
      interpreter.loadPackageIndexFile(new File(p.toFile(), "private/odfi-dev-tcl/tcl/pkgIndex.tcl"))
      interpreter.sourceFile(new File(p.toFile(), "private/odfi.tm"))

      //-- Create Instance
      var newInstance = new ODFIInstance(interpreter.evalString(s"::odfi::odfi $name").asObjectValue.asNXObject)

      //-- Load configs
      getMainConfigFiles.foreach {
        cfg =>
          println("Apply to main Config: " + cfg)
          newInstance.applyFileToConfig("main", cfg)
      }
      getConfigFiles.foreach {
        cfg =>
          println("Apply Config: " + cfg)
          newInstance.applyFile(cfg)
      }

      //-- Gather Modules
      newInstance("gatherModules")

      //-- Save
      this.addDerivedResource(newInstance)
      this.odfiInstances = this.odfiInstances + (name -> newInstance)

      newInstance

    } catch {
      case e: Throwable =>
        TCLModule.deleteInterpreter("odfi-" + name)
        throw e
    }

  })

  def getMainConfigFiles = new File(p.toFile(), "configs").listFiles match {
    case null => List[File]()
    case other =>
      //println("Looking to files inside: "+ p.toFile())
      other.filter(f => f.getName.endsWith(".config.default.tcl")).toList
  }
  def getConfigFiles = new File(p.toFile(), "configs").listFiles match {
    case null => List[File]()
    case other => other.filter(f => f.getName.endsWith(".config.tcl")).toList
  }
  
  // ODFI Processes
  //-----------------
  
  /*def createODFICommand = {
    
    // Look for TCL
    //TCL
    
    
  }*/

}

class Module(p: Path) extends HarvestedFile(p) {
  /*this.root
  this.local = true*/
  // Init 
  //-----------

  //-- Lib 
  var libFolder = new File(p.toFile(), "lib")
  libFolder.exists() match {
    case true =>
      //println("Found lib oflder: " + libFolder)
      System.setProperty("java.library.path", System.getProperty("java.library.path") + File.pathSeparator + libFolder)
      BridJ.addLibraryPath(libFolder.getAbsolutePath)
      //set sys_paths to null so that java.library.path will be reevalueted next time it is needed
      val sysPathsField = classOf[ClassLoader].getDeclaredField("sys_paths");
      sysPathsField.setAccessible(true);
      sysPathsField.set(null, null);
    //System.getProperty("java.library.path")
    case false =>
  }
  //-- Bin
  var binFolder = new File(p.toFile(), "bin")
  binFolder.exists() match {
    case true =>
      //println("Found bin oflder: " + binFolder)
      System.setProperty("java.library.path", System.getProperty("java.library.path") + File.pathSeparator + binFolder)
      BridJ.addLibraryPath(binFolder.getAbsolutePath)
      //set sys_paths to null so that java.library.path will be reevalueted next time it is needed
      val sysPathsField = classOf[ClassLoader].getDeclaredField("sys_paths");
      sysPathsField.setAccessible(true);
      sysPathsField.set(null, null);
    //System.getProperty("java.library.path")

    case false =>
  }

}