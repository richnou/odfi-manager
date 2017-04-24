package odfi.server

import org.odfi.indesign.core.module.IndesignModule
import org.odfi.tcl.module.TCLModule
import org.odfi.indesign.core.harvest.Harvest
import org.odfi.indesign.core.brain.Brain
import org.odfi.indesign.core.heart.HearthUtilTrait

import com.idyria.osi.tea.io.TeaIOUtils
import java.net.URL
import org.odfi.indesign.core.heart.Heart
import java.util.concurrent.TimeUnit
import java.io.File
import org.odfi.indesign.ide.module.maven.utils.Version
import com.idyria.osi.ooxoo.core.buffers.structural.AnyXList
import odfi.server.manager.modules.run.RunConfiguration
import org.odfi.eda.h2dl.H2DLModule
import org.odfi.indesign.core.harvest.fs.FileSystemHarvester
import org.odfi.indesign.core.module.HarvesterModule
import org.odfi.indesign.ide.module.maven.MavenModule
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.indesign.ide.module.maven.MavenProjectHarvester
import org.odfi.wsb.fwapp.SiteApp
import odfi.server.manager.modules.run.SiteAppClass

object ODFIManagerModule extends IndesignModule with HearthUtilTrait with HarvesterModule {

  // Config data
  //-----------------
  AnyXList(classOf[RunConfiguration])

  // Versions
  //------------------------
  var latestOnlineVersion: Option[Version] = None

  val versionTask = createHearthTask {

    //-- Get Version Text
    var onlineVersion = new String(TeaIOUtils.swallow(new URL("https://www.opendesignflow.org/cd/org.odfi/win32/odfi-version.ini").openStream()))

    println("Found ONline version: " + onlineVersion)

    latestOnlineVersion = Some(Version(onlineVersion))
  }
  versionTask.timeUnit = TimeUnit.HOURS
  versionTask.scheduleEvery = Some(2)

  def isOnlineNewer = this.latestOnlineVersion match {
    case Some(v) if (v > ODFI.version.get) => true
    case _ => false
  }

  def saveOnlineInstallertoFile(f: File) = {
    latestOnlineVersion match {
      case Some(v) =>

        TeaIOUtils.writeToFile(f, new URL(s"http://www.idyria.com/access/osi/files/builds/odfi/win32/odfi-installer-${v.toString}.exe").openStream())

      case None =>
        sys.error("Cannot save ODFI installer because online version was not detected")
    }
  }

  // Harvesting
  //------------
  override def doHarvest = {

    val conf = this.config.get

    // Run Tool
    //----------------
    val runConfiguration = getRunConfiguration

    //-- Load maven runs in FS harvester
    runConfiguration.mavenRuns.foreach {
      mavenRun =>

        // Make sure it is in search path
        val f = HarvestedFile(new File(mavenRun.path))
        FileSystemHarvester.addPath(f)

        // look up site classes
       mavenRun.cleanDerivedResourcesOfType[SiteAppClass[_]]
        MavenProjectHarvester.getMavenProjectAtLocation(mavenRun.path) match {
          case Some(p) =>
            val siteApps = p.discoverType[SiteApp]
            mavenRun.addDerivedResources(siteApps.map(new SiteAppClass(_)))
            
          case None =>

        }
    }

  }

  // Run tool
  //---------------

  def getRunConfiguration = this.config.get.custom.content.ensureElement[RunConfiguration]

  // Lifecycle
  //--------------

  this.onLoad {

    //println(s"Loading ODFIDModule")
    //-- Load TCL
    try {
      this.requireModule(TCLModule)
    } catch {
      case e: Throwable =>
        e.printStackTrace()
    }

    //-- Load H2DL
    requireModule(H2DLModule)

    //-- Load maven support
    requireModule(MavenModule)

  }

  this.onInit {

    //-- Add ODFI Harvester
    Harvest.addHarvester(ODFIHarvester)

  }

  this.onStart {

    Heart.pump(versionTask)
    Harvest.run

  }

}