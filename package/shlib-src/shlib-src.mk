################################################################################
#
# shlib-src
#
################################################################################

SHLIB_SRC_VERSION       = 0.2.908
SHLIB_SRC__GITREF       = 987e08e2f47ed8f354c3cfac343a7aa469968cdf
SHLIB_SRC_SOURCE        = shlib-$(SHLIB_SRC__GITREF).tar.gz
SHLIB_SRC_SITE          = $(call github,dywisor,shlib,$(SHLIB_SRC__GITREF))
SHLIB_SRC_LICENSE       = GPLv2+
SHLIB_SRC_LICENSE_FILES =

SHLIB_SRC_SHAREDIR      = /usr/share/shlib/default
SHLIB_SRC_INCLUDEDIR    = $(SHLIB_SRC_SHAREDIR)/include

# might build shlibcc wrappers in future
ifeq ($(BR2_PACKAGE_SHLIBCC),y)
SHLIB_SRC_DEPENDENCIES += shlibcc
endif

HOST_SHLIB_SRC_DEPENDENCIES = host-shlibcc

SHLIB_SHLIBCC   = $(SHLIBCC) -S $(HOST_DIR)$(SHLIB_SRC_INCLUDEDIR)
SHLIB_RUNSCRIPT = $(HOST_DIR)/usr/bin/shlib-runscript

SHLIB_SRC__MAKEOPTS_COMMON =
SHLIB_SRC__MAKEOPTS_COMMON += PREFIX=/usr
SHLIB_SRC__MAKEOPTS_COMMON += SHLIB_SHAREDIR=$(SHLIB_SRC_SHAREDIR)
SHLIB_SRC__MAKEOPTS_COMMON += SHLIB_INCLUDEDIR=$(SHLIB_SRC_INCLUDEDIR)
# set relpath manually, coreutils "realpath" required otherwise
SHLIB_SRC__MAKEOPTS_COMMON += BINDIR_TO_SHAREDIR_RELPATH=../share/shlib/default
SHLIB_SRC__MAKEOPTS_COMMON += SHLIBCC_LIB_FLAGS="$(SHLIBCC_FLAGS) --as-lib"

SHLIB_SRC__MAKEOPTS  = $(SHLIB_SRC__MAKEOPTS_COMMON)
ifeq ($(BR2_PACKAGE_SHLIBCC),y)
SHLIB_SRC__MAKEOPTS += SHLIBCC=/usr/bin/shlibcc
else
SHLIB_SRC__MAKEOPTS += SHLIBCC=/bin/false
endif

HOST_SHLIB_SRC__MAKEOPTS  = $(SHLIB_SRC__MAKEOPTS_COMMON)
HOST_SHLIB_SRC__MAKEOPTS += SHLIBCC=$(SHLIBCC_PROG)

ifeq ($(BR2_PACKAGE_SHLIB_SRC_LOADER_DYNAMIC),y)
SHLIB_SRC__LOADER_TYPE = dynloader
else

ifeq ($(BR2_PACKAGE_SHLIB_SRC_LOADER_STATIC),y)
SHLIB_SRC__LOADER_TYPE = staticloader

ifeq ($(BR2_PACKAGE_SHLIB_SRC_LOADER_STATIC_PROVIDE_LIB),y)
define SHLIB_SRC_DO_PROVIDE_STATICLOADER_LIB
	test ! -h $(TARGET_DIR)$(SHLIB_SRC_SHAREDIR)/shlib.sh || \
		rm -f -- $(TARGET_DIR)$(SHLIB_SRC_SHAREDIR)/shlib.sh

	test ! -e $(TARGET_DIR)$(SHLIB_SRC_SHAREDIR)/shlib.sh

	ln -fs -- staticloader/modules/all.sh \
		$(TARGET_DIR)$(SHLIB_SRC_SHAREDIR)/shlib.sh
endef
SHLIB_SRC_POST_INSTALL_TARGET_HOOKS += SHLIB_SRC_DO_PROVIDE_STATICLOADER_LIB
endif

else
SHLIB_SRC__LOADER_TYPE =
endif
endif

# host shlib-src
define HOST_SHLIB_SRC_BUILD_CMDS
	$(MAKE1) -C $(@D) $(HOST_SHLIB_SRC__MAKEOPTS) clean-dynloader
	$(MAKE1) -C $(@D) $(HOST_SHLIB_SRC__MAKEOPTS) dynloader
endef

define HOST_SHLIB_SRC_INSTALL_CMDS
	$(MAKE1) -C $(@D) \
		$(HOST_SHLIB_SRC__MAKEOPTS) DESTDIR=$(HOST_DIR:/=)/ \
		$(addprefix install-,full-src dynloader)

	cp -R -- $(@D)/scripts/. $(HOST_DIR:/=)$(SHLIB_SRC_SHAREDIR)/scripts
endef


# target shlib-src
define SHLIB_SRC_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE1) -C $(@D) \
		$(SHLIB_SRC__MAKEOPTS) DESTDIR=$(TARGET_DIR:/=)/ \
		install-src
endef

ifeq ($(SHLIB_SRC__LOADER_TYPE),)
else
define SHLIB_SRC_DO_BUILD_LOADER
	$(TARGET_MAKE_ENV) $(MAKE1) -C $(@D) \
		$(SHLIB_SRC__MAKEOPTS) clean-$(SHLIB_SRC__LOADER_TYPE)
	$(TARGET_MAKE_ENV) $(MAKE1) -C $(@D) \
		$(SHLIB_SRC__MAKEOPTS) $(SHLIB_SRC__LOADER_TYPE)
endef
SHLIB_SRC_POST_BUILD_HOOKS += SHLIB_SRC_DO_BUILD_LOADER

define SHLIB_SRC_DO_INSTALL_LOADER
	$(TARGET_MAKE_ENV) $(MAKE1) -C $(@D) \
		$(SHLIB_SRC__MAKEOPTS) DESTDIR=$(TARGET_DIR:/=)/ \
		install-$(SHLIB_SRC__LOADER_TYPE)
endef
SHLIB_SRC_POST_INSTALL_TARGET_HOOKS += SHLIB_SRC_DO_INSTALL_LOADER
endif



$(eval $(generic-package))
$(eval $(host-generic-package))
