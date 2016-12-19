package odfi.server.manager.modules.view

import edu.kit.ipe.adl.indesign.core.module.ui.www.stream.StreamUIBuilder
import odfi.server.manager.ui.ODFIBaseUI
import odfi.server.manager.modules.ui.PathRequiredUtil
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.ZoneId
import java.time.Instant
import edu.kit.ipe.adl.indesign.core.module.ui.www.edit.ace.ACEEditorBuilder
import edu.kit.ipe.adl.indesign.core.module.webdraw.WebdrawViewBuilder
import edu.kit.ipe.adl.indesign.core.module.ui.www.edit.FileEditBuilder

class ViewFileView extends ODFIBaseUI with StreamUIBuilder with PathRequiredUtil with FileEditBuilder  {

  this.definePart("page-content") {
    div {
      
      fileOnPathURLParameterMessage {
        file => 
          
 
          // File Info
          //-----------------
          "ui segment" :: div {
            "ui header " :: h2("File statistics") {

            }

            "ui statistics" :: div {

              //-- Modification
              "statistic" :: div {

                var modifiedDate = LocalDateTime.ofInstant(Instant.ofEpochMilli(file.lastModified()), ZoneId.systemDefault())
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

                var sizeText = file.length() match {
                  case size if (size < 1024) => s"$size Bytes"
                  case size if (size <= 1024 * 1024) => s"${size / 1024} kB"
                  case size if (size <= 1024 * 1024 * 1024) => s"${size / (1024 * 1024)} MB"
                  case size if (size <= 1024 * 1024 * 1024 * 1024) => s"${size / (1024 * 1024 * 1024)} GB"
                }

                "value" :: div(text(sizeText))
                "label" :: div(text("Size"))

              }

              
            }
            // EOF File Info
            

          }
          
          // Create Editor
          //-----------------
          fileEditor(file,file.getExtension) {
            /* onFilteredKeyTyped("""e.ctrlKey && e.key=='s'""") { 
               x =>
                 println("Received CTRL+S")
             }  */
          }
          //aceFastEditor(file.get
          
      }
    }
  }
  
}