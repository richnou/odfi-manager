package odfi.server.manager.modules.ui

import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignUIView
import java.io.File
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedTextFile

trait PathRequiredUtil extends IndesignUIView {
  
  
  def fileOnPathURLParameterMessage(f:Function1[HarvestedTextFile,Unit]) : Unit = {
  
    this.request.get.getURLParameter("path") match {
        case None =>
          "ui message error " :: div(text("URL Parameter file must be provided"))
          None
        case Some(fileParameter) if (!new File(fileParameter).getCanonicalFile.exists) =>
          "ui message error " :: div(text(s"File $fileParameter does not exist"))
          None
        case Some(fileParameter) =>
          f(HarvestedTextFile(new File(fileParameter).getCanonicalFile))
    }
    
  }
  
}