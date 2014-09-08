# Makefile for tlp-pcilist.sh, tlp-usblist.sh

S := $(CURDIR)
O := $(S)

# Evaluate parameters
TLP_LIBDIR ?= /usr/lib
TLP_BIN    ?= /usr/bin
TLP_TLIB    = $(TLP_LIBDIR)/tlp-pm


# Catenate DESTDIR to paths
_BIN   = $(DESTDIR)$(TLP_BIN)
_TLIB  = $(DESTDIR)$(TLP_TLIB)

DEVLIST_SCRIPTS = $(addprefix tlp-,$(addsuffix list.sh,pci usb))

# Make targets
all: $(addprefix $(O)/,$(DEVLIST_SCRIPTS))

clean:
	rm -f -- $(addprefix $(O)/,$(DEVLIST_SCRIPTS))


install:
	install -D -m 755 -- tlp-usblist.sh $(_BIN)/tlp-usblist
	install -D -m 755 -- tlp-pcilist.sh $(_BIN)/tlp-pcilist
	install -D -m 755 -- tlp-devlist-functions $(_TLIB)/tlp-devlist-functions

$(O)/tlp-%.sh: $(S)/gen-tlp-devlist-prog.sh
	mkdir -p -- $(@D)
	$< '$*' '$(TLP_TLIB)' > $@.make_tmp
	sh -n $@.make_tmp
	mv -- $@.make_tmp $@
