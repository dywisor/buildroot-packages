################################################################################
#
# shorewall-hacks
#
################################################################################

SHOREWALL_HACKS_VERSION       = 0.1
SHOREWALL_HACKS_SOURCE        =
SHOREWALL_HACKS_SITE          =
SHOREWALL_HACKS_LICENSE       =
SHOREWALL_HACKS_LICENSE_FILES =

ifeq ($(BR2_PACKAGE_SHOREWALL_HACKS_REMOVE_ANNOTATED),y)
define SHOREWALL_HACKS_DO_REMOVE_ANNOTATED
	$(Q)printf '%s\n' "Removing dot-annotated files ..."
	find $(TARGET_DIR)/usr/share/shorewall -type f -name '*.annotated' -print -delete
endef
# modifying other packages' content -> finalize hook
SHOREWALL_HACKS_TARGET_FINALIZE_HOOKS += SHOREWALL_HACKS_DO_REMOVE_ANNOTATED
#SHOREWALL_HACKS_POST_INSTALL_TARGET_HOOKS += SHOREWALL_HACKS_DO_REMOVE_ANNOTATED
endif


$(eval $(generic-package))
