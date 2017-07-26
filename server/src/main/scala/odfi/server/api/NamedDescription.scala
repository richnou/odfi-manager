package odfi.server.api

import org.odfi.tcl.nx.NXObject
import org.odfi.tcl.flextree.FlexNode
import org.odfi.indesign.core.harvest.HarvestedResource

trait NamedDescription extends NXObject with FlexNode with HarvestedResource {
 
  var internalId = getClass.getCanonicalName+"-"+getName
  def getId = internalId
  
  def getName = this("name get").toString
  def getFullName = this("getFullName").toString()
  
}