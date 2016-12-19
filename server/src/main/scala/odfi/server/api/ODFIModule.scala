package odfi.server.api

import edu.kit.ipe.adl.indesign.tcl.nx.NXObject
import edu.kit.ipe.adl.indesign.tcl.flextree.FlexNode
import edu.kit.ipe.adl.indesign.tcl.nx.NXObjectCacheFactory

class ODFIModule(val odfi: ODFIInstance,base:NXObject)  extends NXObject(base) with NamedDescription {
  deriveFrom(odfi)
  
  def isPhysical = this("isPhysical").toBoolean
}

object ODFIModule extends NXObjectCacheFactory[ODFIModule] {
  
  
}