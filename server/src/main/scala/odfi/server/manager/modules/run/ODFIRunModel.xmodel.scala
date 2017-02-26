package odfi.server.manager.modules.run

import com.idyria.osi.ooxoo.model.ModelBuilder
import com.idyria.osi.ooxoo.model.producers
import com.idyria.osi.ooxoo.model.producer
import com.idyria.osi.ooxoo.model.out.markdown.MDProducer
import com.idyria.osi.ooxoo.model.out.scala.ScalaProducer
import com.idyria.osi.ooxoo.core.buffers.structural.io.sax.STAXSyncTrait

@producers(Array(
  new producer(value = classOf[ScalaProducer]),
  new producer(value = classOf[MDProducer])))
object ODFIRunModel extends ModelBuilder {

  val run = "Run" is {
    "Date" ofType "datetime"
    "Process" is {
      attribute("vpid") ofType "integer"
    }
    "Statistics" is {
      "Runtime" ofType "long"
      "Success" ofType "boolean" default "true"
    }
    "Stream" multiple {
      "ID" ofType "string"
      "Content" ofType "cdata"
    }
  }

  "ToolRun" is {

    "Artifact" is {
      "groupId" ofType "string"
      "artifactId" ofType "string"
      "version" ofType "string"
    }

    importElement(run).setMultiple

  }

  "FileRun" is {
    withTrait(classOf[STAXSyncTrait])

    "Path" ofType "string"
    "SaveHistory" ofType "integer" default "5"
    "StreamSave" ofType "boolean" default "false"

    importElement(run).setMultiple
  }

}