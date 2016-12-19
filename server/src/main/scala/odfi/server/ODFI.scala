package odfi.server

import java.awt.MenuItem
import java.awt.SystemTray
import java.awt.Toolkit
import java.awt.TrayIcon
import java.awt.event.ActionEvent
import java.awt.event.ActionListener
import java.awt.event.MouseAdapter
import java.awt.event.MouseEvent

import com.idyria.osi.vui.implementation.javafx.JavaFXRun
import com.idyria.osi.vui.implementation.javafx.JavaFXUtilsTrait
import com.idyria.osi.vui.implementation.swing.SwingUtilsTrait

import edu.kit.ipe.adl.indesign.core.brain.Brain
import edu.kit.ipe.adl.indesign.core.main.IndesignPlatorm
import javafx.application.HostServices
import javafx.scene.control.Alert
import javafx.scene.control.Alert.AlertType
import javafx.scene.control.MenuBar
import javafx.scene.image.Image
import javafx.stage.Popup
import javafx.stage.Stage
import javafx.stage.Window
import javafx.stage.WindowEvent
import javax.imageio.ImageIO
import javax.swing.JMenu
import javax.swing.JMenuItem
import javax.swing.JPopupMenu
import javax.swing.UIManager
import javafx.application.Application
import com.idyria.osi.wsb.webapp.localweb.LocalWebEngine
import java.io.File
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import edu.kit.ipe.adl.indesign.module.maven.utils.VersionLocator
import odfi.server.manager.ODFIManagerUI
import com.idyria.osi.tea.logging.TLog
import com.idyria.osi.wsb.webapp.localweb.SingleViewIntermediary
import edu.kit.ipe.adl.indesign.tcl.integration.TclintLibrary
import edu.kit.ipe.adl.indesign.core.harvest.Harvester
import odfi.server.manager.ui.ODFIManagerUIModule
import edu.kit.ipe.adl.indesign.core.config.Config
import edu.kit.ipe.adl.indesign.core.config.ooxoo.OOXOOFSConfigImplementation
import edu.kit.ipe.adl.indesign.core.module.eclipse.EclipseModule

object ODFI extends App with SwingUtilsTrait with JavaFXUtilsTrait {

  println(s"Starting ODFI Standalone....")

  sys.env.keys.foreach {
    k => println(s"KE: " + k + " -> " + sys.env(k))
  }
  //TclintLibrary.enableDebug
  //TLog.setLevel(classOf[SingleViewIntermediary], TLog.Level.FULL)
  //TLog.setLevel(classOf[Harvester], TLog.Level.FULL)

  /*
  sys.props.keys.foreach {
    k => println(s"KP: "+k)
  }
  */

  // Find Version
  //--------------------
  var version = VersionLocator.findVersion("odfi", "odfi-server")
  println("Version: " + version)

  //-- Gather Parameters
  //-------------------------
  var allArgs = args.zipWithIndex
  var (odfiLoc) = allArgs.toList.find(_._1 == "--odfi").getOrElse(new File("").getAbsolutePath -> -1) match {
    case (path, -1) => new File(path).getCanonicalFile
    case (p, argi) => new File(args(argi + 1)).getCanonicalFile
  }
  ODFIHarvester.saveToAvailableResources(HarvestedFile(odfiLoc))
  /*.collect {
    case ("--install",i) => args(i+1)
  }*/

  //-- Prepare Indesign
  IndesignPlatorm.prepareDefault
  IndesignPlatorm use ODFIIDModule
  IndesignPlatorm use ODFIManagerUIModule
  IndesignPlatorm use Config
  Config.setImplementation(new OOXOOFSConfigImplementation(new File("manager-db")))

  
  //-- Add Special Modules
  IndesignPlatorm use EclipseModule
  EclipseModule.addDerivedResource(HarvestedFile(new File("E:\\Common\\Projects\\eclipse-workspaces\\neon")))
  
  //--
  JavaFXRun.noImplicitExit
  JavaFXRun.waitStarted
  var hostServices = JavaFXRun.application.getHostServices

  //-- Prepare a few data like images
  Toolkit.getDefaultToolkit

  val mainIcon512PNGURL = this.getClass().getClassLoader.getResource("logo-main-512.png")
  val mainIcon512ICOURL = this.getClass().getClassLoader.getResource("logo-main-16.png")
  val mainIcon512AWT = ImageIO.read(mainIcon512ICOURL)

  //-- Splashscreen

  //-- Create App tray
  SystemTray.isSupported() match {
    case true =>

      //-- Menu Using Swing
      //--------------------  
      UIManager.setLookAndFeel(
        UIManager.getSystemLookAndFeelClassName());

      var popupMenu = new JPopupMenu

      var urlInfo = addActionMenu(popupMenu)("URL: http://") {

      }

      addActionMenu(popupMenu)("Manager -> Manager Restart") {
        Brain.moveToStop
        Brain.resetState
        Brain.moveToStart
      }

      addActionMenu(popupMenu)("Manager -> Open") {

        hostServices.showDocument(s"http://localhost:${LocalWebEngine.httpConnector.port}/")

      }

      addActionMenu(popupMenu)("Manager -> Stop") {

        Brain.moveToShutdown
        JavaFXRun.stopAll

      }

      //-- Create Tray
      //--------------------
      var tray = SystemTray.getSystemTray
      var mainIcon = new TrayIcon(mainIcon512AWT, "ODFI Manager")
      tray.add(mainIcon)
      
 

      addActionMenu(popupMenu)("Quit") {

        Brain.moveToShutdown
        JavaFXRun.stopAll
        popupMenu.setVisible(false)
        SystemTray.getSystemTray.remove(mainIcon)

      }

      mainIcon.addMouseListener(new MouseAdapter {

        override def mouseReleased(e: MouseEvent) = {

          if (e.isPopupTrigger()) {

            //trayMenuWindow.
            popupMenu.setLocation(e.getX(), e.getY());
            popupMenu.setInvoker(popupMenu);
            popupMenu.setVisible(true);

          }

        }
      })

      //-- Create Menu

      //-- Starting
      IndesignPlatorm.start

    case false =>

      JavaFXRun.onJavaFX {

        val mainIcon512FXImage = new Image(mainIcon512PNGURL.toString())
        var alert = new Alert(AlertType.ERROR);
        alert.setTitle("ODFI Manager");
        alert.setHeaderText("Cannot start ODFI Service Tray");
        alert.setContentText("ODFI has no support for System Tray on this system and won't start to avoid letting the manager server run without clear notification");

        alert.getDialogPane().getScene().getWindow().asInstanceOf[Stage].getIcons.add(new Image(this.getClass().getClassLoader.getResource("logo-main-512.png").toString()))

        alert.showAndWait();
      }
  }

}