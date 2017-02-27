package odfi.server

import java.awt.MenuItem
import java.awt.SystemTray
import java.awt.Toolkit
import java.awt.TrayIcon
import java.awt.event.ActionEvent
import java.awt.event.ActionListener
import java.awt.event.MouseAdapter
import java.awt.event.MouseEvent

import org.odfi.indesign.core.brain.Brain
import org.odfi.indesign.core.main.IndesignPlatorm
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
import org.odfi.indesign.core.harvest.fs.HarvestedFile

import odfi.server.manager.ODFIManagerUI
import com.idyria.osi.tea.logging.TLog
import com.idyria.osi.wsb.webapp.localweb.SingleViewIntermediary
import org.odfi.tcl.integration.TclintLibrary
import org.odfi.indesign.core.harvest.Harvester
import odfi.server.manager.ui.ODFIManagerUIModule
import org.odfi.indesign.core.config.Config
import org.odfi.indesign.core.config.ooxoo.OOXOOFSConfigImplementation

import org.odfi.indesign.ide.module.maven.utils.VersionLocator
import org.odfi.indesign.core.module.jfx.JavaFXUtilsTrait
import org.odfi.indesign.core.module.jfx.JFXRun
import org.odfi.indesign.core.module.swing.SwingUtilsTrait
import org.odfi.wsb.fwapp.assets.ResourcesAssetSource
import com.idyria.osi.wsb.core.network.connectors.tcp.TCPConnector
import com.idyria.osi.wsb.core.network.connectors.tcp.TCPProtocolHandlerConnector

object ODFI extends App with JavaFXUtilsTrait with SwingUtilsTrait {

  println(s"Starting ODFI Standalone....")

  //Brain.tlogEnableFull[ResourcesAssetSource]

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
  ODFIManagerUIModule.listen(8585)

  IndesignPlatorm use Config
  Config.setImplementation(new OOXOOFSConfigImplementation(new File("manager-db")))

  //-- Add Special Modules
  /* IndesignPlatorm use EclipseModule
  EclipseModule.addDerivedResource(HarvestedFile(new File("E:\\Common\\Projects\\eclipse-workspaces\\neon")))*/

  //--
  JFXRun.noImplicitExit
  JFXRun.waitStarted
  var hostServices = JFXRun.application.getHostServices

  //-- Prepare a few data like images
  Toolkit.getDefaultToolkit

  val mainIcon512PNGURL = this.getClass().getClassLoader.getResource("odfi/logos/logo-main-512.png")
  val mainIcon512ICOURL = this.getClass().getClassLoader.getResource("odfi/logos/logo-main-16.png")
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

      ODFIManagerUIModule.engine.network.connectors.toList.find { 
        case c : TCPProtocolHandlerConnector[_] => true
        case other => false 
        
      } match {
        case Some(tc : TCPProtocolHandlerConnector[_]) =>
          addActionMenu(popupMenu)("Manager -> Open") {

            hostServices.showDocument(s"http://localhost:${tc.port}/odfi")

          }
        case None =>
      }

      addActionMenu(popupMenu)("Manager -> Stop") {

        Brain.moveToShutdown
        JFXRun.stopAll

      }

      //-- Create Tray
      //--------------------
      var tray = SystemTray.getSystemTray
      var mainIcon = new TrayIcon(mainIcon512AWT, "ODFI Manager")
      tray.add(mainIcon)

      addActionMenu(popupMenu)("Quit") {

        IndesignPlatorm.stop
        //Brain.moveToShutdown
        JFXRun.stopAll
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

      JFXRun.onJavaFX {

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