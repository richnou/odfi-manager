package odfi.server.api

import org.odfi.indesign.core.harvest.fs.HarvestedFile
import odfi.server.ODFIHarvester
import org.odfi.indesign.core.main.IndesignPlatorm
import java.io.File
import odfi.server.ODFIInstallation
import com.idyria.osi.tea.thread.ThreadLanguage
import odfi.server.ODFIManagerModule


object TestCommandRun extends App with ThreadLanguage {

  //-- Find ODFI and TCL
  IndesignPlatorm.prepareDefault
  IndesignPlatorm use ODFIManagerModule
  ODFIHarvester.deliverDirect(HarvestedFile(new File("""E:\odfi""")))
  IndesignPlatorm.start

  var odfi = ODFIHarvester.getResource[ODFIInstallation].get.getODFIInstance("main")
  
  //-- Run Command
  var th = createThread {

    //var odfi = ODFIHarvester.getResource[ODFIInstallation].get.getODFIInstance("main")

    odfi.interpreter.evalString("""puts "Hello World"  """)
    
    odfi.getCommand("odfi/info") match {
      case None =>
        println("Command not found")
      case Some(c) =>
        println("Running Command...")

        c.startRedirectIO match {
          case Some(r) =>

            println(s"Found Result....")
            r.valueMaps.foreach {
              case (k, v) =>
                println(s"Key: $k, Value: $v")
            }

          case None =>
        }
    }

  }
  th.start()
  th.join()
  println("=============================================================")

  th = createThread {


    odfi.getCommand("odfi/info") match {
      case None =>
        println("Command not found")
      case Some(c) =>
        println("Running Command...")

        c.startRedirectIO match {
          case Some(r) =>

            println(s"Found Result....")
            r.valueMaps.foreach {
              case (k, v) =>
                println(s"Key: $k, Value: $v")
            }

          case None =>
        }
    }
  }
  th.start()
  th.join()
}