
namespace eval odfi::manager {






	## ODFi: Describe configuration of a manager
	#############################
	itcl::class ODFI {

		## A Custom name of this manager
		public variable name "local"

		## Folder base path of ODFI (can be file of something else)
		public variable managerHome ""

		## List of current nested groups for module configuration grouping
		public variable groupPath {}

		## The defined Modules
		public variable modules {}

		## The installed Modules
		public variable installedModules {}

		## Build ODFI With a location
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
				set name [file tail $installedModulePath]
				set installedModule [::new odfi::manager::InstalledModule ${name}.installed $installedModulePath]

				lappend installedModules $installedModule

				#odfi::common::println "Installed module: $name"

			}


		}

		public method applyFile file {

			odfi::closures::doFile $file

		}

		## Module config
		######################

		public method group {name closure} {

			lappend groupPath $name

			odfi::closures::doClosure $closure


			set groupPath [lreplace $groupPath end end]
		}

		public method module {name closure} {


			## Create Module
			#######
			set module [::new odfi::manager::Module [join [concat $groupPath $name] -] $closure]

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




	}

	## Describe a module, just a name group and URL for now
	###################################
	itcl::class Module {

		public variable name ""

		public variable url ""

		constructor closure {

			## Remove first :: from full object name for real friendly name
			set name [lindex [split $this ::] end]

			odfi::closures::doClosure $closure


		}

		## Get/Set the GIT Repository URL
		public method url {{fUrl ""}} {

			if {$fUrl!=""} {
				set url $fUrl
			}

			return $url

		}

		## Get Module name
		public method name args {

			return $name

		}

		## @return true if an installed module object has been detected
		public method isInstalled args {

			if {[llength [itcl::find objects ::${name}.installed]]>0} {
				return 1
			} else {
				return 0
			}

		}

		## @return The first instanciated InstalledModule object with same name is this one, but with .installed appended
		public method getInstalledModule args {

			return [lindex [itcl::find objects ::${name}.installed] 0]

		}

		## Update or Install the module
		###################
		public method update args {

			## If not Installed -> Install
			###############
			if {![isInstalled]} {
				odfi::common::println "Module is not installed -> trying to install"
				odfi::common::println "Cloning from $url into $::managerHome/install/$name"

				set installationPath $::managerHome/install/$name

				odfi::git::clone $url $installationPath

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

		public method printInfos args {

			odfi::common::println "- Installation Path: $path"

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
		public method doLad loadResult {


			## Load Default paths
			############################
			if{[file exists $path/bin]} {
				$loadResult env PATH $path/bin
			}

			## Execute extra script
			###############################
			$loadResult apply $loadClosure

		}

		## Setup
		##############

		## Register setup closure
		public method setup closure {
			set setupClosure $closure
		}

		public method doSetup args {

			## Call closure
			odfi::closures::doClosure $setupClosure

		}

	}

	itcl::class LoadResult {

		public variable environment

		## Add a value to a specific environment variable
		public method env {name value} {



		}

		## Output a bash string that can be evaled by bash for env setup
		public method toBash args {


		}


	}

}
