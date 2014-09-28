################################################################################
#
# tlp
#
################################################################################

TLP_VERSION         = 0.5.90X
TLP_LIVEVER_REF     = 3aed0b1051640dcefa7940f8de99e8ee543d02bd
TLP_SOURCE          = tlp-$(TLP_LIVEVER_REF).tar.gz
TLP_SITE            = $(call github,linrunner,TLP,$(TLP_LIVEVER_REF))
TLP_LICENSE         = GPLv2+ GPLv3
TLP_LICENSE_FILES   = COPYING LICENSE

TLP_ADD_LIVEVER_REF = 44c9b64c3571062ba785c14b21a4279b23671526
TLP_ADD_SITE        = \
	$(call github,dywisor,tlp-gentoo-additions,$(TLP_ADD_LIVEVER_REF))
TLP_ADD_SOURCE      = tlp-gentoo-additions-$(TLP_ADD_LIVEVER_REF).tar.gz

TLP__LIBDIR         = /usr/lib/tlp-pm
TLP__ULIB           = /lib/udev
TLP__SYSTEMDLIB     = /lib/systemd
TLP__CONFFILE       = $(or \
	$(call qstrip,$(BR2_PACKAGE_TLP_CONFFILE_PATH)),\
	/etc/default/tlp)

TLP__X_EMPTY        =
TLP__X_SPACE        = $(TLP__X_EMPTY) $(TLP__X_EMPTY)
TLP__X_WS_STRIP     = $(subst $(space),,$(1))
TLP__X_WS_QSTRIP    = $(call qstrip,$(subst $(space),,$(1)))


TLP_DOEXE = $(INSTALL) -D -m 0755 --
TLP_DOINS = $(INSTALL) -D -m 0644 --
TLP_DOSYM = ln -fs --


define TLP_DO_FETCH_ADDITIONS
	$(call DOWNLOAD,$(TLP_ADD_SITE:/=)/$(TLP_ADD_SOURCE))
endef
TLP_POST_DOWNLOAD_HOOKS += TLP_DO_FETCH_ADDITIONS

define TLP_DO_EXTRACT_ADDITIONS
	mkdir -p -- $(@D)/additions
	$(call suitable-extractor,$(TLP_ADD_SOURCE)) $(DL_DIR)/$(TLP_ADD_SOURCE) | \
	$(TAR) $(TAR_STRIP_COMPONENTS)=1 -C $(@D)/additions $(TAR_OPTIONS) -
endef
TLP_POST_EXTRACT_HOOKS += TLP_DO_EXTRACT_ADDITIONS



TLP__LOCALVER = -br-dirty
BR2_PACKAGE_TLP_SYSTYPE_DESC ?= undef
#TLP__LOCALVER += +$(BR2_PACKAGE_TLP_SYSTYPE_DESC)

ifeq ($(BR2_PACKAGE_TLP_DEVLIST_IMPL_SHELL),y)
TLP__LOCALVER += +noperl
endif

define TLP__RUN_MAKE
	$(TARGET_MAKE_ENV) $(MAKE) -C '$(call qstrip,$(1))' \
		$(TLP__MAKEOPTS) TLP_SRC=$(@D) $(2)
endef

define TLP__RUN_MAKE_INSTALL
	$(call TLP__RUN_MAKE,$(1),DESTDIR=$(TARGET_DIR:/=)/ $(2))
endef

# make install options
TLP__MAKEOPTS  =
TLP__MAKEOPTS += TLP_TLIB=$(TLP__LIBDIR) TLP_ULIB=$(TLP__ULIB)
TLP__MAKEOPTS += TLP_CONF=$(TLP__CONFFILE)
# init script is installed separately
TLP__MAKEOPTS += TLP_NO_INIT=1
# bashcomp not needed
TLP__MAKEOPTS += TLP_NO_BASHCOMP=1
# pm-utils not available anyway, no need to install related files
TLP__MAKEOPTS += TLP_NO_PMUTILS=1


