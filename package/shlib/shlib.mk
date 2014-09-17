################################################################################
#
# shlib
#
################################################################################

# version doesn't matter at all
SHLIB_VERSION       = $(or $(SHLIB_SRC_VERSION),__undef__)
SHLIB_SOURCE        =
SHLIB_SITE          =
SHLIB_LICENSE       = GPLv2+
SHLIB_LICENSE_FILES =

HOST_SHLIB_DEPENDENCIES  = host-shlib-src
SHLIB_DEPENDENCIES       = host-shlib-src

# host shlib file cannot be configured
define HOST_SHLIB_BUILD_CMDS
	$(SHLIB_SHLIBCC) --as-lib all -O $(@D)/host-shlib.sh
endef

define HOST_SHLIB_INSTALL_CMDS
	$(INSTALL) -D -m 0644 -- $(@D)/host-shlib.sh \
		$(HOST_DIR)/$(SHLIB_SRC_SHAREDIR)/shlib.sh
endef

# for target shlib.sh, allow selection of modules etc.
define SHLIB_BUILD_CMDS
	$(SHLIB_SHLIBCC) \
		$(call qstrip,$(BR2_PACKAGE_SHLIB_SHLIBCC_FLAGS)) \
		$(or $(call qstrip,$(BR2_PACKAGE_SHLIB_MODULES)),all) \
		$(addprefix -D,$(call qstrip,$(BR2_PACKAGE_SHLIB_DEPFILES))) \
		-O $(@D)/shlib.sh
endef

define SHLIB_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 -- $(@D)/shlib.sh \
		$(TARGET_DIR)/$(SHLIB_SRC_SHAREDIR)/shlib.sh
endef


$(eval $(generic-package))
$(eval $(host-generic-package))
