package odfi.server.api

import org.odfi.tcl.nx.NXObject
import org.odfi.tcl.flextree.FlexNode
import org.odfi.tcl.nx.NXObjectCacheFactory

class ODFIModule(val odfi: ODFIInstance,base:NXObject)  extends NXObject(base) with NamedDescription {
  deriveFrom(odfi)
  
  def isPhysical = this("isPhysical").toBoolean
}

object ODFIModule extends NXObjectCacheFactory[ODFIModule] {
  
  
}