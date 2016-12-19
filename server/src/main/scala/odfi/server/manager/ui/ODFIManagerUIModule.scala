package odfi.server.manager.ui

import edu.kit.ipe.adl.indesign.core.module.IndesignModule
import odfi.server.manager.ODFIManagerUI
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.indesign.core.module.ui.www.WWWViewHarvester
import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignWWWUIModule
import odfi.server.manager.modules.run.RunFileView
import odfi.server.manager.modules.view.ViewFileView

object ODFIManagerUIModule extends IndesignModule {

  this.onLoad {
    requireModule(IndesignWWWUIModule)

  }

  this.onInit {
    
    //-- Deliver GUI
    Harvest.deliverToHarvesters[WWWViewHarvester](new ODFIManagerUI)
    Harvest.deliverToHarvesters[WWWViewHarvester](new SetupUI)
    var wwwharvester = Harvest.getHarvesters[WWWViewHarvester].get.head
    wwwharvester.deliverDirectToPath("/odfi/run/file" -> new RunFileView)
    wwwharvester.deliverDirectToPath("/odfi/view/file" -> new ViewFileView)
  }

}