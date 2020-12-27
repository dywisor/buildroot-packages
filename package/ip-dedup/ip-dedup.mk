################################################################################
#
# ip-dedup
#
################################################################################

IP_DEDUP_VERSION       = 00bb28ffe75ac6a7257e7ba7b7211ae6317b0df8
IP_DEDUP_SITE          = $(call github,dywisor,ip-dedup,$(IP_DEDUP_VERSION))
IP_DEDUP_LICENSE       = MIT
IP_DEDUP_LICENSE_FILES = LICENSE

IP_DEDUP_MAKEOPTS =

define IP_DEDUP_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C '$(@D)' \
		PREFIX=/usr \
		$(TARGET_CONFIGURE_OPTS) $(IP_DEDUP_MAKEOPTS)
endef

define IP_DEDUP_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C '$(@D)' \
		$(TARGET_CONFIGURE_OPTS) $(IP_DEDUP_MAKEOPTS) \
		PREFIX=/usr DESTDIR=$(TARGET_DIR) \
		install-bin install-data install-scripts
endef

$(eval $(generic-package))
