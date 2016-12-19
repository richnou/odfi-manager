package odfi.server.manager

import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignUIView
import com.idyria.osi.vui.html.lib.semanticui.SemanticUIBuilder
import edu.kit.ipe.adl.indesign.core.module.ui.www.external.SemanticUIView
import edu.kit.ipe.adl.indesign.tcl.module.interpreter.TCLInstallationHarvester
import edu.kit.ipe.adl.indesign.tcl.module.interpreter.TCLInstallation
import odfi.server.ODFIHarvester
import odfi.server.ODFIInstallation
import odfi.server.ODFIInstallation
import odfi.server.ODFIIDModule
import java.io.File
import edu.kit.ipe.adl.indesign.core.module.process.IDCommand
import edu.kit.ipe.adl.indesign.core.module.process.IDProcess
import odfi.server.api.ODFIInstance
import odfi.server.api.ODFICommand
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule

class ODFIManagerUI extends IndesignUIView with SemanticUIView {
  this.root
  this.changeTargetViewPath("/odfi")

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

            //-- System Check 
            var somethingMissing = false
            "ui segment" :: div {
              importHTML(<a class="ui right blue ribbon label">System Check</a>)

              // tests
              div {
                TCLInstallationHarvester.getResourcesOfType[TCLInstallation] match {
                  case all if (all.size == 0) =>
                    div {
                      "ui red label" :: div {

                        "warning  icon" :: i {}
                        text("No TCL Installation Found")
                      }
                    }
                    somethingMissing = true
                  case other =>
                    other.foreach {
                      install =>
                        div {
                          "ui label" :: div {
                             
                            TCLInstallationHarvester.getValidInstallation match {
                              case Some(inst) if (inst==install) => classes("green")
                              case _ => 
                            }

                            "checkmark box icon " :: i {}
                            text("TCL Found at " + install.path)
                          }
                        }
                    }

                }

                ODFIHarvester.getResourcesOfType[ODFIInstallation].size match {
                  case 0 =>
                    "ui red label" :: div {
                      "warning  icon" :: i {}
                      text("No ODFI Installation Found")
                    }
                    somethingMissing = true
                  case other =>
                    "ui green label" :: div {
                      "checkmark box icon " :: i {}
                      text("ODFI Found")
                    }
                }
              }
              
              // Reset ODFI
              "ui red button" :: button("Reset ODFI") {
                onClickReload {
                  ODFIHarvester.getResource[ODFIInstallation].get.deleteAllODFIInstances
                  TCLModule.interpreters.foreach {
                    case (k,int) => 
                      TCLModule.deleteInterpreter(int)
                  }
                }
              }

            }
            //-- EOF System check

            somethingMissing match {
              case true =>

                "ui error message segment" :: div {
                  text("TCL or ODFI installtion are missing, please check")
                }

              case false =>

                //------------------------
                //-- ODFI Configs
                //------------------------
                "ui segment" :: div {
                  importHTML(<a class="ui right blue ribbon label">ODFI Configs</a>)

                  var odfi = ODFIHarvester.getResource[ODFIInstallation].get.getODFIInstance("main")

                  "ui striped table" :: table {
                    thead("Name", "Installation Path")
                    tbody {
                      odfi.getConfigs.foreach {
                        config =>
                          trvalues(config.name, config.installPath)
                      }

                      //odfi.
                    }
                  }

                  odfi

                }
                // EOF ODFI configs

                //-- ODFI Modules
                "ui segment" :: div {
                  importHTML(<a class="ui right blue ribbon label">ODFI Modules</a>)

                  var odfi = ODFIHarvester.getResource[ODFIInstallation].get.getODFIInstance("main")

                  "ui stripped table" :: table {
                    thead("Name", "Physical")
                    tbody {
                      odfi.getAllModules.foreach {
                        module =>
                          trvalues(module.getFullName, module.isPhysical)
                      }

                      //odfi.
                    }
                  }

                  odfi

                }
                // EOF ODFI Modules

                //-- Commands
                "ui segment" :: div {
                  importHTML(<a class="ui right blue ribbon label">ODFI Commands</a>)

                  var odfi = ODFIHarvester.getResource[ODFIInstallation].get.getODFIInstance("main")

                  "ui stripped table" :: table {
                    thead("Name", "Running", "Action")
                    tbody {
                      odfi.getAllCommands.foreach {
                        cmd =>
                          trvalues(
                            cmd.getFullName,
                            cmd.isRunning,
                            rtd {
                              "error" :: div {
                                
                              }
                              cmd.isRunning match {
                                case false =>
                                  "ui blue button" :: button("Launch") {
                                    onClickReload {
                                      
                                        println(s"Try to start")
                                       cmd.startNonBlocking
                                      
                                    }
                                  }
                                case true =>
                                  var odfiCommandInstance = cmd.getDerivedResources[ODFIInstance].head
                                  "ui red button" :: button("Force Stop") {
                                    onClickReload {
                                      
                                      println("Stopping")
                                      odfiCommandInstance.clean
                                      
                                    }
                                  }
                                  
                                  /*"ui red button" :: button("Soft Stop s") {
                                    onClickReload {
                                      
                                      println("Stopping no sync")
                                      odfiCommandInstance.interpreter.evalStringNoSync("set ::forever true")
                                      println("Done")
                                      odfiCommandInstance.clean
                                      
                                    }
                                  }*/
                                  
                                  "ui yellow label" :: div {
                                    //text("State: "+odfiCommandInstance.getDerivedResources[ODFICommand].head.getState)
                                    var cmd = odfiCommandInstance.getDerivedResources[ODFICommand].head
                                   // text("State: "+cmd.interpreter.evalStringNoSync(s"$cmd getState"))
                                  }
                                  
                                  "ui yellow button" :: button("Soft Stop") {
                                    onClickReload {
                                      var cmd = odfiCommandInstance.getDerivedResources[ODFICommand].head
                                      cmd.interpreter.evalStringNoSync(s"$cmd notify")
                                      //cmd.interpreter.evalStringNoSync("set ::globalwait true")
                                    }
                                  
                                  }
                              }

                            })
                      }

                      //odfi.
                    }
                  }

                }
            }
            // EOF Missings Check

          }
          // EOF Page

          // Footer
          //-------------

        }
        // EOF PAGE

      }
    }
  }
}