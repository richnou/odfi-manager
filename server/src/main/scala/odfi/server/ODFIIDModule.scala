package odfi.server

import org.odfi.indesign.core.module.IndesignModule
import org.odfi.tcl.module.TCLModule
import org.odfi.indesign.core.harvest.Harvest
import org.odfi.indesign.core.brain.Brain
import odfi.server.manager.ODFIManagerUI
import org.odfi.indesign.core.heart.HearthUtilTrait

import com.idyria.osi.tea.io.TeaIOUtils
import java.net.URL
import org.odfi.indesign.core.heart.Heart
import java.util.concurrent.TimeUnit
import java.io.File
import org.odfi.indesign.ide.module.maven.utils.Version
import com.idyria.osi.ooxoo.core.buffers.structural.AnyXList
import odfi.server.manager.modules.run.ToolRun

object ODFIIDModule extends IndesignModule with HearthUtilTrait {

  // Config data
  //-----------------
  AnyXList(classOf[ToolRun])
  
  // Versions
  //------------------------
  var latestOnlineVersion : Option[Version] = None
  
  val versionTask = createHearthTask {
    
    //-- Get Version Text
    var onlineVersion = new String(TeaIOUtils.swallow(new URL("https://www.opendesignflow.org/cd/org.odfi/win32/odfi-version.ini").openStream()))
    
    println("Found ONline version: "+onlineVersion)
    
    latestOnlineVersion = Some(Version(onlineVersion))
  }
  versionTask.timeUnit = TimeUnit.HOURS
  versionTask.scheduleEvery = Some(2)
  
  def isOnlineNewer = this.latestOnlineVersion match {
    case Some(v) if (v > ODFI.version.get) => true
    case _ => false
  }
  
  def saveOnlineInstallertoFile(f:File) = {
    latestOnlineVersion match {
      case Some(v) => 
        
        TeaIOUtils.writeToFile(f, new URL(s"http://www.idyria.com/access/osi/files/builds/odfi/win32/odfi-installer-${v.toString}.exe").openStream())
        
        
      case None => 
        sys.error("Cannot save ODFI installer because online version was not detected")
    }
  }
  
  
  this.onLoad {
  
    //println(s"Loading ODFIDModule")
    try {
    this.requireModule(TCLModule)
    } catch {
      case e : Throwable => 
        e.printStackTrace()
    }
  }

  this.onInit  {

    //-- Add ODFI Harvester
    Harvest.addHarvester(ODFIHarvester)

    

  }

  this.onStart {
    
    Heart.pump(versionTask)
    
  }
  
}