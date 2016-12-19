package odfi.server.api

import edu.kit.ipe.adl.indesign.tcl.nx.NXObject
import edu.kit.ipe.adl.indesign.tcl.flextree.FlexNode

/**
 * Command Result should not live longer than command run, because command process/interepreter are cleaned right after usage
 */
class CommandResult(o:NXObject)  {
 
  //-- Get Stream
  var outputContent = o("toString").toString()
  
  //-- Get values map
  var valueMaps = o("getMapContent") match {
    case lst   if (lst.toString == "") => Map[String,String]()
    case other  => other.asList.toList.grouped(2).map {
      pair => (pair(0).toString,pair(1).toString)
    }.toMap
      
  }
  
}