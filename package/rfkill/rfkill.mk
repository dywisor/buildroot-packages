################################################################################
#
# rfkill
#
################################################################################

RFKILL_VERSION       = 0.5
RFKILL_SOURCE        = rfkill-$(RFKILL_VERSION).tar.xz
RFKILL_SITE          = https://www.kernel.org/pub/software/network/rfkill
RFKILL_LICENSE       = ISC
RFKILL_LICENSE_FILES = COPYING

ifeq ($(BR2_PACKAGE_BUSYBOX),y)
RFKILL_DEPENDENCIES += busybox
endif

# version.sh fails with exit code 2 (<< git version suffix error)
# when not specifying a VERSION_SUFFIX
define RFKILL_BUILD_CMDS
	$(MAKE) -C $(@D) CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" \
		V=1 VERSION_SUFFIX="-br"
endef

define RFKILL_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 -- $(@D)/rfkill $(TARGET_DIR)/usr/sbin/rfkill
endef

define RFKILL_CLEAN_CMDS
	rm -f -- $(TARGET_DIR)/usr/sbin/rfkill
endef

$(eval $(generic-package))
