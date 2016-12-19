package odfi.server.manager.ui

import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignUIView
import odfi.server.ODFIInstallation
import odfi.server.ODFIHarvester
import edu.kit.ipe.adl.indesign.tcl.module.interpreter.TCLInstallationHarvester
import edu.kit.ipe.adl.indesign.tcl.module.interpreter.TCLInstallation
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import odfi.server.manager.win.WinKey
import edu.kit.ipe.adl.indesign.core.brain.Brain
import edu.kit.ipe.adl.indesign.core.module.eclipse.EclipseModule
import edu.kit.ipe.adl.indesign.core.module.eclipse.EclipseWorkspaceHarvester
import edu.kit.ipe.adl.indesign.core.module.eclipse.EclipseWorkspaceFolder

class SetupUI extends ODFIBaseUI {

  this.changeTargetViewPath("/odfi/setup")

  this.definePart("page-content") {

    div {

      h1("Setup Check") {

      }

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
            //somethingMissing = true
            case other =>
              other.foreach {
                install =>
                  div {
                    "ui label" :: div {

                      TCLInstallationHarvester.getValidInstallation match {
                        case Some(inst) if (inst == install) => classes("green")
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
            //somethingMissing = true
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
              case (k, int) =>
                TCLModule.deleteInterpreter(int)
            }
          }
        }

      }
      //-- EOF System check

      // TCL Extra
      //----------------
      "ui segment" :: div {
        importHTML(<a class="ui right blue ribbon label">TCL additions</a>)

        div {

          // Context Menu
          //------------------

          //-- Test reg
          var tclfileShellKey = new WinKey("HKEY_CLASSES_ROOT\\SystemFileAssociations\\.tcl\\shell\\ODFI\\command")
          // var tclfileKey = new WinKey("HKEY_CLASSES_ROOT\\tclfile")

          //-- Check TCL Key is tclfile
          var isTCLFile = (tclfileShellKey.exists && tclfileShellKey.getDefault.isDefined)
          isTCLFile = false
          isTCLFile match {
            case true =>
            case false =>
              "ui button" :: button("Set TCL Context Menu") {
                onClickReload {

                  //-- Set tcl to tclfile
                  //tclKey.setDefault("tclfile")
                  //tclfileKey.create

                  //-- Set Shell
                  var tclfileShellKey = new WinKey("HKEY_CLASSES_ROOT\\SystemFileAssociations\\.tcl\\shell\\ODFI\\command")
                  //tclfileShellKey.create
                  tclfileShellKey.setDefault(s"""cmd  /C "start http://localhost:8585/odfi/run/file?path=%1"""")

                  //-- Set Icon
                  var tclfileShellIconKey = new WinKey("HKEY_CLASSES_ROOT\\SystemFileAssociations\\.tcl\\shell\\ODFI")
                  tclfileShellIconKey.setValue("Icon", s"""%USERPROFILE%/AppData/Local/odfi-manager/logo_main_512.ico""")
                }
              }
          }

          // Build Systems for Sublime Text
          //----------------

          // TCL Installations post Install Script
          //-------------------------

        }
      }

      // EClipse WS?
      //-------------------
      Brain.withResource(EclipseModule) {
        "ui segment" :: div {
          importHTML(<a class="ui right blue ribbon label">Eclipse</a>)
          div {
            EclipseWorkspaceHarvester.getResource[EclipseWorkspaceFolder] match {
              case None => 
                "ui warning message" :: div {
                  text("No Eclipse Workspace found")
                }
              case Some(wsFolder) => 
                "ui success message" :: div {
                  text(s"Workspace at: ${wsFolder.path.toFile().getCanonicalPath}")
                }
            }
          }
        }
      }

    }

  }

}