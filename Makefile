

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
	@echo "Downloading db..."
	@cd .staging && mkdir -p repo/x86_64/ && cd repo/x86_64/ && duck -u 84bdfa378ec247619d3f863c95c05569:${OS_USERNAME} -p ${OS_PASSWORD} -e overwrite -d swift://auth.cloud.ovh.net/packaging/msys2/x86_64/odfi.* .
	@cd .staging/repo/x86_64/ && cp ../../odfi-*-x86_64.pkg.tar.xz . && repo-add odfi.db.tar.xz odfi-*-x86_64.pkg.tar.xz
	@cd .staging/repo/x86_64/ && duck -u 84bdfa378ec247619d3f863c95c05569:${OS_USERNAME} -p ${OS_PASSWORD} -e overwrite --upload swift://auth.cloud.ovh.net/packaging/msys2/x86_64/ odfi*
	
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
	@cp -Rfv lib/nsf/ lib/*.tcl lib/*.tm lib/commands .staging/lib

dist: dist-clean install
	@echo "prepareing dist"
	@cp Makefile $(PREFIX)


dist-clean:
	@echo "Cleaning Dist"
	@rm -Rf $(PREFIX)
	@mkdir -p $(PREFIX)

######### Install for packages ############# 	@cp -Rf private/ $(PREFIX)/usr/share/odfi/private 
# 	@ln -s  $(PREFIX)/share/odfi/bin/odfi $(PREFIX)/bin/odfi
#  @install -D lib/nsf/nsf2.0.0-linux -t $(PREFIX)/share/odfi/lib/nsf/nsf2.0.0-linux
#@mkdir -p $(PREFIX)/share/odfi/lib/nsf
#	@cp -Rf lib/nsf/nsf2.0.0-linux $(PREFIX)/share/odfi/lib/nsf
install:
	@echo "Installing Package to...$(PREFIX)"
	@install -D bin/odfi $(PREFIX)/share/odfi/bin/odfi
	@install -D bin/odfi $(PREFIX)/bin/odfi
	@mkdir -p $(PREFIX)/bin
	@install -D lib/*.tm  -t $(PREFIX)/share/odfi/lib/
	@install -D lib/*.tcl -t $(PREFIX)/share/odfi/lib/
	@install -D lib/commands/*.* -t $(PREFIX)/share/odfi/lib/commands/
	@mkdir -p $(PREFIX)/share/odfi/lib/nsf
	@cp -Rf lib/nsf/nsf2.0.0-linux $(PREFIX)/share/odfi/lib/nsf
	@install -D etc/* -t $(PREFIX)/share/odfi/etc/



######### System ###########################


	
DVERSION:=$(VERSION)-0
DEBKEY?=5D88B0DB

#	@git-dch --ignore-branch --auto
deb: PACKAGE:=deb
deb: DVERSION:=$(VERSION)-0
deb: package 

deb-src: TARGET:=deb 
deb-src: DVERSION:=$(VERSION)-0
deb-src: DIST?=UNRELEASED
deb-src: DCHOPTS?=	
deb-src: stage
	@echo "Making Deb Source Package for $(DIST)..."
	@echo "Packing and Unpacking Stage..."
	@rm -Rf .deb && mkdir -p .deb/odfi_$(VERSION).orig
	@mv -f .staging/* .deb/odfi_$(VERSION).orig
	@cd .deb/ && tar -caf odfi_$(VERSION).orig.tar.gz odfi_$(VERSION).orig
	@echo "Generating Changelog from top folder, will move debian to dist subdirectory later..."
	@rm -Rf debian && cp -Rf packaging/debian .
	@gbp dch --snapshot $(DCHOPTS) --force-distribution --ignore-branch --auto --distribution=$(DIST)
	@mv debian .deb/odfi_$(VERSION).orig/
	@cd .deb/odfi_$(VERSION).orig/ && debuild -k$(DEBKEY) -S

deb-build: DISTRIBUTION?=stable
deb-build: ARCHITECTURE?=amd64
deb-build: MIRRORSITE?=http://ftp.fr.debian.org/debian/
deb-build:
	@mkdir -p .deb/$(DISTRIBUTION)/$(ARCHITECTURE)/
	@rm -Rf .deb/$(DISTRIBUTION)/$(ARCHITECTURE)/*
	@sudo pbuilder --create --mirror $(MIRRORSITE) --distribution $(DISTRIBUTION) --architecture $(ARCHITECTURE)
	@sudo pbuilder --update --mirror $(MIRRORSITE) --override-config --distribution $(DISTRIBUTION) --architecture $(ARCHITECTURE)
	@sudo pbuilder --build  --mirror $(MIRRORSITE) --distribution $(DISTRIBUTION) --architecture $(ARCHITECTURE) .deb/*.dsc
	@cp -v /var/cache/pbuilder/result/odfi* .deb/$(DISTRIBUTION)/$(ARCHITECTURE)/
	@debsign --re-sign -k$(DEBKEY) .deb/$(DISTRIBUTION)/$(ARCHITECTURE)/*.changes

#@sudo pbuilder  --create --distribution $(DIST) --override-config
#@sudo pbuilder  --update --distribution $(DIST) --override-config
#@sudo pbuilder --build --distribution $(DIST) dist/*.dsc