# POST_PATCH: replace-conffile [optional]
ifneq ($(call qstrip,$(BR2_PACKAGE_TLP_CONFIG)),)
define TLP_DO_REPLACE_CONFFILE
#  import custom config file
	rm    -- $(@D)/default
	cp -L -- '$(call qstrip,$(BR2_PACKAGE_TLP_CONFIG))' $(@D)/default
endef
TLP_POST_PATCH_HOOKS += TLP_DO_REPLACE_CONFFILE
endif

# commands that will be passed to editsrc
TLP__EDITSRC =

# FIXME: either enable the .service files or uncomment the line below
#TLP__EDITSRC += CFGVAR TLP_ENABLE 0

# + hook that executes editsrc (POST_PATCH)
#   (also applies the base patches)
define TLP_DO_RUN_EDITSRC
	$(call TLP__RUN_MAKE,$(@D)/additions,livepatch-basepatch)

	$(TARGET_MAKE_ENV) bash "$(@D)/additions/bin/tlp-editsrc.bash" \
		-d "$(@D)" $(TLP__EDITSRC)
endef
TLP_POST_PATCH_HOOKS += TLP_DO_RUN_EDITSRC

# set custom version str
TLP__EDITSRC += MACRO appendver \
	"$(call TLP__X_WS_QSTRIP,$(TLP__LOCALVER))"

# set LSBREL path to TLP__LIBDIR/fake_lsb_release
#  (lsb_release not available in target)
TLP__EDITSRC += EDITVAR LSBREL '$(TLP__LIBDIR)/fake_lsb_release'

# relocate libdir files (if != default)
ifneq ($(TLP__LIBDIR),/usr/lib/tlp-pm)
TLP__EDITSRC += MACRO libdir "$(TLP__LIBDIR)"
endif

# always (unconditionally) remove thinkpad-radiosw
TLP__EDITSRC += MACRO no-radiosw

# disable installation of wireless scripts [optional]
ifneq ($(BR2_PACKAGE_TLP_FEATURE_WIRELESS),y)
TLP__EDITSRC += MACRO no-wireless
endif

# disable installation of tlp-pcilist [optional]
# OR install pcilist to sbin (lspci is a dep and in sbin)
ifeq ($(BR2_PACKAGE_TLP_PCILIST),y)
TLP__EDITSRC += MACRO pcilist-sbin
else
TLP__EDITSRC += MACRO no-pcilist
endif

# disable installation of tlp-usblist [optional]
ifneq ($(BR2_PACKAGE_TLP_USBLIST),y)
TLP__EDITSRC += MACRO no-usblist
endif

# set TLP_LOAD_MODULES in conffile
ifeq ($(BR2_PACKAGE_TLP_LOAD_MODULES),y)
TLP__EDITSRC += MACRO TLP_LOAD_MODULES=y
else
TLP__EDITSRC += MACRO TLP_LOAD_MODULES=n
endif

# add TLP_DEBUG to conffile
TLP__EDITSRC += MACRO TLP_DEBUG _

# relocate CONFFILE [optional]
ifneq ($(call qstrip,$(TLP__CONFFILE)),/etc/default/tlp)
TLP__EDITSRC += MACRO conffile "$(TLP__CONFFILE)"
endif

# POST_BUILD:
#  replace tpacpi-bat script
#
# POST_INSTALL_TARGET:
#  install symlink /usr/bin/tpacpi-bat -> TLP__LIBDIR/tpacpi-bat
#
# [optional]
#
ifeq ($(BR2_PACKAGE_TLP_TPACPIBAT),y)

ifeq ($(BR2_PACKAGE_TLP_TPACPIBAT_SYSTEMWIDE),y)
define TLP_DO_INSTALL_TPACPIBAT_SYSTEM_WIDE
#  create /usr/bin/tpacpi-bat -> $(TLP__LIBDIR)/tpacpi-bat
	$(TLP_DOSYM) $(TLP__LIBDIR)/tpacpi-bat $(TARGET_DIR)/usr/bin/tpacpi-bat
