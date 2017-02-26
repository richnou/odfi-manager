package odfi.server.manager.ui

import org.odfi.indesign.core.module.IndesignModule
import odfi.server.manager.ODFIManagerUI
import org.odfi.indesign.core.harvest.Harvest
import org.odfi.wsb.fwapp.Site
import org.odfi.wsb.fwapp.assets.AssetsResolver
import org.odfi.wsb.fwapp.assets.ResourcesAssetSource

object ODFIManagerUIModule extends Site("/odfi") with IndesignModule {

  // Site
  //-----------------
  view (classOf[WelcomeView])

  
  var assetsManager = ("/assets" uses new AssetsResolver ) 
  assetsManager.addAssetsSource("/odfi", new ResourcesAssetSource).addFilesSource("odfi")
  /*{
    addAssetsSource("odfi", new ResourcesAssetSource).addFilesSource("odfi")
  }*/
  
  this.add404Intermediary
  
  
  // LFC
  //------------------
  
  this.onLoad {
    //requireModule(IndesignWWWUIModule)

  }

  this.onInit {
    
    //-- Deliver GUI
   /* Harvest.deliverToHarvesters[WWWViewHarvester](new ODFIManagerUI)
    Harvest.deliverToHarvesters[WWWViewHarvester](new SetupUI)
    var wwwharvester = Harvest.getHarvesters[WWWViewHarvester].get.head
    wwwharvester.deliverDirectToPath("/odfi/run/file" -> new RunFileView)
    wwwharvester.deliverDirectToPath("/odfi/view/file" -> new ViewFileView)*/
  }

}