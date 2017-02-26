package odfi.server.manager.modules.ui


import java.io.File
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.indesign.core.harvest.fs.HarvestedTextFile
import org.odfi.wsb.fwapp.views.FWappView

trait PathRequiredUtil extends FWappView {
  
  
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