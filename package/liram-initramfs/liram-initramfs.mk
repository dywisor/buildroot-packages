################################################################################
#
# liram-initramfs
#
################################################################################

LIRAM_INITRAMFS_VERSION       = $(or $(SHLIB_SRC_VERSION),__undef__)
LIRAM_INITRAMFS_SOURCE        =
LIRAM_INITRAMFS_SITE          =
LIRAM_INITRAMFS_LICENSE       = GPLv2+
LIRAM_INITRAMFS_LICENSE_FILES =

# dependencies
LIRAM_INITRAMFS_DEPENDENCIES = host-shlibcc host-shlib-src

# INSFILE ( src, dst:="liram/"src, mode:=0644 )
define LIRAM_INITRAMFS_INSFILE
	$(INSTALL) -D -m $(or $(3),0644) -- \
		$(@D)/liram/$(1) $(TARGET_DIR:/=)/$(or $(2),liram/$(1))
endef

# dosym ( link_target, rel_link )
define LIRAM_INITRAMFS_DOSYM
	rm -f -- $(TARGET_DIR)/$(2)
	ln -s -- $(1) $(TARGET_DIR)/$(2)
endef

# RECURSIVE_FILE_INSTALL ( abs_src, rel_dst, filemode:=0644, **TARGET_DIR )
define LIRAM_INITRAMFS_RECURSIVE_FILE_INSTALL
	test -n '$(SHELL)'
	cd '$(1)' && \
		find ./ -type f -print0 | \
			xargs -0 -n 1 -I '{FILE}' $(SHELL) -c \
				'set -- install -D -m $(or $(3),0644) -- "{FILE}" \
					"$(TARGET_DIR:/=)/$(2:/=)/{FILE}" && \
				printf "%s\n" "$${*}" && \
				"$${@}"'
endef

# IMPORT_TO_SRCDIR ( rel_dst, <src_dirs> )
define LIRAM_INITRAMFS_IMPORT_TO_SRCDIR
	mkdir -p -- $(@D)/$(1)
	set -e; for src in $(call qstrip,$(2)); do \
		cp -dpR -- "$${src}/." $(@D)/$(1)/.; \
	done
endef


define LIRAM_INITRAMFS_DO_IMPORT_FILES
	$(call LIRAM_INITRAMFS_IMPORT_TO_SRCDIR,files,$(PKGDIR)/files,)
	$(call LIRAM_INITRAMFS_IMPORT_TO_SRCDIR,liram/layouts,\
		$(LIRAM_INITRAMFS__IMPORT_LAYOUT_DIRS))
endef
LIRAM_INITRAMFS_POST_EXTRACT_HOOKS += LIRAM_INITRAMFS_DO_IMPORT_FILES

define LIRAM_INITRAMFS__GENERATE_HELPER
	$(SHLIB_GENSCRIPT) \
		--name    $(1) \
		--shlib   /liram/functions.sh \
		--output  $(@D)/liram/$(1).sh \
		$(@D)/files/$(1).in
endef

define LIRAM_INITRAMFS_BUILD_CMDS
	mkdir -p -- $(@D)/liram/layouts

	$(SHLIB_GENSCRIPT) \
		--name        initramfs/default \
		--shlib       /liram/functions.sh \
		--split-lib   $(@D)/liram/functions.sh \
		--output      $(@D)/liram/init.sh \
		initramfs/default

	$(call LIRAM_INITRAMFS__GENERATE_HELPER,net-setup)
	$(call LIRAM_INITRAMFS__GENERATE_HELPER,start-dropbear)
endef

define LIRAM_INITRAMFS_INSTALL_TARGET_CMDS
	$(INSTALL) -d -- $(TARGET_DIR)/liram/layouts
	$(call LIRAM_INITRAMFS_INSFILE,init.sh,,0755)
	$(call LIRAM_INITRAMFS_INSFILE,functions.sh,,)
	$(call LIRAM_INITRAMFS_RECURSIVE_FILE_INSTALL,$(@D)/liram/layouts,liram/layouts,0644)
	$(call LIRAM_INITRAMFS_DOSYM,liram/init.sh,init)
	$(call LIRAM_INITRAMFS_DOSYM,liram/functions.sh,functions.sh)
endef

ifeq ($(BR2_PACKAGE_LIRAM_INITRAMFS_NETSETUP_HELPER),y)
define LIRAM_INITRAMFS_DO_INSTALL_NETSETUP_HELPER
	$(INSTALL) -D -m 0755 -- $(@D)/liram/net-setup.sh \
		$(TARGET_DIR:/=)/sbin/net-setup
endef
LIRAM_INITRAMFS_POST_INSTALL_TARGET_HOOKS += \
	LIRAM_INITRAMFS_DO_INSTALL_NETSETUP_HELPER
endif

ifeq ($(BR2_PACKAGE_LIRAM_INITRAMFS_DROPBEAR_HELPER),y)
define LIRAM_INITRAMFS_DO_INSTALL_DROPBEAR_HELPER
	$(INSTALL) -D -m 0755 -- $(@D)/liram/start-dropbear.sh \
		$(TARGET_DIR:/=)/usr/sbin/start-dropbear
endef
LIRAM_INITRAMFS_POST_INSTALL_TARGET_HOOKS += \
	LIRAM_INITRAMFS_DO_INSTALL_DROPBEAR_HELPER
endif

$(eval $(generic-package))
