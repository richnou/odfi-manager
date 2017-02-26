package odfi.server

import org.odfi.indesign.core.main.IndesignPlatorm
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import java.io.File

object ODFITestApp extends App {

  IndesignPlatorm.prepareDefault
  IndesignPlatorm use ODFIIDModule

  ODFIHarvester.deliverDirect(HarvestedFile(new File("""E:\odfi""")))
  
  IndesignPlatorm.start

  //-- Get ODFI
  var odfi = ODFIHarvester.getResource[ODFIInstallation].get.getODFIInstance("main")

  odfi.getChildren().foreach {
    no => 
        println("--> "+no("name get"))
  }
  
 
  
   IndesignPlatorm.stop


}