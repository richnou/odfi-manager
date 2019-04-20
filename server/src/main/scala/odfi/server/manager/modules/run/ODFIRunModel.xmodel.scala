package odfi.server.manager.modules.run

import com.idyria.osi.ooxoo.model.ModelBuilder
import com.idyria.osi.ooxoo.model.producers
import com.idyria.osi.ooxoo.model.producer
import com.idyria.osi.ooxoo.model.out.markdown.MDProducer
import com.idyria.osi.ooxoo.model.out.scala.ScalaProducer
import com.idyria.osi.ooxoo.core.buffers.structural.io.sax.STAXSyncTrait
import org.odfi.indesign.core.harvest.HarvestedResourceDefaultId

@producers(Array(
  new producer(value = classOf[ScalaProducer]),
  new producer(value = classOf[MDProducer])))
object ODFIRunModel extends ModelBuilder {

  val run = "Run" is {

    "Date" ofType "datetime"
    "ProcessID" ofType "integer"

    "Statistics" is {
      "Runtime" ofType "long"
      "Success" ofType "boolean" default "true"
    }
    "Stream" multiple {
      "ID" ofType "string"
      "Content" ofType "cdata"
    }
  }
  
  val runTypeTrait = "RunType" is {
     makeTraitAndUseCustomImplementation
    
  }

  "RunConfiguration" is {
    attribute("name")
    attribute("id")

    
    // Run Types
    //-----------------
    "MavenRun" is {
      makeTraitAndUseCustomImplementation
      withTrait(runTypeTrait)
      withTrait(classOf[HarvestedResourceDefaultId])

      "Artifact" is {
        "groupId" ofType "string"
        "artifactId" ofType "string"
        "version" ofType "string"
      }

      "Path" ofType ("string")

      "BuildGoal" ofType ("string") default "compile"

      "Run" multiple {

        // withTrait(run)
        ofType(run)
        //ofType("odfi.server.manager.modules.run.Run")

        "MainClass" ofType ("string")

        "JDKName" ofType ("string")

        "Args" is {
          "Arg" multiple {
            ofType("string")
          }
        }

      }

    }

    "ExeRun" is {
      
      withTrait(runTypeTrait)
      makeTraitAndUseCustomImplementation
      
      "ExecutablePath" ofType ("file")

      importElement(run).setMultiple
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

}