.PHONY: deb

NAME = libsbss-http-client-perl
VERSION = $(shell cat VERSION | sed -e 's,\-.*,,')
RELEASE = $(shell cat VERSION | sed -e 's,.*\-,,')

BUILD_DIR = $(notdir $(shell pwd))
BUILD_DATE = $(shell date +%Y%m%d%H%M%S)
BUILD_ARCH = all

SOURCE_FILES = $(shell ls -AB | grep -i 'lib$$\|makefile$$\|t$$')

# Debian build root
DEB_DIR = $(shell pwd)/build/debian
DEB_ROOT = $(DEB_DIR)/$(NAME)-$(VERSION)/debian
DEB_SOURCE = $(DEB_DIR)/$(NAME)_$(VERSION).orig.tar.gz
DEB_PKG = $(DEB_DIR)/$(NAME)_$(VERSION)-$(RELEASE)_$(BUILD_ARCH).deb

deb: $(DEB_PKG)

$(DEB_ROOT): contrib/debian
	mkdir -p $(DEB_ROOT)
	cp -ad $</* $@/
	find $@ -type f -exec sed -i -e"s/@VERSION@/$(VERSION)/g" {} \;
	find $@ -type f -exec sed -i -e"s/@NAME@/$(NAME)/g" {} \;

$(DEB_SOURCE): $(SOURCE_FILES)
	mkdir -p $(@D)
	tar --transform "s,^,$(NAME)-$(VERSION)/src/$(NAME)/," -f $@ -cz $^

$(DEB_PKG): $(DEB_ROOT) $(DEB_SOURCE)
	cd $(DEB_DIR)/$(NAME)-$(VERSION) && \
	debuild --set-envvar BUILD_APP_VERSION=$(VERSION) --set-envvar BUILD_APP_NAME=$(NAME) -us -uc -b
