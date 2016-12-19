package odfi.server.api

import edu.kit.ipe.adl.indesign.tcl.nx.NXObject
import edu.kit.ipe.adl.indesign.tcl.flextree.FlexNode
import edu.kit.ipe.adl.indesign.core.harvest.HarvestedResource

trait NamedDescription extends NXObject with FlexNode with HarvestedResource {
 
  var internalId = getClass.getCanonicalName+"-"+getName
  def getId = internalId
  
  def getName = this("name get").toString
  def getFullName = this("getFullName").toString()
  
}