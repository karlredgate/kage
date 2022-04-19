
PACKAGE = kage
PWD := $(shell pwd)
DEPENDENCIES = tcl

MAJOR_VERSION=1
MINOR_VERSION=0
REVISION=0

CFLAGS += -fpic -g
CXXFLAGS += -fpic -g
LDFLAGS += -g

#
# default: build install
default: build

OS := $(shell uname -s)
include Makefiles/$(OS).mk
CXXFLAGS += -I$(OS)

build: all
# all: kage system-uuid
all: kage

include $(shell uname)/Platform.mk

# changed to -O1 from -O2, since -O2 screws up valgrind.  This
# should be good enough for shipping anyway.
# INCLUDE_DIRS = -I../xen/vendor/dist/install/usr/include -I../libservice -I../network
# INCLUDE_DIRS = -Ixen -Ilibservice -Inetwork -I$(shell pwd)
INCLUDE_DIRS += -I.
# CXXFLAGS += -g -O1 $(INCLUDE_DIRS) -Wall -rdynamic
CXXFLAGS += -g -O1 $(INCLUDE_DIRS)
CFLAGS += -g -O1 $(INCLUDE_DIRS) -Wall
LDFLAGS += -g -O1

OBJS = kage.o 
OBJS += Allocator.o
OBJS += $(PLATFORM_OBJS)

CLEANS += kage $(OBJS)
kage: $(OBJS)
	@: $(CXX) $(CXXFLAGS) -o $@ $^ -L../network -lnetmgr -L../network/netlib -lnetlib -L../network/netcfg -lnetcfg -L../libservice -lservice -lpthread -ltcl -lexpect5.44.1.15
	$(CXX) $(LDFLAGS) -o $@ $^ -lpthread -ltcl

CLEANS += system-uuid
system-uuid: system-uuid.o
	@: $(CXX) $(CXXFLAGS) -o $@ $^ -L../libservice -lservice -lpthread
	$(CXX) $(CXXFLAGS) -o $@ $^ -lpthread

install: rpm
	$(INSTALL) --directory --mode 755 $(RPM_DIR)
	rm -f $(RPM_DIR)/kage-*.rpm
	cp rpm/RPMS/*/kage-*.rpm $(RPM_DIR)/

uninstall:
	rm -f $(RPM_DIR)/kage-*.rpm

rpm: dist
	rm -rf rpm
	mkdir -p rpm/BUILD rpm/RPMS rpm/BUILDROOT
	rpmbuild -bb --buildroot=$(TOP)platform/kage/rpm/BUILDROOT kage.spec

dist: build
	$(RM) -rf exports
	mkdir -p exports
	$(INSTALL) -d --mode=755 exports/usr/sbin
	$(INSTALL) --mode=755 kage exports/usr/sbin
	$(INSTALL) --mode=755 system-uuid exports/usr/sbin
	$(INSTALL) -d --mode=755 exports/usr/share/kage
	$(INSTALL) -d --mode=755 exports/usr/share/man/man8
	$(INSTALL) kage.8 exports/usr/share/man/man8

clean:
	$(RM) -rf $(CLEANS)
	$(RM) -rf rpm exports

distclean: uninstall clean

.PHONY: test

test:
	for testcase in testcases/*; do ./kage $$testcase ; done