endef
TLP_POST_INSTALL_TARGET_HOOKS += TLP_DO_INSTALL_TPACPIBAT_SYSTEM_WIDE
endif

else

define TLP_DO_REPLACE_TPACPIBAT
#  replace tpacpi-bat with dummy script
	rm -- $(@D)/tpacpi-bat
	cp -- $(@D)/additions/files/buildroot/tpacpi-bat.null $(@D)/tpacpi-bat
endef
TLP_POST_BUILD_HOOKS += TLP_DO_REPLACE_TPACPIBAT
endif


# POST_BUILD: create tlp-{pci,usb}list with devlist-sh scripts [optional]
ifeq ($(BR2_PACKAGE_TLP_DEVLIST_IMPL_SHELL),y)
define TLP_DO_BUILD_DEVLIST_SH
#  create tlp-devlist-functions scripts
	$(call TLP__RUN_MAKE,$(@D)/additions/devlist-sh,)

#  replace tlp-pcilist [sh]
	rm -- $(@D)/tlp-pcilist
	cp -- $(@D)/additions/devlist-sh/tlp-pcilist.sh $(@D)/tlp-pcilist

#  replace tlp-usblist [sh]
	rm -- $(@D)/tlp-usblist
	cp -- $(@D)/additions/devlist-sh/tlp-usblist.sh $(@D)/tlp-usblist
endef
TLP_POST_BUILD_HOOKS += TLP_DO_BUILD_DEVLIST_SH
endif


### base install ###
# * force reinstall of TLP__CONFFILE
#    by removing it before running make install
#
define TLP_INSTALL_TARGET_CMDS
#  remove old config file
	rm -f -- $(TARGET_DIR)/$(TLP__CONFFILE)

#  install tlp
	$(call TLP__RUN_MAKE_INSTALL,$(@D),install-tlp)

#  lsb_release dummy script
	$(TLP_DOEXE) \
		$(@D)/additions/files/buildroot/fake_lsb_release \
		$(TARGET_DIR)$(TLP__LIBDIR)/fake_lsb_release
endef

# POST_INSTALL_TARGET: install tlp-devlist-functions [optional]
ifeq ($(BR2_PACKAGE_TLP_NEED_DEVLIST)$(BR2_PACKAGE_TLP_DEVLIST_IMPL_SHELL),yy)
define TLP_DO_INSTALL_DEVLIST_FUNCTIONS
#  tlp-devlist-functions [libdir]
	$(call TLP__RUN_MAKE_INSTALL,$(@D)/additions/devlist-sh,install-functions)
endef
TLP_POST_INSTALL_TARGET_HOOKS += TLP_DO_INSTALL_DEVLIST_FUNCTIONS
endif

# POST_INSTALL_TARGET: install tlp-rdw [optional]
ifeq ($(BR2_PACKAGE_TLP_RDW),y)
define TLP_DO_INSTALL_RDW
	$(call TLP__RUN_MAKE_INSTALL,$(@D),install-rdw)
endef
TLP_POST_INSTALL_TARGET_HOOKS += TLP_DO_INSTALL_RDW
endif

# (pre-)POST_INSTALL_TARGET: systemd files
define TLP_INSTALL_INIT_SYSTEMD
#  tlp.service [systemd]
	$(TLP_DOINS) \
		$(@D)/tlp.service \
		$(TARGET_DIR)$(TLP__SYSTEMDLIB)/system/tlp.service

#  tlp-sleep.service [systemd]
	$(TLP_DOINS) \
		$(@D)/tlp-sleep.service \
		$(TARGET_DIR)$(TLP__SYSTEMDLIB)/system/tlp-sleep.service
endef

# pre-POST_INSTALL_TARGET: sysv files
#  -- unreachable (only systemd supported so far)
define TLP_INSTALL_INIT_SYSV
#  tlp.init [sysV]
	$(TLP_DOEXE) $(@D)/tlp.init $(TARGET_DIR)/etc/init.d/S80tlp
endef


$(eval $(generic-package))
