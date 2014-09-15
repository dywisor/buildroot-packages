################################################################################
#
# gentoo-functions
#
################################################################################

GENTOO_FUNCTIONS_VERSION       = 0.9
#GENTOO_FUNCTIONS__GITREF       = gentoo-functions-$(GENTOO_FUNCTIONS_VERSION)
GENTOO_FUNCTIONS__GITREF       = e43405f3b9a57c7b69067aadbf23df33caededa8
GENTOO_FUNCTIONS_SITE          = \
	$(call github,gentoo,gentoo-functions,$(GENTOO_FUNCTIONS__GITREF))
GENTOO_FUNCTIONS_LICENSE       = GPLv2
GENTOO_FUNCTIONS_LICENSE_FILES = COPYING


define GENTOO_FUNCTIONS_DO_DISABLE_MANPAGE_INSTALL
	sed -e '/install.*\$$(MANDIR)/d' -i '$(@D)/Makefile'
endef
GENTOO_FUNCTIONS_POST_PATCH_HOOKS += GENTOO_FUNCTIONS_DO_DISABLE_MANPAGE_INSTALL

define GENTOO_FUNCTIONS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C '$(@D)' $(TARGET_CONFIGURE_OPTS)
endef

define GENTOO_FUNCTIONS_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C '$(@D)' DESTDIR="$(TARGET_DIR)" install
endef

$(eval $(generic-package))
