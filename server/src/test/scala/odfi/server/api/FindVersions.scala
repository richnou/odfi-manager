package odfi.server.api

import org.odfi.indesign.core.artifactresolver.ArtifactResolverModule
import org.odfi.indesign.ide.module.maven.embedder.EmbeddedMaven
import org.odfi.indesign.core.module.archiva.ArchivaRestInterface
import odfi.server.manager.module.archiva.ODFIArchivaInterface

object FindVersions extends App {
  
  ArtifactResolverModule.moveToStart

  
  var archivaInstall = new ODFIArchivaInterface
  
  archivaInstall.listVersionsFor("org.odfi.indesign.ide", "indesign-ide-core")
  
  
  archivaInstall.getMavenMetadata("odfi", "odfi-server","3.0.0-SNAPSHOT")
}