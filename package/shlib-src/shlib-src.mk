################################################################################
#
# shlib-src
#
################################################################################

SHLIB_SRC_VERSION       = 0.2.908
SHLIB_SRC__GITREF       = 565b02aa13b8e8e54b19cf5126a24ffc8590b43a
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

SHLIB_SHLIBCC         = $(SHLIBCC) -S $(HOST_DIR:/=)$(SHLIB_SRC_INCLUDEDIR)
SHLIB_RUNSCRIPT       = $(HOST_DIR:/=)/usr/bin/shlib-runscript
SHLIB_GENSCRIPT_PROG  = $(HOST_DIR:/=)/usr/bin/shlib-genscript

SHLIB_SRC_GENSCRIPT_ENV =
SHLIB_SRC_GENSCRIPT_ENV += SHLIB_PRJROOT='$(HOST_DIR:/=)$(SHLIB_SRC_SHAREDIR)'
SHLIB_SRC_GENSCRIPT_ENV += SHLIB_SRC_ROOT='$(HOST_DIR:/=)$(SHLIB_SRC_SHAREDIR)'
SHLIB_SRC_GENSCRIPT_ENV += \
	SHLIBCC_WRAPPER='$(SHLIBCC) -S $(HOST_DIR:/=)$(SHLIB_SRC_INCLUDEDIR)'
SHLIB_SRC_GENSCRIPT_ENV += SHLIBCC_ARGS='$(SHLIBCC_FLAGS)'
SHLIB_SRC_GENSCRIPT_ENV += SHLIBCC_LIB_ARGS='$(SHLIBCC_FLAGS) --as-lib'
SHLIB_SRC_GENSCRIPT_ENV += DEFAULT_SHLIB_TARGET='$(SHLIB_SRC_SHAREDIR)/shlib.sh'
SHLIB_SRC_GENSCRIPT_ENV += ALWAYS_LINK_SHLIB=y
SHLIB_SRC_GENSCRIPT_ENV += ALWAYS_LINK=y
SHLIB_SRC_GENSCRIPT_ENV += FORCE=n
SHLIB_SRC_GENSCRIPT_ENV += SCRIPT_BASH=n
SHLIB_SRC_GENSCRIPT_ENV += SCRIPT_INTERPRETER=/bin/sh
SHLIB_SRC_GENSCRIPT_ENV += SCRIPT_VERIFY=y
SHLIB_SRC_GENSCRIPT_ENV += SCRIPT_CHMOD=0644
SHLIB_SRC_GENSCRIPT_ENV += SCRIPT_LIB_CHMOD=0644
SHLIB_SRC_GENSCRIPT_ENV += SCRIPT_STANDALONE=n
SHLIB_SRC_GENSCRIPT_ENV += SCRIPT_OUTFILE= SCRIPT_LIB_OUTFILE=
SHLIB_SRC_GENSCRIPT_ENV += SCRIPT_OUTFILE_REMOVE=y

SHLIB_GENSCRIPT = $(SHLIB_SRC_GENSCRIPT_ENV) $(SHLIB_GENSCRIPT_PROG)

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

	# build genscript helper
	## defsym
	mkdir -p -- $(@D)/build/genscript

	## genscript.sh
	$(SHLIBCC_PROG) --stable-sort --shlib-dir=$(@D)/lib \
		--depfile --main $(@D)/build-scripts/generate_script.sh \
		--short-header --strip-virtual -u \
		--keep-safety-checks=y --enable-debug-code=y \
		--output $(@D)/build/genscript/genscript.sh
endef

define HOST_SHLIB_SRC_INSTALL_CMDS
	$(MAKE1) -C $(@D) \
		$(HOST_SHLIB_SRC__MAKEOPTS) DESTDIR=$(HOST_DIR:/=)/ \
		$(addprefix install-,full-src dynloader)

	mkdir -p -- $(HOST_DIR:/=)$(SHLIB_SRC_SHAREDIR)/scripts
	cp -dR -- $(@D)/scripts/. $(HOST_DIR:/=)$(SHLIB_SRC_SHAREDIR)/scripts/.

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
