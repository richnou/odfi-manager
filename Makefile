

deb-buildpackage: DISTRIBUTION?=stable
deb-buildpackage: ARCHITECTURE?=amd64
deb-buildpackage: MIRRORSITE?=http://ftp.fr.debian.org/debian/
deb-buildpackage:
	@gbp buildpackage --git-dist=$(DISTRIBUTION) --git-upstream-branch=dev --git-debian-branch=debian


