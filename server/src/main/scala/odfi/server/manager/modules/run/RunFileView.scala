package odfi.server.manager.modules.run

import java.io.File
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

import odfi.server.manager.ui.ODFIBaseUI
import java.time.Instant
import odfi.server.ODFIInstallation
import odfi.server.ODFIInstallation
import odfi.server.ODFIHarvester
import odfi.server.api.ODFIInstance
import edu.kit.ipe.adl.indesign.core.module.ui.www.stream.StreamUIBuilder
import edu.kit.ipe.adl.indesign.core.config.Config
import com.idyria.osi.ooxoo.core.buffers.datatypes.DateTimeBuffer
import java.net.URI

class RunFileView extends ODFIBaseUI with StreamUIBuilder {

  this.definePart("page-content") {
    div {

      // Get File From parameters
      //----------------
      this.request.get.getURLParameter("path") match {
        case None =>
          "ui message error " :: div(text("URL Parameter file must be provided"))
        case Some(fileParameter) if (!new File(fileParameter).getCanonicalFile.exists) =>
          "ui message error " :: div(text(s"File $fileParameter does not exist"))
        case Some(fileParameter) =>

          var targetFile = new File(fileParameter).getCanonicalFile
          "ui message success " :: div(text(s"Running File $fileParameter"))

          // Look for Run
          //-----------------
          var docContainer = Config.getContainerFor("odfi.server.manager.modules.run.RunFile").get
          var runDocument = docContainer.documentWithNew(targetFile.getCanonicalPath.replace(":", "").replace("/", "_").replace("\\", "_") + ".xml", new FileRun) {
            doc =>
              doc.path = targetFile.getCanonicalPath
          }

          // File Info
          //-----------------
          "ui segment" :: div {
            "ui header " :: h2("File statistics") {

            }

            "ui statistics" :: div {

              //-- Modification
              "statistic" :: div {

                var modifiedDate = LocalDateTime.ofInstant(Instant.ofEpochMilli(targetFile.lastModified()), ZoneId.systemDefault())
                var now = LocalDateTime.now()
                var formatter = now.toLocalDate().isEqual(modifiedDate.toLocalDate()) match {
                  case true => DateTimeFormatter.ofPattern("H:m:s")
                  case false => DateTimeFormatter.ISO_LOCAL_DATE
                }

                "value" :: div(text(modifiedDate.format(formatter)))
                "label" :: div(text("Last Modification"))
              }

              //-- Size
              "statistic" :: div {

                var sizeText = targetFile.length() match {
                  case size if (size < 1024) => s"$size Bytes"
                  case size if (size <= 1024 * 1024) => s"${size / 1024} kB"
                  case size if (size <= 1024 * 1024 * 1024) => s"${size / (1024 * 1024)} MB"
                  case size if (size <= 1024 * 1024 * 1024 * 1024) => s"${size / (1024 * 1024 * 1024)} GB"
                }

                "value" :: div(text(sizeText))
                "label" :: div(text("Size"))

              }

              //-- Run Count
              "statistic" :: div {

                "value" :: div(text(runDocument.runs.size.toString))
                "label" :: div(text("Runs"))

              }
            }

          }

          // Run Output
          //-------------------
          "ui segment" :: div {
            "ui header " :: h2("Run") {

            }

            div {
              input {

                label("Save Stream Contents") {

                }
                bindBufferValue(runDocument.streamSave)
              }
            }

            "ui button" :: button("Test Run") {
              onClick {

                //-- Add Run to DB
                var fileRun = runDocument.runs.add
                fileRun.date = DateTimeBuffer()

                try {

                  //-- File path needs in "/" in TCL
                  var tclFilePath = targetFile.getCanonicalPath.replace("\\", "/")
                  println("File to run: " + tclFilePath)

                  //-- Get ODFI, command for file
                  var odfi: ODFIInstance = ODFIHarvester.getResource[ODFIInstallation].get.getODFIInstance("runfile" + System.currentTimeMillis())
                  var fileCommand = odfi.getCommand(tclFilePath).get

                  println("Ready to run")

                  //-- Watch for streams
                  var streams = List[String]()
                  odfi.interpreter.onWith("stream.create") {
                    nameAndId: (String, String) =>
                      println("******* Strem Create ********")
                      var runStream = fileRun.streams.add
                      runStream.ID = nameAndId._2
                      streams = streams :+ nameAndId._1
                      this.sendStreamCreate(nameAndId._1, nameAndId._2)
                  }

                  //-- Run Command and catch STDOUT
                  fileCommand.startCurrentWithStdout {
                    utext =>
                      //println("*** Got line, last char: " + utext.last.intValue().toString)
                      sendUpdateStreamText("stdout", utext)
                  }

                  //-- Update Stream informations
                  streams.foreach {
                    streamId =>
                      sendStreamParameter(streamId, "size", odfi.interpreter.streams(streamId).getSize.toString)
                  }

                } finally {
                  runDocument.resyncToFile
                }

              }
            }

            //-- File Out Stream
            div {
              +@("style" -> "display:none")
              "ui table" :: table {
                id("streams-table")
                thead("File", "Size")
                tbody {

                }

              }
            }

            //-- Output
            "ui floating message" :: div {
              divStreamArea("stdout") {

              }
            }

            /*"ui floating message" :: div {
              id("stream-runoutput")
              
            }*/

          }

          script(new URI(createSpecialPath("resources", "/js/runfile.js"))) {

          }

      }
      // EOF PAge conteot

    }
  }

}