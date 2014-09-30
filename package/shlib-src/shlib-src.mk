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

SHLIB_SHLIBCC        = $(SHLIBCC) -S $(HOST_DIR:/=)$(SHLIB_SRC_INCLUDEDIR)
SHLIB_RUNSCRIPT      = $(HOST_DIR:/=)/usr/bin/shlib-runscript
SHLIB_GENSCRIPT_PROG = $(HOST_DIR:/=)/usr/bin/shlib-genscript
SHLIB_GENSCRIPT_ARGS = --verify --interpreter /bin/sh --chmod 0644
SHLIB_GENSCRIPT      = $(SHLIB_GENSCRIPT_PROG) $(SHLIB_GENSCRIPT_ARGS)

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
define SHLIB_SRC__PRINTVAR
	printf "%s=%s%s%s\n" "$(1)" "\"" "$(call qstrip,$(2))" "\""
endef

define HOST_SHLIB_SRC_BUILD_CMDS
	$(MAKE1) -C $(@D) $(HOST_SHLIB_SRC__MAKEOPTS) clean-dynloader
	$(MAKE1) -C $(@D) $(HOST_SHLIB_SRC__MAKEOPTS) dynloader

	# build genscript helper
	## defsym
	mkdir -p -- $(@D)/build/genscript

	{ \
		$(call SHLIB_SRC__PRINTVAR,export SHLIB_PRJROOT,$(HOST_DIR:/=)$(SHLIB_SRC_SHAREDIR)); \
		$(call SHLIB_SRC__PRINTVAR,export SHLIBCC_ARGS,$(SHLIBCC_FLAGS)); \
		$(call SHLIB_SRC__PRINTVAR,export SHLIBCC_LIB_ARGS, \$${SHLIBCC_ARGS} --as-lib); \
		$(call SHLIB_SRC__PRINTVAR,DEFAULT_SHLIB_TARGET,$(SHLIB_SRC_SHAREDIR)/shlib.sh); \
	} > $(@D)/build/genscript/defsym.inject

	## shlibcc wrapper (\$${SHLIB_PRJROOT}/CC)
	{ \
		printf "%s\n" '#!/bin/sh'; \
		printf "%s" "exec"; \
		$(foreach exe,$(call qstrip,$(SHLIBCC_PROG)),\
			printf " %s\n\t%s" "\\" "\"$(exe)\"";) \
		\
		$(foreach arg,\
			$(call qstrip,$(SHLIBCC_FLAGS)) \
			--shlib-dir=\"$(call qstrip,$(HOST_DIR:/=)$(SHLIB_SRC_INCLUDEDIR))\" \
			\"\$$@\",\
				printf " %s\n\t\t%s" "\\" "$(arg)";) \
		\
		printf "\n"; \
	} > $(@D)/build/genscript/CC_wrapper

	## genscript.sh
	$(SHLIBCC_PROG) --stable-sort --shlib-dir=$(@D)/lib \
		--depfile --main $(@D)/build-scripts/generate_script.sh \
		--defsym $(@D)/build/genscript/defsym.inject \
		--short-header --strip-virtual -u \
		--keep-safety-checks=y --enable-debug-code=y \
		--output $(@D)/build/genscript/genscript.sh
endef

define HOST_SHLIB_SRC_INSTALL_CMDS
	$(MAKE1) -C $(@D) \
		$(HOST_SHLIB_SRC__MAKEOPTS) DESTDIR=$(HOST_DIR:/=)/ \
		$(addprefix install-,full-src dynloader)

	cp -R -- $(@D)/scripts/. $(HOST_DIR:/=)$(SHLIB_SRC_SHAREDIR)/scripts

	$(INSTALL) -D -m 0755 -- $(@D)/build/genscript/CC_wrapper \
		$(HOST_DIR:/=)$(SHLIB_SRC_SHAREDIR)/CC

	$(INSTALL) -D -m 0755 -- $(@D)/build/genscript/genscript.sh \
		$(SHLIB_GENSCRIPT_PROG)
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
