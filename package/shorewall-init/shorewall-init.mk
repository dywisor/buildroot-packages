################################################################################
#
# shorewall-init
#
################################################################################

SHOREWALL_INIT_VERSION       = $(SHOREWALL_CORE_VERSION)
SHOREWALL_INIT_SOURCE        = shorewall-init-$(SHOREWALL_CORE_VERSION).tar.bz2
SHOREWALL_INIT_SITE          = $(SHOREWALL_CORE_SITE)
SHOREWALL_INIT_LICENSE       = $(SHOREWALL_CORE_LICENSE)
SHOREWALL_INIT_LICENSE_FILES = $(SHOREWALL_CORE_LICENSE_FILES)

# build order: after shorewall-core
SHOREWALL_INIT_DEPENDENCIES = shorewall-core

# using foreign hook
SHOREWALL_INIT_POST_EXTRACT_HOOKS += SHOREWALL_CORE_DO_COPY_RC

ifeq ($(BR2_INIT_OPENRC),y)
define SHOREWALL_INIT_DO_COPY_OPENRC
	cp -- $(SHOREWALL_INIT_PKGDIR)/shorewall-init.initd-buildroot $(@D)/init.gentoo.sh
endef
SHOREWALL_INIT_POST_EXTRACT_HOOKS += SHOREWALL_INIT_DO_COPY_OPENRC

define SHOREWALL_INIT_DO_PURGE_IFUPDOWN
	[ ! -e $(TARGET_DIR)/usr/share/shorewall-init/ifupdown ] || \
		find '$(TARGET_DIR)/usr/share/shorewall-init/ifupdown' -depth -delete
endef
SHOREWALL_INIT_POST_INSTALL_TARGET_HOOKS += SHOREWALL_INIT_DO_PURGE_IFUPDOWN

else
define SHOREWALL_INIT_DO_COPY_SYSV
	cp -- $(@D)/init.sh $(@D)/init.gentoo.sh
endef
SHOREWALL_INIT_POST_EXTRACT_HOOKS += SHOREWALL_INIT_DO_COPY_SYSV
endif

define SHOREWALL_INIT_INSTALL_TARGET_CMDS
	DESTDIR=$(TARGET_DIR) $(SHOREWALL_CORE_ENV) $(@D)/install.sh $(SHOREWALL_CORE_RC)
endef

define SHOREWALL_INIT_DO_REMOVE_LOGROTATE
	$(call SHOREWALL_CORE_F_REMOVE_LOGROTATE,shorewall)
endef
SHOREWALL_INIT_POST_INSTALL_TARGET_HOOKS += SHOREWALL_INIT_DO_REMOVE_LOGROTATE

# init.d script already copied
define SHOREWALL_INIT_INSTALL_INIT_OPENRC
	$(INSTALL) -D -m 0644 -- \
		$(SHOREWALL_INIT_PKGDIR)/shorewall-init.confd \
		$(TARGET_DIR)/etc/conf.d/shorewall-init
endef

$(eval $(generic-package))
