

SHELL=/bin/bash
VERSION=1.0.0
PREFIX=dist/stage

THIS_FILE := $(lastword $(MAKEFILE_LIST))

default:
	@echo "Please choose a valid target"

#@makepkg-mingw -f -C --sign
msys: PACKAGE:=msys
msys: package 

package-msys: 
	@echo "Making MSYS Package"
	@cp packaging/msys2/PKGBUILD .staging/
	@cd .staging && makepkg-mingw -f -C --sign
	#@echo "Downloading db..."
	#@duck -u 84bdfa378ec247619d3f863c95c05569:${OS_USERNAME} -p ${OS_PASSWORD} -e overwrite -d swift://auth.cloud.ovh.net/packaging/msys2/x86_64/odfi.* .
	#@repo-add odfi.db.tar.xz odfi-*-x86_64.pkg.tar.xz
	#@duck -u 84bdfa378ec247619d3f863c95c05569:${OS_USERNAME} -p ${OS_PASSWORD} -e overwrite --upload swift://auth.cloud.ovh.net/packaging/msys2/x86_64/ odfi.*
	
#@sshpass -p "${OS_TENANT_NAME}.${OS_USERNAME}.${OS_PASSWORD}" scp odfi-*-x86_64.pkg.tar.xz pca@gateways.storage.${OS_REGION_NAME}.cloud.ovh.net:/packaging/msys2/x86_64/

######### Stage ############################
package: stage 
	@echo "Done Staging..."
	@echo "Running package-$(PACKAGE)..."
	@$(MAKE) -f $(THIS_FILE) package-$(PACKAGE)

stage:
	@echo "Staging Sources for packaging $(PACKAGE)..."
	@rm -Rf .staging
	@mkdir -p .staging
	@cp -Rfv Makefile bin etc lib/*.tcl lib/*.tm .staging/
	@mkdir .staging/lib
	@cp -Rfv lib/*.tcl lib/*.tm .staging/lib
dist: dist-clean install
	@echo "prepareing dist"
	@cp Makefile $(PREFIX)


dist-clean:
	@echo "Cleaning Dist"
	@rm -Rf $(PREFIX)
	@mkdir -p $(PREFIX)

######### Install for packages ############# 	@cp -Rf private/ $(PREFIX)/usr/share/odfi/private 
install:
	@echo "Installing Package to...$(PREFIX)"
	@install -D bin/odfi $(PREFIX)/usr/share/odfi/bin/odfi
	@mkdir -p $(PREFIX)/bin
	@ln -s  $(PREFIX)/usr/share/odfi/bin/odfi $(PREFIX)/bin/odfi
	@install -D lib/*.tm  -t $(PREFIX)/usr/share/odfi/lib/
	@install -D lib/*.tcl -t $(PREFIX)/usr/share/odfi/lib/
	@install -D etc/* -t $(PREFIX)/usr/share/odfi/etc/

######### System ###########################


	


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



