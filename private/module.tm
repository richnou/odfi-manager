
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
			set name 		[lindex [split $this .] end]

			## Load Closure Points
			####################################################

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

			####################################################

			## Apply Config files
			#############
			foreach configFile [glob -types f -nocomplain $managerHome/odfi*.config] {
				applyFile $configFile
			}


			## Apply User config files 
			#################
			foreach configFile [glob -types f -nocomplain ~/.odfi/*.config] {
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



		}


		## Add a module at the specified path that lives outside ODFI manager and is declared as configured by user
		## It will override any standard installation of the module
		public method addUserInstalledModule path {

			set installedModuleName [file tail $path]
			set installedModule [::new odfi::manager::InstalledModule ::${name}.${installedModuleName}.user $path]
			$installedModule setUser true

			lappend installedModules $installedModule

		}


		## Return name
		public method name args {
			return $name
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

		## @return A list of the installed modules that will be used for loading. The local installed modules override the parent ones
		public method resolveInstalledModules args {

			## Get From Parents and this install 
			########################
			set resultList {}
			foreach parent [concat $parents $this] {

				## Get Modules
				set installedModules [itcl::find objects "*[$parent name].*.installed"]

				#puts "Found installed modules in [$parent name]: [llength $installedModules] "

				foreach installedModule $installedModules {

					## Check module has not already be set
					#######

					## Search in existing for a module with same shortName.installed
					set existing [lsearch -glob $resultList "*[$installedModule name].installed"]

					## If one exists, replace
					if {$existing!=-1} {
						set resultList [lreplace $resultList $existing $existing $installedModule]
					} else {

						## Just add
						lappend resultList $installedModule

					}

				}

			}

			## Now Resolve user installed modules from this install known modules
			###########################
			eachModule {

				## Look for a user install 
				#puts "User search for module [$module name]"
				set userModules [itcl::find objects "*[$this name].[$module name].user"]

				if {[llength $userModules]>0} {

					set userModule [lindex $userModules 0]

					#puts "-> Found user module, searching now for: *[$userModule name].installed"

					## Found a user install, then try to replace 
					set existing [lsearch -glob $resultList "*[$userModule name].installed"]

					## If one exists, replace
					if {$existing!=-1} {
						set resultList [lreplace $resultList $existing $existing $userModule]
					} else {

						## Just add
						lappend resultList $installedModule

					}
				}

			}

			## Add All User modules to output 
			################
			foreach userModule [itcl::find objects "*[$this name].*.user"] {

				lappend resultList $userModule

			}

			return $resultList

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

			foreach {closureName closure} $closuresPoints {

				if {[string match $nameGlob $closureName]} {

					lappend resultClosures $closure
				}

			}

			return $resultClosures


		}

		## Call all the closures point for the given name
		public method callClosurePoint nameGlob {

			foreach closure [getClosuresForPoint $nameGlob] {
				odfi::closures::doClosure $closure
			}
		}

		## Various
		######################
		public method printInfos args {

			## Current Version
			##############
			odfi::common::println "- Current Version: [odfi::git::current-branch $managerHome]"


			## Parent
			#############
			$this eachParent {
				odfi::common::println "- Parent source: $parent"
				odfi::common::printlnIndent
				$parent printInfos
				odfi::common::printlnOutdent
			}

			#### List
			##########################
			odfi::common::println "- Available modules:"
			odfi::common::printlnIndent
			$this eachModule {

				odfi::common::println "Module : [$module fullName]"

				odfi::common::printlnIndent

				## Basic Infos
				foreach {urlName url} [$module urls] {
					odfi::common::println "- URL $urlName ->  $url"
				}


				## Installation paths
				#############
				if {[$module isInstalled]} {

					odfi::common::println "- Installed: yes"

					set installedModule [$module getInstalledModule]
					$installedModule printInfos

				} else {
					odfi::common::println "- Installed: no"
				}

				if {[$module isUserInstalled]} {

					odfi::common::println "- User Installed: yes"
					set installedModule [$module getUserInstalledModule]
					$installedModule printInfos

				} else {
					odfi::common::println "- User Installed: no"
				}

				odfi::common::printlnOutdent


			}

			odfi::common::printlnOutdent

		}


	}

	######################################################################
	## Describe a module, just a name group and URL for now
	######################################################################
	itcl::class Module {

		## Simple Name of module
		private variable name ""

		## Full Name ist the object name, including ODFI install provenance
		private variable fullName ""

		## name value pairs of available urls for module
		private variable urls {}

		constructor closure {

			## Remove first :: from full object name for real friendly name
			set fullName   [string range $this 2 end]
			set name 	   [lindex [split $this .] end]


			#puts "Created module object name: $this"

			odfi::closures::doClosure $closure


		}

		## Get/Set the GIT Repository URL
		#  @closurePoint module.url.add $name $url
		public method url {urlName {url ""}} {

			if {$url!=""} {

				## Call Closure point
				::odfi.local callClosurePoint module.url.add*

				set urls [odfi::list::arrayReplace $urls $urlName $url]
			}

			return [odfi::list::arrayGet $urls $urlName]

		}

		## @return 0 if urlname is not defined, 1 otherwise
		public method hasUrl urlName {

			if {[lsearch -exact $urls $urlName]!=-1} {
				return 1
			} else {
				return 0
			}

		}


		## Returns the defined urls
		public method urls args {
			return $urls
		}

		## Get Module name
		public method name args {

			return $name

		}

		## Get Full Object name
		public method fullName args {

			return $fullName

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

		## @return true if a user installed module object has been detected
		public method isUserInstalled args {

			if {[llength [itcl::find objects ${this}.user]]>0} {
				return 1
			} else {
				return 0
			}

		}

		## @return The first instanciated InstalledModule object with same name is this one, but with .installed appended
		public method getUserInstalledModule args {

			return [lindex [itcl::find objects ${this}.user] 0]

		}
		
		## Update/Install module at specified location as a user module. Quite the same ad normal update, but for custom paths
		## @param args can contain the installation/update path of the module
		public method updateLocation path {

			## Installated at location ? 
			#set installedAtLocation [file exists $path]

			## If not Installed -> Install
			###############
			if {![isUserInstalled]} {

				## Choose URL ?
				if {[catch {set choosenURL [url default]}]} {
					odfi::common::println "No default URL Provided, check config -> Aborting...."
					return
				}

				odfi::git::clone $choosenURL $path

				## Create Module and setup
				######################
				set installedModule [::new odfi::manager::InstalledModule ::${fullName}.user $path]
				$installedModule setUser true
				$installedModule doSetup

			} else {

				## Update Module
				######################
				[getUserModule] doUpdate


			}

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


				set installationPath $::managerHome/install/$name

				odfi::common::println "2 Cloning from $choosenURL into $installationPath"
				odfi::git::clone $choosenURL $installationPath

				## Create Module and setup
				######################
				set installedModule [::new odfi::manager::InstalledModule ::${fullName}.installed $installationPath]

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

		## true if the installation is outside of ODFI manager and set by the user
		public variable user false 

		constructor cInstallationPath {

			## Init
			###############
			set name [file tail $cInstallationPath]
			set path $cInstallationPath

			## FIXME
			if {[string match *local.* $this]} {
				
				if {[catch {
					set currentBranch [odfi::git::current-branch $path]
				}]} {
					set currentBranch "unavailable"
				}
			} else {
				set currentBranch "FIXME, Not local install"
			}

			#
			## Execute $path/module.odfi as closure if present
			###############
			odfi::closures::doFile $path/module.odfi
		}

		## Get Installed Module name
		public method name args {

			return $name

		}

		public method setUser fuser {
			set user $fuser
		}

		public method isUser args {
			return $user
		}

		public method getPath args {
			return $path
		}

		## Show installed module informations
		public method printInfos args {

			odfi::common::println "- Installation Path: $path"

		}

		## Record a new Parameter
		public method parameter {name value} {

			set parameters [odfi::list::arrayReplace $parameters $name $value]

		}

		public method switch-url {name newurl} {

			## Add Remote
			odfi::git::set-remote $path $name $newurl

			## FIXME Update default up
			catch {exec git branch --set-upstream-to $name/[odfi::git::current-branch]}


		}

		## Update
		################
		public method doUpdate args {




			## List Versions (branches) from all remotes
			######################
			odfi::common::println "- Module is here: $path"
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
			odfi::git::pull $path --quiet

			## Setup
			doSetup

			## Check Clean state
			#if {[odfi::git::isClean $path]} {
			#} else {
			#	odfi::common::println "The module installation is not clean, you have changes you should check before updating!"
			#}





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
			foreach loadClosurePoint [::odfi.local getClosuresForPoint load*] {
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
			foreach setupClosurePoint [::odfi.local getClosuresForPoint setup*] {
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

		## Remove
		#########################

		public method remove args {

			odfi::common::println "Removing $name at $path..."

			## Check Status
			if {[odfi::git::isClean $path]} {

				## Delete Folder
				file delete -force -- $path

			} else {

				odfi::common::println "There seems to be some local modifications in the module, maybe you should check that before removing module to avoid losing data"
			}





		}

	}

	######################################################################################
	## Gathers Results of Loading, and tries to apply to underlying system
	######################################################################################
	itcl::class LoadResult {

		## Target Environment modification
		public variable environment {}


		## Apply a closure, typically from installed module configuration to this load result
		public method apply closure {

			odfi::closures::doClosure $closure

		}

		## Add a value to a specific environment variable
		public method env {name value args} {

			## Separator specified ?
			set nameWithSep $name
			if {[odfi::list::arrayContains $args -separator]} {

				set sep [odfi::list::arrayGet $args -separator]
				set nameWithSep [list $name $sep]
			}

			## String value ?
			if {[odfi::list::arrayContains $args -string]} {
				set environment [odfi::list::arrayReplace $environment $nameWithSep $value]
			} else {
				set environment [odfi::list::arrayConcat $environment $nameWithSep $value]
			}



		}


		## Output a bash string that can be evaled by bash for env setup
		public method toBash args {

			set resStream [odfi::common::newStringChannel]

			## ENV
			################
			foreach {name val} $environment {

				## name can be a list with separator specified
				set sep :
				if {[llength $name]>1} {
					set sep [lindex $name 1]
					set name [lindex $name 0]
				}

				## If only one value, keep the variable content simple
				if {[llength $val]<=1} {
					puts $resStream "export $name=\"$val$sep\$$name\""
				} else {
					puts $resStream "export $name=\"[join $val $sep]$sep\$$name\""
				}




			}

			## Get Result and return
			flush $resStream
			set res [read $resStream]
			close $resStream

			return $res


		}


	}

}
