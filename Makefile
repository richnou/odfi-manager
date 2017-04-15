

SHELL = /bin/bash
VERSION=1.0.0
PREFIX=dist/stage

default:
	@echo "Please choose a valid target"

######### Install for packages #############
install:
	@echo "Installing Package to...$(PREFIX)"
	@mkdir -p $(PREFIX)
	@install -D bin/odfi $(PREFIX)/bin/odfi
	
######### Stage ############################

dist: dist-clean install
	@cp Makefile $(PREFIX)

dist-clean:
	@echo "Cleaning Dist"
	@rm -Rf dist

######### System ###########################

msys:
	@echo "Making MSYS Package"


#	@git-dch --ignore-branch --auto
deb: TARGET:=deb 
deb: DVERSION:=$(VERSION)-0
deb: DIST?=jessie
deb:dist
	@echo "Making Deb Source Package for $(DIST)..."
	@echo "Packing and Unpacking Stage..."
	@mv dist/stage dist/odfi_$(VERSION).orig
	@cd dist/ && tar -caf odfi_$(VERSION).orig.tar.gz odfi_$(VERSION).orig
	@echo "Generating Changelog from top folder, will move debian to dist subdirectory later..."
	@rm -Rf debian && cp -Rf private/packaging/debian .
	@git-dch --force-distribution --ignore-branch --auto --distribution=$(DIST)
	@mv debian dist/odfi_$(VERSION).orig/
	@cd dist/odfi_$(VERSION).orig/ && debuild -k8932D4D3 -S
	@sudo pbuilder --build --distribution $(DIST) dist/*.dsc
	@cp /var/cache/pbuilder/result/* dist/
	@debsign -k8932D4D3 dist/*.changes
#@sudo pbuilder  --create --distribution $(DIST) --override-config
#@sudo pbuilder  --update --distribution $(DIST) --override-config
#@sudo pbuilder --build --distribution $(DIST) dist/*.dsc



