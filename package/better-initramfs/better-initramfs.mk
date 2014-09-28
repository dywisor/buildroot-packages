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

define BETTER_INITRAMFS_INSFILE
	$(INSTALL) -D -m $(or $(3),0644) -- \
		$(@D)/sourceroot/$(1) $(TARGET_DIR:/=)/$(or $(2),$(1))
endef

define BETTER_INITRAMFS_DO_EDIT_SOURCES
	sed -r -i $(@D)/sourceroot/functions.sh \
		-e 's#/bin/cryptsetup#/usr/sbin/cryptsetup#g'
endef
BETTER_INITRAMFS_POST_PATCH_HOOKS += BETTER_INITRAMFS_DO_EDIT_SOURCES

define BETTER_INITRAMFS_BUILD_CMDS
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
endef

$(eval $(generic-package))
