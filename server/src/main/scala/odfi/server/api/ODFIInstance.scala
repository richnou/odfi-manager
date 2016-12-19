package odfi.server.api

import java.io.File

import edu.kit.ipe.adl.indesign.core.harvest.HarvestedResource
import edu.kit.ipe.adl.indesign.tcl.flextree.FlexNode
import edu.kit.ipe.adl.indesign.tcl.flist.MutableList
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.indesign.tcl.nx.NXObject
import com.idyria.osi.tea.thread.ThreadLanguage
import edu.kit.ipe.adl.indesign.core.heart.HeartTask

class ODFIInstance(obj: NXObject) extends NXObject(obj) with NamedDescription with HarvestedResource with ThreadLanguage {

 // override def getId = "odfi-"+this.getName
  
  
  
  //var odfiInstances = Map[String,ODFInstance]

  /**
   * Remove associated resources and interpreter
   */
  this.onClean {
    
    // Clean Resource
    this.unroot
    this.parentResource match {
      case Some(pr) => 
        pr.removeDerivedResource[ODFIInstance](this)
      case None => 
    }
    
    // Kill all tasks
    this.getDerivedResources[HeartTask[_]].foreach {
      task => 
        task.kill
    }
    this.cleanDerivedResources
    
    // Finally: Clear interpreter
    // Do this right now, not before!
    TCLModule.deleteInterpreter(this.interpreter)
  }
  
  def applyFileToConfig(name: String, f: File) = {
    this(s"getConfig $name").asObjectValue.asNXObject.applyFile(f)
  }
  
  def getConfigs = this.getChildren("::odfi::Config")
  
  // Modules
  //--------------
  
  def getAllModules = ODFIModule(this("getAllModules"),new ODFIModule(this,_))

  // Commands
  //--------------
  def getCommand(str:String) : Option[ODFICommand] = this(s"resolveCommand $str") match {
    case v if (v.toString == "") => None
    case v => Some(new ODFICommand(this,v))
  }
  def getAllCommands  = ODFICommand(this("getAllCommands"),new ODFICommand(this,_))
  
  
  
  
}