################################################################################
#
# diskid
#
################################################################################

DISKID_VERSION       = 6d49c37ec056fe430cbc7fce83cf376e923fc9c8
DISKID_SITE          = $(call github,dywisor,diskid,$(DISKID_VERSION))
DISKID_LICENSE       = LGPLv2.1+ GPLv2 GPLv2+
DISKID_LICENSE_FILES = COPYING

DISKID_EXE = /sbin/diskid

DISKID_MAKEOPTS = X_DISKID=$(DISKID_EXE)

DISKID_MAKEOPTS += MINIMAL=1

ifeq ($(BR2_PREFER_STATIC_LIB),y)
DISKID_MAKEOPTS += STATIC=1
else
DISKID_MAKEOPTS += STATIC=0
endif

define DISKID_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C '$(@D)' \
		$(TARGET_CONFIGURE_OPTS) $(DISKID_MAKEOPTS) \
		diskid ./create_diskid_links.sh
endef

define DISKID_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 -- $(@D)/diskid $(TARGET_DIR:/=)$(DISKID_EXE)
endef

ifeq ($(BR2_PACKAGE_DISKID_LINK_HELPER),y)
define DISKID_DO_INSTALL_LINK_HELPER
	$(INSTALL) -D -m 0755 -- $(@D)/create_diskid_links.sh \
		$(TARGET_DIR:/=)/sbin/create-diskid-links
endef
DISKID_POST_INSTALL_TARGET_HOOKS += DISKID_DO_INSTALL_LINK_HELPER
endif

$(eval $(generic-package))
