package odfi.server.api

import scala.sys.process._
import odfi.server.manager.win.WinKey

object TestRegistry extends App {

  // HKEY_CLASSES_ROOT
  var tclKey = new WinKey("HKEY_CLASSES_ROOT\\.tcl")
  var tcllKey = new WinKey("HKEY_CLASSES_ROOT\\.tcll")

  println("Exists: " + tclKey.exists)
  println("Exists: " + tcllKey.exists)

  println("Default: " + tclKey.getDefault)

  var tclfileShellKey = new WinKey("HKEY_CLASSES_ROOT\\SystemFileAssociations\\.tcl\\shell\\ODFI\\command")
                   tclfileShellKey.create
                   tclfileShellKey.setDefault(s"""cmd  /C "start http://localhost:8585/odfi/run/file?path=%1"""")
}