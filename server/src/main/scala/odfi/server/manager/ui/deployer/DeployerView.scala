package odfi.server.manager.ui.deployer

import odfi.server.manager.ui.ODFIBaseUI
import org.odfi.wsb.fwapp.lib.markdown.MarkdownView
import org.odfi.indesign.core.harvest.Harvest
import odfi.server.ODFIManagerModule
import org.odfi.wsb.fwapp.lib.indesign.FWappResourceValueBindingView
import org.odfi.indesign.ide.module.maven.MavenProjectHarvester
import org.odfi.wsb.fwapp.SiteApp
import odfi.server.manager.modules.run.SiteAppClass

class DeployerView extends ODFIBaseUI with MarkdownView with FWappResourceValueBindingView {

  this.pageContent {

    div {
      h1("Deployer") {

      }

      markdown("""|
                  |This page enables quick and easy deployment of applications like web applications.
                  |
                  |It simply works by starting processes, so it could manage any kind of application.
                  |
                  |## FWAPP
                  |
                  |FWAPP applications have more deployment options, like Monitoring Agent, or in-house deployment.
                  |
                  |""".stripMargin)

      h2("Maven Runs") {
      }

      "ui primary button" :: buttonClickReload("Rescan")(Harvest.run)

      "ui celled table" :: table {

        thead("", "Path", "Build Goal", "Args", "Running", "Problems")

        /*withEmpty(ODFIManagerModule.getRunConfiguration.filter(_.mavenRun!=null)) {
          case None =>
            tbody(tr(td("No Projects")(colspan(6))))

          case Some(mavenRuns) =>
            tbody {
              mavenRuns.foreach {
                mavenRun =>

                  // Maven Line
                  //-----------------
                  //-- Delete
                  rtd("ui delete icon" :: iconClickReload { ODFIManagerModule.getRunConfiguration.mavenRuns -= mavenRun; Harvest.run })

                  //-- Path
                  td(mavenRun.path)()

                  //-- Build Goal
                  rtd {
                    inputToBufferAfter500MS(mavenRun.buildGoal)

                  }

                  // Main Class and Running are for Sub-lines
                  rtd()
                  rtd()

                  // Errors
                  rtd {

                    MavenProjectHarvester.getMavenProjectAtLocation(mavenRun.path) match {
                      case Some(p) =>
                        classes("Positive")
                        text("None")
                      case None =>
                        classes("negative")
                        "ui error icon" :: i()
                        text("Maven Project Not Found")
                    }

                  }

                  // Run Definitions
                  //------------
                  withEmpty(mavenRun.runDefinitions) {
                    case None =>
                      td("No Run Definitions") {
                        colspan(6)
                      }

                    case Some(runDefinitions) =>

                      trLoop(runDefinitions) {
                        runDefinition =>

                          //-- Delete
                          rtd("ui delete icon" :: iconClickReload { ODFIManagerModule.getRunConfiguration.mavenRuns -= mavenRun; Harvest.run })

                          //-- Path is name and no build goal
                          rtd(runDefinition.mainClass)
                          rtd()

                          //-- Arguments
                          rtd()
                          //-- Running
                          rtd {
                            if (runDefinition.processID != null) {
                              classes("positive")
                              text("Process Running")
                            } else {

                              // JDK
                             // selectOptions(options)(cl)
                              

                              // Start
                              "ui primary button" :: buttonClickReload("Start") {

                              }
                            }
                          }
                          //-- Errors
                          rtd()
                      }
                  }
                  // EOF Run definition lines

                  // ADd Main Class Line
                  //---------------
                  tr {
                    //-- No delete
                    rtd()

                    //-- Path is found main select

                    withEmpty(mavenRun.getDerivedResources[SiteAppClass[_]]) {
                      case None =>
                      case Some(siteApps) =>
                        rtd {

                          classes("Positive")
                          form {
                            selectOptions(siteApps.toList.map { sa => (sa.getId, sa.getId) }) {
                              fieldName("class")
                            }
                            semanticOnSubmitButton("Add") {

                              //-- Create Run Definition
                              val run = mavenRun.runDefinitions.add
                              run.mainClass = request.get.getURLParameter("class")
                              ODFIManagerModule.saveConfig

                            }
                          }

                        }
                    }

                    //-- No build
                    rtd()

                    //-- Run
                    rtd {

                    }

                    //-- Errors
                    rtd {

                    }
                  }
              }
            }

        }
        // EOF Lines*/

        /*tfootTrTh {
          form {
            "inline" :: input {
              fieldName("path")
              semanticFieldRequire
              semanticFieldNot(ODFIManagerModule.getRunConfiguration.mavenRuns.map(_.path.toString))
            }
            "inline" :: semanticOnSubmitButton("Add") {
              var run = ODFIManagerModule.getRunConfiguration.mavenRuns.add
              run.path = request.get.getURLParameter("path").get
              ODFIManagerModule.saveConfig
              Harvest.run

            }
          }
        }*/
      }
      //-- EOF MAven table

    }
  }
}