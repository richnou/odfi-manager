package odfi.server.manager.ui

import org.odfi.indesign.core.module.IndesignModule
import org.odfi.indesign.core.harvest.Harvest
import org.odfi.wsb.fwapp.Site
import org.odfi.wsb.fwapp.assets.AssetsResolver
import org.odfi.wsb.fwapp.assets.ResourcesAssetSource
import odfi.server.manager.ui.deployer.DeployerView
import org.odfi.wsb.fwapp.swing.SwingPanelSite
import org.odfi.wsb.fwapp.DefaultSite
import odfi.server.manager.ui.run.RunConfigUI
import org.odfi.wsb.fwapp.jmx.FWAPPJMX

object ODFIManagerSite extends DefaultSite("/odfi") with FWAPPJMX  {

  // Site
  //-----------------
  view (classOf[WelcomeView])

  "/deployer" is {
    view(classOf[DeployerView])
  }
  
  "/cd/" is {
    
  }
  
  "/api" is {
    
    "/cd" is {
      
      "/reload" is {
        
      }
    }
  }
  
  // Runs
  //-------------
  "/run" is {
    view(classOf[RunConfigUI])
  }
  
  
  //-- 404
  this.add404Intermediary
  
  // API
  //------------
  
  // Site
  //--------------
  
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