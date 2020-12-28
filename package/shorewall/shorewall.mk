################################################################################
#
# shorewall
#
################################################################################

SHOREWALL_VERSION       = $(SHOREWALL_CORE_VERSION)
SHOREWALL_SOURCE        = shorewall-$(SHOREWALL_CORE_VERSION).tar.bz2
SHOREWALL_SITE          = $(SHOREWALL_CORE_SITE)
SHOREWALL_LICENSE       = $(SHOREWALL_CORE_LICENSE)
SHOREWALL_LICENSE_FILES = $(SHOREWALL_CORE_LICENSE_FILES)

# build order: after shorewall-core
SHOREWALL_DEPENDENCIES = shorewall-core

# using foreign hook
SHOREWALL_POST_EXTRACT_HOOKS += SHOREWALL_CORE_DO_COPY_RC

define SHOREWALL_INSTALL_TARGET_CMDS
	DESTDIR=$(TARGET_DIR) $(SHOREALL_CORE_ENV) $(@D)/install.sh $(SHOREWALL_CORE_RC)
endef

define SHOREWALL_DO_REMOVE_LOGROTATE
	$(call SHOREWALL_CORE_F_REMOVE_LOGROTATE,shorewall)
endef
SHOREWALL_POST_INSTALL_TARGET_HOOKS += SHOREWALL_DO_REMOVE_LOGROTATE

$(eval $(generic-package))
