################################################################################
#
# better-initramfs
#
################################################################################

BETTER_INITRAMFS_VERSION         = 0.9.0.1
BETTER_INITRAMFS_LIVEVER_REF     = v$(BETTER_INITRAMFS_VERSION)
BETTER_INITRAMFS_SOURCE          = better-initramfs-$(BETTER_INITRAMFS_LIVEVER_REF).tar.gz
BETTER_INITRAMFS_SITE            = $(call github,slashbeast,better-initramfs,$(BETTER_INITRAMFS_LIVEVER_REF))
BETTER_INITRAMFS_LICENSE         = BSD-2c
BETTER_INITRAMFS_LICENSE_FILES   = LICENSE

# dependencies
BETTER_INITRAMFS_DEPENDENCIES =

# build after lvm2
ifeq ($(BR2_PACKAGE_LVM2),y)
BETTER_INITRAMFS_DEPENDENCIES += lvm2
endif

# INSFILE ( src, dst:=src, mode:=0644 )
define BETTER_INITRAMFS_INSFILE
	$(INSTALL) -D -m $(or $(3),0644) -- \
		$(@D)/sourceroot/$(1) $(TARGET_DIR:/=)/$(or $(2),$(1))
endef

# RECURSIVE_FILE_INSTALL ( abs_src, rel_dst, filemode:=0644, **TARGET_DIR )
define BETTER_INITRAMFS_RECURSIVE_FILE_INSTALL
	test -n '$(SHELL)'
	cd '$(1)' && \
		find ./ -type f -print0 | \
			xargs -0 -n 1 -I '{FILE}' $(SHELL) -c \
				'set -- install -D -m $(or $(3),0644) -- "{FILE}" \
					"$(TARGET_DIR:/=)/$(2:/=)/{FILE}" && \
				printf "%s\n" "$${*}" && \
				"$${@}"'
endef

BETTER_INITRAMFS__IMPORT_HOOK_DIRS = \
	$(call qstrip,$(BR2_PACKAGE_BETTER_INITRAMFS_HOOK_DIRS))

ifeq ($(BETTER_INITRAMFS__IMPORT_HOOK_DIRS),)
else
define BETTER_INITRAMFS_DO_IMPORT_HOOKS
	mkdir -p -- $(@D)/sourceroot/hooks
	for src in $(BETTER_INITRAMFS__IMPORT_HOOK_DIRS); do \
		cp -dpR -- "$${src}/." $(@D)/sourceroot/hooks/. || exit; \
	done
endef
BETTER_INITRAMFS_POST_EXTRACT_HOOKS += BETTER_INITRAMFS_DO_IMPORT_HOOKS
endif

BETTER_INITRAMFS__KEYMAP_SRC = \
	$(call qstrip,$(BR2_PACKAGE_BETTER_INITRAMFS_KEYMAP_FILE))

ifeq ($(BETTER_INITRAMFS__KEYMAP_SRC),)
else
define BETTER_INITRAMFS_DO_IMPORT_KEYMAP_FILE
	$(or $(call suitable-extractor,$(BETTER_INITRAMFS__KEYMAP_SRC)),cat) \
		$(BETTER_INITRAMFS__KEYMAP_SRC) > $(@D)/sourceroot/keymap
endef
BETTER_INITRAMFS_POST_EXTRACT_HOOKS += BETTER_INITRAMFS_DO_IMPORT_KEYMAP_FILE

define BETTER_INITRAMFS_DO_INSTALL_KEYMAP_FILE
	$(call BETTER_INITRAMFS_INSFILE,keymap,,)
endef
BETTER_INITRAMFS_POST_INSTALL_TARGET_HOOKS += \
	BETTER_INITRAMFS_DO_INSTALL_KEYMAP_FILE
endif

define BETTER_INITRAMFS_DO_EDIT_SOURCES
	sed -r -i $(@D)/sourceroot/functions.sh \
		-e 's#/bin/cryptsetup#/usr/sbin/cryptsetup#g'
endef
BETTER_INITRAMFS_POST_PATCH_HOOKS += BETTER_INITRAMFS_DO_EDIT_SOURCES

define BETTER_INITRAMFS_BUILD_CMDS
	mkdir -p -- $(@D)/sourceroot/hooks
	printf "%s\n" "$(BETTER_INITRAMFS_LIVEVER_REF)" > $(@D)/sourceroot/VERSION
endef

define BETTER_INITRAMFS_INSTALL_TARGET_CMDS
	$(call BETTER_INITRAMFS_INSFILE,VERSION,,)
	$(call BETTER_INITRAMFS_INSFILE,functions.sh,,)
	$(call BETTER_INITRAMFS_INSFILE,init,,0755)
	$(call BETTER_INITRAMFS_INSFILE,etc/lvm/lvm.conf,,)
	# noins sourceroot/etc/profile
	$(call BETTER_INITRAMFS_INSFILE,etc/profile.d/00_profile.sh,etc/profile.d/50_better-initramfs.sh,)
	$(call BETTER_INITRAMFS_INSFILE,etc/suspend.conf,,)
	$(call BETTER_INITRAMFS_INSFILE,bin/resume-boot,,0755)
	$(call BETTER_INITRAMFS_INSFILE,bin/unlock-luks,,0755)
	$(call BETTER_INITRAMFS_RECURSIVE_FILE_INSTALL,$(@D)/sourceroot/hooks,hooks,0755)
endef

$(eval $(generic-package))
