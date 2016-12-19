package odfi.server

import edu.kit.ipe.adl.indesign.core.module.IndesignModule
import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignWWWUIModule
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.indesign.core.brain.Brain
import edu.kit.ipe.adl.indesign.core.module.ui.www.WWWViewHarvester
import odfi.server.manager.ODFIManagerUI
import edu.kit.ipe.adl.indesign.core.heart.HearthUtilTrait
import edu.kit.ipe.adl.indesign.module.maven.utils.Version
import com.idyria.osi.tea.io.TeaIOUtils
import java.net.URL
import edu.kit.ipe.adl.indesign.core.heart.Heart
import java.util.concurrent.TimeUnit
import java.io.File

object ODFIIDModule extends IndesignModule with HearthUtilTrait {

  var latestOnlineVersion : Option[Version] = None
  
  val versionTask = createHearthTask {
    
    //-- Get Version Text
    var onlineVersion = new String(TeaIOUtils.swallow(new URL("http://www.idyria.com/access/osi/files/builds/odfi/win32/odfi-version.ini").openStream()))
    
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
  
    println(s"Loading ODFIDModule")
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