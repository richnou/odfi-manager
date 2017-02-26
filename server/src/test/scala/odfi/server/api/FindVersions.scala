package odfi.server.api

import org.odfi.indesign.core.artifactresolver.ArtifactResolverModule
import org.odfi.indesign.ide.module.maven.embedder.EmbeddedMaven
import org.odfi.indesign.core.module.archiva.ArchivaRestInterface

object FindVersions extends App {
  
  ArtifactResolverModule.moveToStart

  
  var archivaInstall = new ArchivaRestInterface("https://www.opendesignflow.org/maven")
  
  archivaInstall.getVersionsFor("org.odfi.indesign.ide", "indesign-ide-core")
  
}