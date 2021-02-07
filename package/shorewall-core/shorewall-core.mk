################################################################################
#
# shorewall-core
#
################################################################################

SHOREWALL_CORE_MAJOR_VERSION = 5.2
SHOREWALL_CORE_MINOR_VERSION = 8

SHOREWALL_CORE_RC = shorewallrc.buildroot

SHOREWALL_CORE_VERSION       = $(SHOREWALL_CORE_MAJOR_VERSION).$(SHOREWALL_CORE_MINOR_VERSION)
SHOREWALL_CORE_SOURCE        = shorewall-core-$(SHOREWALL_CORE_VERSION).tar.bz2
SHOREWALL_CORE_SITE          = https://shorewall.org/pub/shorewall/$(SHOREWALL_CORE_MAJOR_VERSION)/shorewall-$(SHOREWALL_CORE_VERSION)
SHOREWALL_CORE_LICENSE       = GPL-2
SHOREWALL_CORE_LICENSE_FILES = COPYING

SHOREWALL_CORE_ENV =
SHOREWALL_CORE_ENV += DIGEST=

# SHOREWALL_CORE_F_REMOVE_LOGROTATE(name)
define SHOREWALL_CORE_F_REMOVE_LOGROTATE
	[ ! -e $(TARGET_DIR)/etc/logrotate.d/$(1) ] || rm -- $(TARGET_DIR)/etc/logrotate.d/$(1)
	rmdir -- $(TARGET_DIR)/etc/logrotate.d || :
endef

define SHOREWALL_CORE_DO_COPY_RC
	cp -- $(SHOREWALL_CORE_PKGDIR)/$(SHOREWALL_CORE_RC) $(@D)/$(SHOREWALL_CORE_RC)
endef
SHOREWALL_CORE_POST_EXTRACT_HOOKS += SHOREWALL_CORE_DO_COPY_RC

define SHOREWALL_CORE_INSTALL_TARGET_CMDS
	DESTDIR=$(TARGET_DIR) $(SHOREWALL_CORE_ENV) $(@D)/install.sh $(SHOREWALL_CORE_RC)
endef

define SHOREWALL_CORE_INSTALL_INIT_OPENRC
	$(INSTALL) -D -m 0755 -- \
		$(SHOREWALL_CORE_PKGDIR)/shorewall.initd-r3-buildroot \
		$(TARGET_DIR)/etc/init.d/shorewall

	$(INSTALL) -D -m 0644 -- \
		$(SHOREWALL_CORE_PKGDIR)/shorewall.confd-r1 \
		$(TARGET_DIR)/etc/conf.d/shorewall
endef

$(eval $(generic-package))
