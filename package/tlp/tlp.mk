################################################################################
#
# tlp
#
################################################################################

TLP_VERSION        = 0.5
TLP_SITE           = $(call github,linrunner,TLP,$(TLP_VERSION))
TLP_LICENSE        = GPLv2+ GPLv3
TLP_LICENSE_FILES  = COPYING LICENSE

TLP__LIBDIR        = /usr/lib/tlp-pm
TLP__ULIB          = /lib/udev
TLP__SYSTEMDLIB    = /lib/systemd
TLP__CONFFILE      = $(call qstrip,$(BR2_PACKAGE_TLP_CONFFILE_PATH))

TLP__X_EMPTY     =
TLP__X_SPACE     = $(TLP__X_EMPTY) $(TLP__X_EMPTY)
TLP__X_WS_STRIP  = $(subst $(space),,$(1))
TLP__X_WS_QSTRIP = $(call qstrip,$(subst $(space),,$(1)))



TLP_RUN_EDITVAR    = \
	X_LS_FILES='$(@D)/addons/build-scripts/list_src_files.sh' \
	'$(@D)/addons/build-scripts/edit_var.sh' '$(@D)'

TLP_DOEXE = $(INSTALL) -D -m 0755 --
TLP_DOINS = $(INSTALL) -D -m 0644 --
TLP_DOSYM = ln -fs --


BR2_PACKAGE_TLP_SYSTYPE_DESC ?= undef
TLP__LOCALVER = -br-dirty+$(BR2_PACKAGE_TLP_SYSTYPE_DESC)

ifeq ($(BR2_PACKAGE_TLP_DEVLIST_IMPL_SHELL),y)
TLP__LOCALVER += +noperl
endif

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

# sed options for removing/editing lines in the Makefile
TLP__MAKEFILE_SED =

# always (unconditionally) remove thinkpad-radiosw
TLP__MAKEFILE_SED += -e '/thinkpad-radiosw/d'

# disable installation of wireless scripts [optional]
ifneq ($(BR2_PACKAGE_TLP_FEATURE_WIRELESS),y)
TLP__MAKEFILE_SED += -e '/\(_BIN\)\/(bluetooth|wifi|wwan)/d'
endif

# disable installation of tlp-pcilist [optional]
ifneq ($(BR2_PACKAGE_TLP_PCILIST),y)
TLP__MAKEFILE_SED += -e '/install\s.*\s+tlp-pcilist/d'
endif

# disable installation of tlp-usblist [optional]
ifneq ($(BR2_PACKAGE_TLP_USBLIST),y)
TLP__MAKEFILE_SED += -e '/install\s.*\s+tlp-usblist/d'
endif


# POST_PATCH: apply TLP__MAKEFILE_SED
ifneq ($(TLP__MAKEFILE_SED),)
define TLP_DO_EDIT_MAKEFILE
	sed -r -i $(@D)/Makefile $(TLP__MAKEFILE_SED)
endef
TLP_POST_PATCH_HOOKS += TLP_DO_EDIT_MAKEFILE
endif


# POST_PATCH: addons dir
define TLP_DO_IMPORT_ADDONS
	cp -a    -- $(PKGDIR)/addons/ $(@D)/addons/
	chmod +x -- $(@D)/addons/build-scripts/?*.sh
endef
TLP_POST_EXTRACT_HOOKS += TLP_DO_IMPORT_ADDONS


# POST_PATCH: replace-conffile [optional]
ifneq ($(call qstrip,$(BR2_PACKAGE_TLP_CONFIG)),)
define TLP_DO_REPLACE_CONFFILE
#  import custom config file
	rm    -- $(@D)/default
	cp -L -- '$(call qstrip,$(BR2_PACKAGE_TLP_CONFIG))' $(@D)/default
endef
TLP_POST_PATCH_HOOKS += TLP_DO_REPLACE_CONFFILE
endif


# POST_PATCH: set TLP_LOAD_MODULES in conffile [optional]
ifneq ($(BR2_PACKAGE_TLP_LOAD_MODULES),y)
define TLP_DO_DISABLE_MODLOAD
	printf "\n# %s\nTLP_LOAD_MODULES=n\n\n" \
		"disable automatic kernel module loading on startup" \
		>> $(@D)/default
endef
TLP_POST_PATCH_HOOKS += TLP_DO_DISABLE_MODLOAD
endif


