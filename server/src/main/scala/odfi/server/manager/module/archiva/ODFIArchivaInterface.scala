package odfi.server.manager.module.archiva

import org.odfi.indesign.core.module.archiva.ArchivaRestInterface
import java.net.HttpURLConnection
import com.idyria.osi.tea.io.TeaIOUtils
import java.net.URL

class ODFIArchivaInterface extends ArchivaRestInterface("https://www.opendesignflow.org/maven") {
  
  
  /**
   * https://www.opendesignflow.org/maven/repository/snapshots/odfi/odfi-server/3.0.0-SNAPSHOT/maven-metadata.xml
   */
  def getMavenMetadata(groupId: String, artifactId: String, version: String) = {

    var metadataFile = version.endsWith("-SNAPSHOT") match {
      case true => 
        s"https://www.opendesignflow.org/maven/repository/snapshots/$groupId/$artifactId/$version/maven-metadata.xml"
      case false => 
        s"https://www.opendesignflow.org/maven/repository/internal/$groupId/$artifactId/$version/maven-metadata.xml"
        
    }
    
    //-- OPen Connection
    var url = new URL(metadataFile)
    var con = url.openConnection().asInstanceOf[HttpURLConnection]
    con.addRequestProperty("Accept", "application/xml")
    con.connect()

    // Get String
    var is = con.getInputStream
    var respXML = new String(TeaIOUtils.swallowStream(is))
    
    // Make XML
    org.odfi.indesign.ide.module.maven.metadata(respXML)
    
    /*AetherResolver.resolveArtifact(groupId, artifactId, version) match {
      case Some(art) =>
        art.getProperties.asScala.foreach {
          case (k, v) =>
            println("MD : " + k)
        }
        var mreq = new MetadataRequest
        var mdata = new DefaultMetadata(groupId, artifactId, version, "jar", Metadata.Nature.RELEASE_OR_SNAPSHOT)
        mreq.setMetadata(mdata)

        // mreq.setRequestContext(context)
        //mreq.setArtifact(art)

        // AetherResolver.system.resolveMetadata(session, requests)
        var mresult = AetherResolver.system.resolveMetadata(AetherResolver.session, List(mreq).asJava).asScala.toList

        print("MREs size: " + mresult.size)
        mresult.foreach {
          mdataRes =>
            var md = mdataRes.getMetadata
            //mdataRes.
            //println("V: " + md.getVersion)
            md.getProperties.asScala.foreach {
              case (k, v) =>
                println("MD : " + k)
            }
        }

      case None =>
    }*/

    //AetherResolver
  }
  
}