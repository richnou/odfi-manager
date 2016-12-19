package odfi.server.api

import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import odfi.server.ODFIHarvester
import odfi.server.ODFIIDModule
import edu.kit.ipe.adl.indesign.core.main.IndesignPlatorm
import java.io.File
import odfi.server.ODFIInstallation
import com.idyria.osi.tea.thread.ThreadLanguage
import edu.kit.ipe.adl.indesign.tcl.module.interpreter.TCLInstallationHarvester

object TestCommandLongRun extends App with ThreadLanguage {

  //-- Find ODFI and TCL
  IndesignPlatorm.prepareDefault
  IndesignPlatorm use ODFIIDModule
  ODFIHarvester.deliverDirect(HarvestedFile(new File("""E:\odfi""")))
  IndesignPlatorm.start

  var odfi = ODFIHarvester.getResource[ODFIInstallation].get.getODFIInstance("main")

  //-- Run Command Wait command
  var vwaitCommand = odfi.getAllCommands.find { p => p.getName.startsWith("vwait") }.get

  //-- Start in new thread
  var commandODFI = vwaitCommand.startNonBlocking

  Thread.sleep(3000)
  println("=============================")

  println("Non blocking started")
  var state = commandODFI("getState")
  println("State: " + state)
}