# POST_PATCH: set CONFFILE path [optional]
ifneq ($(TLP__CONFFILE),)
ifneq ($(TLP__CONFFILE),/etc/default/tlp)
define TLP_DO_SET_CONFFILE_PATH
	$(TLP_RUN_EDITVAR) CONFFILE '$(TLP__CONFFILE)' '/etc/default/tlp'
endef
TLP_POST_PATCH_HOOKS += TLP_DO_SET_CONFFILE_PATH
endif
endif

# POST_PATCH: set custom version str
define TLP_DO_SET_VER
	$(TLP_RUN_EDITVAR) TLPVER \
		$(call TLP__X_WS_QSTRIP,$(TLP_VERSION)$(TLP__LOCALVER))
endef
TLP_POST_PATCH_HOOKS += TLP_DO_SET_VER

# POST_PATCH: set LSBREL path to TLP__LIBDIR/fake_lsb_release
#  (lsb_release not available in target)
## $(TLP_RUN_EDITVAR) LSBREL '\$${libdir}/fake_lsb_release'
define TLP_DO_SET_LSBREL
	$(TLP_RUN_EDITVAR) LSBREL '$(TLP__LIBDIR)/fake_lsb_release'
endef
TLP_POST_PATCH_HOOKS += TLP_DO_SET_LSBREL


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
	cp -- $(addprefix $(@D)/,addons/tpacpi-bat.null tpacpi-bat)
endef
TLP_POST_BUILD_HOOKS += TLP_DO_REPLACE_TPACPIBAT
endif


# POST_BUILD: create tlp-{pci,usb}list with devlist-sh scripts [optional]
ifeq ($(BR2_PACKAGE_TLP_DEVLIST_IMPL_SHELL),y)
define TLP_DO_BUILD_DEVLIST_SH
#  create tlp-devlist-functions scripts
	$(MAKE) -C '$(@D)/addons/devlist-sh' $(TLP__MAKEOPTS)

#  replace tlp-pcilist [sh]
	rm -- $(@D)/tlp-pcilist
	cp -- $(addprefix $(@D)/,addons/devlist-sh/tlp-pcilist.sh tlp-pcilist)

#  replace tlp-usblist [sh]
	rm -- $(@D)/tlp-usblist
	cp -- $(addprefix $(@D)/,addons/devlist-sh/tlp-usblist.sh tlp-usblist)
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
	$(MAKE) -C '$(@D)' $(TLP__MAKEOPTS) DESTDIR=$(TARGET_DIR)/ install-tlp

#  lsb_release dummy script
	$(TLP_DOEXE) \
		$(@D)/addons/fake_lsb_release \
		$(TARGET_DIR)$(TLP__LIBDIR)/fake_lsb_release
endef

# POST_INSTALL_TARGET: install tlp-devlist-functions [optional]
ifeq ($(BR2_PACKAGE_TLP_NEED_DEVLIST)$(BR2_PACKAGE_TLP_DEVLIST_IMPL_SHELL),yy)
define TLP_DO_INSTALL_DEVLIST_FUNCTIONS
#  tlp-devlist-functions [libdir]
	$(TLP_DOINS) \
		$(@D)/addons/devlist-sh/tlp-devlist-functions \
		$(TARGET_DIR)/$(TLP__LIBDIR)/tlp-devlist-functions
endef
TLP_POST_INSTALL_TARGET_HOOKS += TLP_DO_INSTALL_DEVLIST_FUNCTIONS
endif

# POST_INSTALL_TARGET: install tlp-rdw [optional]
ifeq ($(BR2_PACKAGE_TLP_RDW),y)
define TLP_DO_INSTALL_RDW
	$(MAKE) -C '$(@D)' $(TLP__MAKEOPTS) DESTDIR=$(TARGET_DIR)/ install-rdw
endef
TLP_POST_INSTALL_TARGET_HOOKS += TLP_DO_INSTALL_RDW
endif

# pre-POST_INSTALL_TARGET: systemd files
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
#  (pm-utils files should be installed by $(@D)/Makefile)
#  -- unreachable (only systemd supported so far)
define TLP_INSTALL_INIT_SYSV
#  tlp.init [sysV]
   $(TLP_DOEXE) $(@D)/tlp.init $(TARGET_DIR)/etc/init.d/S80tlp
endef



$(eval $(generic-package))
