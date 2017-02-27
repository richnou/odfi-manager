


all: manager installer

installer: 
	@../../../bin/odfi package.tcl

manager: ../../../server/target/odfi-manager.exe


../../../server/target/odfi-manager.exe:
	@pushd ../../../server/
	@mvn package
	@popd