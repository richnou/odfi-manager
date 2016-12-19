package odfi.server.manager.ui

import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignUIView
import edu.kit.ipe.adl.indesign.core.module.ui.www.external.SemanticUIView
import odfi.server.ODFIInstallation
import odfi.server.ODFIHarvester
import odfi.server.ODFIIDModule
import edu.kit.ipe.adl.indesign.tcl.module.interpreter.TCLInstallationHarvester
import edu.kit.ipe.adl.indesign.core.module.process.IDProcess
import edu.kit.ipe.adl.indesign.core.module.process.IDCommand
import edu.kit.ipe.adl.indesign.tcl.module.interpreter.TCLInstallation
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import java.io.File
import odfi.server.api.ODFIInstance
import odfi.server.api.ODFICommand

trait ODFIBaseUI extends IndesignUIView with SemanticUIView  {
  
   this.viewContent {
    html {
      head {

        stylesheet(createSpecialPath("resources", "/odfi.css")) {

        }
      }
      body {

        "ui page container" :: div {

          // Header
          //---------------
          "ui header" :: h1("") {

            image(createSpecialPath("resources", "/logo-main-96.png")) {
            }
            "content" :: div {
              textContent("ODFI")
              "sub header" :: div {
                text("ODFI Manager")

                // Installer and version Check
                //--------------
                getTempBufferValue[IDProcess]("odfi-installer") match {
                  case Some(process) =>
                    "ui green label" :: div {
                      "warning  icon" :: i {}
                      text("Installer is running")
                    }
                  case None =>

                    ODFIIDModule.isOnlineNewer match {
                      case true =>
                        "ui yellow label" :: div {
                          "warning  icon" :: i {}
                          text("New Version available: " + ODFIIDModule.latestOnlineVersion.get.toString())

                        }
                        //"ui blue button" :: button("") {
                        "download blue  icon" :: i {

                          onClick {

                            //-- Get Download
                            var newVersion = ODFIIDModule.latestOnlineVersion.get.toString
                            var installerFile = File.createTempFile(s"odfi-installer-$newVersion", ".exe")
                            installerFile.deleteOnExit()

                            ODFIIDModule.saveOnlineInstallertoFile(installerFile)

                            //-- Execute
                            var installerCommand = new IDCommand(installerFile)
                            var process = installerCommand.createToolProcess()
                            putToTempBuffer("odfi-installer", process)
                            process.startProcessAndWait
                            println("Done installer")
                            deleteFromTempBuffer("odfi-installer")

                          }

                        }

                      //}
                      case false =>
                        text("Online version: " + ODFIIDModule.latestOnlineVersion)
                    }
                  // EOF Version check

                }
                // EOF Installer check

              }

            }

          }
          // EOF Header

          // Page
          //----------------
          "page" :: div {
            
            this.placePart("page-content")

          }
          // EOF Page

          // Footer
          //-------------
          "footer" :: div {
            

          }
        }
        // EOF PAGE

      }
    }
  }
  
  
  
  
}