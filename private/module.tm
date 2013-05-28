
namespace eval odfi::manager {





	######################################################################
	## ODFi: Describe configuration of a manager
	######################################################################
	itcl::class ODFI {

		## A Custom name of this manager
		public variable name "local"

		## Folder base path of ODFI (can be file of something else)
		public variable managerHome ""

		## Available parents
		public variable parents {}

		## List of current nested groups for module configuration grouping
		public variable groupPath {}

		## The defined Modules
		public variable modules {}

		## The installed Modules
		public variable installedModules {}

		## List with name+closure pairs that provide some closures points
		public variable closuresPoints {}

		## Build ODFI With a location
		#############################################
		constructor cHomePath {

			## Defaults
			###############
			set managerHome $cHomePath
			#set name 		[string range $this 2 end]

			## Apply Config files
			#############
			foreach configFile [glob -types f -nocomplain $managerHome/odfi*.config] {
				applyFile $configFile
			}

			## Installed modules
			####################
			set allModules [glob -types d -nocomplain $managerHome/install/*]
			foreach installedModulePath $allModules {

				## Create Installed
				#####################
				set installedModuleName [file tail $installedModulePath]
				set installedModule [::new odfi::manager::InstalledModule ::${name}.${installedModuleName}.installed $installedModulePath]

				lappend installedModules $installedModule

				#odfi::common::println "Installed module: ::${name}.${installedModuleName}.installed"

			}

			## Load Closure Points
			##########################

			#### File containing multiple closures
			foreach closuresFile [glob -types f -nocomplain $managerHome/private/closures*.tcl] {

				#puts "Found closures file: $closuresFile"

				## Register
				#lappend closuresPoints $closureName $content
				#set closuresPoints [concat $closuresPoints [odfi::common::readFileContent $closuresFile]]

				#puts "Found closures file: $closuresPoints"

				applyFile $closuresFile

			}

			#### Single files closures
			foreach closureFile [glob -types f -nocomplain $managerHome/private/closure.*.tcl] {

				## Closure name
				regexp {closure\.([\w_\.]+)\.tcl} [file tail $closureFile] -> closureName

				## Content
				set content [odfi::common::readFileContent $closureFile]

				## Register
				lappend closuresPoints $closureName $content

			}

		}

		public method applyFile file {

			odfi::closures::doFile $file

		}


		## Hierarchical Installation
		##################################
		public method parent {name location} {

			## Create an ODFI for this parent
			set newODFI [::new odfi::manager::ODFI ::odfi.${name} $location]
			lappend parents $newODFI

		}

		public method eachParent closure {

			foreach parent $parents {

				odfi::closures::doClosure $closure
			}

		}

		## Module config
		######################

		public method group {name closure} {

			lappend groupPath $name

			odfi::closures::doClosure $closure


			set groupPath [lreplace $groupPath end end]
		}

		public method module {moduleName closure} {


			## Create Module
			#######
			set module [::new odfi::manager::Module ::${name}.[join [concat $groupPath $moduleName] -] $closure]

			lappend modules $module

			return $module

		}

		## Executes closure on each configured module, with $module available as variable for current module
		public method eachModule closure {

			foreach module $modules {

				odfi::closures::doClosure $closure
			}

		}

		## Installed Modules
		############################


		## Closures Points
		#################

		## Register a new closure point
		public method closurePoint {name closure} {

			lappend closuresPoints $name $closure

		}

		## Return the closures matching the provided name glob
		public method getClosuresForPoint nameGlob {

			set resultClosures {}

			foreach {name closure} $closuresPoints {

				if {[string match $nameGlob $name]} {

					lappend resultClosures $closure
				}

			}

			return $resultClosures


		}


	}

	######################################################################
	## Describe a module, just a name group and URL for now
	######################################################################
	itcl::class Module {

		## Name of module
		public variable name ""

		## name value pairs of available urls for module
		public variable urls {}

		constructor closure {

			## Remove first :: from full object name for real friendly name
			set name [lindex [split $this .] end]

			#puts "Created module object name: $this"

			odfi::closures::doClosure $closure


		}

		## Get/Set the GIT Repository URL
		public method url {name {fUrl ""}} {

			if {$fUrl!=""} {
				set urls [odfi::list::arrayReplace $urls $name $fUrl]
			}

			return [odfi::list::arrayGet $urls $name]

		}

		## Returns the defined urls
		public method urls args {
			return $urls
		}

		## Get Module name
		public method name args {

			return $name

		}

		## @return true if an installed module object has been detected
		public method isInstalled args {

			if {[llength [itcl::find objects ${this}.installed]]>0} {
				return 1
			} else {
				return 0
			}

		}

		## @return The first instanciated InstalledModule object with same name is this one, but with .installed appended
		public method getInstalledModule args {

			return [lindex [itcl::find objects ${this}.installed] 0]

		}

		## Update or Install the module
		###################
		public method update args {

			## If not Installed -> Install
			###############
			if {![isInstalled]} {
				odfi::common::println "Module is not installed -> trying to install"

				## Choose URL ?
				if {[catch {set choosenURL [url default]}]} {
					odfi::common::println "No default URL Provided, check config -> Aborting...."
					return
				}

				odfi::common::println "Cloning from $choosenURL into $::managerHome/install/$name"

				set installationPath $::managerHome/install/$name

				odfi::git::clone $choosenURL $installationPath

				## Create Module
				######################
				set installedModule [::new odfi::manager::InstalledModule ::${name}.installed $installationPath]

				$installedModule doSetup

			} else {

				## Update Module
				######################
				[getInstalledModule] doUpdate

			}




		}


	}


	## Describe an installed Modules
	##################
	itcl::class InstalledModule {

		public variable name ""

		## Installation Path
		public variable path ""

		## Current Branch that is checked out
		public variable currentBranch

		## Closure executed at load time
		public variable loadClosure ""

		## Closure executed at setup time
		public variable setupClosure ""

		## Parameters: name value pairs in list that are resetup before closures evalutation
		public variable parameters {}

		constructor cInstallationPath {

			## Init
			###############
			set name [file tail $cInstallationPath]
			set path $cInstallationPath

			set currentBranch [odfi::git::current-branch $path]

			## Execute $path/module.odfi as closure if present
			###############
			odfi::closures::doFile $path/module.odfi
		}

		## Get Installed Module name
		public method name args {

			return $name

		}

		## Show installed module informations
		public method printInfos args {

			odfi::common::println "- Installation Path: $path"

		}

		## Record a new Parameter
		public method parameter {name value} {

			set parameters [odfi::list::arrayReplace $parameters $name $value]

		}

		## Update
		################
		public method update args {

			## List Versions (branches) from all remotes
			######################
			odfi::common::println "- Available Versions:"
			odfi::common::printlnIndent
			foreach {remote branches} [odfi::git::list-remote-branches $path] {

				odfi::common::println "- From $remote"

				odfi::common::printlnIndent
				foreach branch $branches {
					odfi::common::println "- Version: $branch"
				}
				odfi::common::printlnOutdent
			}
			odfi::common::printlnOutdent

			## TODO: Ask user to update current version, or switch to another version

			## Update current
			#######################
			odfi::common::println "- Current version: $currentBranch"
			odfi::git::pull $path --rebase

			## Setup
			doSetup

		}

		## Load
		##################

		## Register load closure
		public method load closure {
			set loadClosure $closure
		}

		## Load Module by finding environment updates needed and so on
		public method doLoad loadResult {


			## Apply Load Closures
			#############################
			foreach loadClosurePoint [::odfi getClosuresForPoint load*] {
				$loadResult apply $loadClosurePoint
			}



			## Execute extra script
			###############################

			#### Prepare parameters
			foreach {pName pValue} $parameters {
				set $pName $pValue
			}

			$loadResult apply $loadClosure

		}

		## Setup
		##############

		## Register setup closure
		public method setup closure {
			set setupClosure $closure
		}

		public method doSetup args {

			## Apply Setup Closures
			#############################
			foreach setupClosurePoint [::odfi getClosuresForPoint setup*] {
				odfi::closures::doClosure $setupClosurePoint
			}



			## Execute extra script
			###############################

			#### Prepare parameters
			foreach {pName pValue} $parameters {
				set $pName $pValue
			}

			## Call closure
			odfi::closures::doClosure $setupClosure

		}

	}


	## Gathers Results of Loading, and tries to apply to underlying system
	#################################""
	itcl::class LoadResult {

		## Target Environment modification
		public variable environment {}


		## Apply a closure, typically from installed module configuration to this load result
		public method apply closure {

			odfi::closures::doClosure $closure

		}

		## Add a value to a specific environment variable
		public method env {name value} {

			set environment [odfi::list::arrayConcat $environment $name $value]

		}


		## Output a bash string that can be evaled by bash for env setup
		public method toBash args {

			set resStream [odfi::common::newStringChannel]

			## ENV
			################
			foreach {name val} $environment {

				puts $resStream "export $name=\"[join $val :]:\$$name\""

			}

			## Get Result and return
			flush $resStream
			set res [read $resStream]
			close $resStream

			return $res


		}


	}

}
