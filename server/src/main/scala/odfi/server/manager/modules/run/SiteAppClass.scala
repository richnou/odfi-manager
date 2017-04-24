package odfi.server.manager.modules.run

import org.odfi.wsb.fwapp.SiteApp
import org.odfi.indesign.core.harvest.HarvestedResource

class SiteAppClass[T <: SiteApp](cl: Class[T]) extends HarvestedResource {
  
  def getId = cl.getCanonicalName
  
}