package odfi.server.manager.ui

import odfi.server.ODFIInstallation
import odfi.server.ODFIHarvester
import org.odfi.tcl.module.interpreter.TCLInstallationHarvester
import org.odfi.indesign.core.module.process.IDProcess
import org.odfi.indesign.core.module.process.IDCommand
import org.odfi.tcl.module.interpreter.TCLInstallation
import org.odfi.tcl.module.TCLModule
import java.io.File
import odfi.server.api.ODFIInstance
import odfi.server.api.ODFICommand
import org.odfi.wsb.fwapp.framework.FWAppTempBufferView
import org.odfi.wsb.fwapp.module.semantic.SemanticView
import odfi.server.ODFIManagerModule

trait ODFIBaseUI extends SemanticView with FWAppTempBufferView {

  this.addLibrary("odfi") {

    case (_, targetNode) =>

      onNode(targetNode) {

        stylesheet(createAssetsResolverURI("/odfi/css/odfi.css")) {

        }

      }
  }

  def pageContent(cl: => Any) = {
    this.definePart("page-content") {
      div {
        cl
      }
    }
  }

  this.viewContent {
    html {
      head {

        placeLibraries

      }
      body {

        "ui page container" :: div {

          // Header
          //---------------
          "ui header" :: div {
            h1("") {

              image(createAssetsResolverURI("/odfi/logos/logo-main-96.png")) {
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

                      ODFIManagerModule.isOnlineNewer match {
                        case true =>
                          "ui yellow label" :: div {
                            "warning  icon" :: i {}
                            text("New Version available: " + ODFIManagerModule.latestOnlineVersion.get.toString())

                          }
                          //"ui blue button" :: button("") {
                          "download blue  icon" :: iconClick {

                            //-- Get Download
                            var newVersion = ODFIManagerModule.latestOnlineVersion.get.toString
                            var installerFile = File.createTempFile(s"odfi-installer-$newVersion", ".exe")
                            installerFile.deleteOnExit()

                            ODFIManagerModule.saveOnlineInstallertoFile(installerFile)

                            //-- Execute
                            var installerCommand = new IDCommand(installerFile)
                            var process = installerCommand.createToolProcess()
                            putToTempBuffer("odfi-installer", process)
                            process.startProcessAndWait
                            println("Done installer")
                            deleteFromTempBuffer("odfi-installer")

                          }

                        //}
                        case false =>
                          text("Online version: " + ODFIManagerModule.latestOnlineVersion)
                      }
                    // EOF Version check

                  }
                  // EOF Installer check

                }

              }

            }
            //-- EOF Header logo

            //-- Menu
            "ui menu" :: div {

              "ui item" :: a("/")(text("Home"))
              "ui item" :: a("/deployer")(text("Deployer"))
              
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