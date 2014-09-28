################################################################################
#
# systemd-hacks
#
################################################################################

SYSTEMD_HACKS_VERSION       = 20140924-r3
SYSTEMD_HACKS_SOURCE        = systemd-hacks_$(SYSTEMD_HACKS_VERSION).xz
SYSTEMD_HACKS_SITE          = http://yugoloth.de/dywi/dl/scripts
SYSTEMD_HACKS_LICENSE       = GPLv2+
SYSTEMD_HACKS_LICENSE_FILES =

SYSTEMD_HACKS__SYSTEMD_LIBDIR = /lib/systemd

define SYSTEMD_HACKS_EXTRACT_CMDS
	mkdir -p -- $(@D)
	$(call suitable-extractor,$(SYSTEMD_HACKS_SOURCE)) \
		$(DL_DIR)/$(SYSTEMD_HACKS_SOURCE) > '$(@D)/systemd-hacks.sh'
	chmod +x -- '$(@D)/systemd-hacks.sh'
endef

# get_key ( kv_pair )
define SYSTEMD_HACKS__KV_GET_KEY
	$(firstword $(subst =, ,$(1)))
endef

# get_val ( kv_pair, fallback )
define SYSTEMD_HACKS__KV_GET_VAL
	$(or $(word 2,$(subst =, ,$(1))),$(call qstrip,$(2)))
endef

### dependencies
SYSTEMD_HACKS_DEPENDENCIES = systemd

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_FIXUP_LIBDIR_ALL),y)
SYSTEMD_HACKS_DEPENDENCIES += \
	$(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_FIXUP_LIBDIR_ALL_DEPS))
endif

# always build after the following packages as this package might want
# to access their files
# (or overwrite/install, which should be explicitly noted)

# @install getty@ service config files
ifeq ($(BR2_PACKAGE_UTIL_LINUX),y)
SYSTEMD_HACKS_DEPENDENCIES += util-linux
endif

# @overwrite avahi-daemon.service
ifeq ($(BR2_PACKAGE_AVAHI),y)
SYSTEMD_HACKS_DEPENDENCIES += avahi
endif

ifeq ($(BR2_PACKAGE_DROPBEAR),y)
SYSTEMD_HACKS_DEPENDENCIES += dropbear
endif

# @install mongoose.service
ifeq ($(BR2_PACKAGE_MONGOOSE),y)
SYSTEMD_HACKS_DEPENDENCIES += mongoose
endif

# @install nfs unit files
ifeq ($(BR2_PACKAGE_NFS_UTILS),y)
SYSTEMD_HACKS_DEPENDENCIES += nfs-utils
endif

# @install rpcbind.service
ifeq ($(BR2_PACKAGE_RPCBIND),y)
SYSTEMD_HACKS_DEPENDENCIES += rpcbind
endif

ifeq ($(BR2_PACKAGE_TLP),y)
SYSTEMD_HACKS_DEPENDENCIES += tlp
endif

# @install tvheadend.service
ifeq ($(BR2_PACKAGE_TVHEADEND),y)
SYSTEMD_HACKS_DEPENDENCIES += tvheadend
endif

### end dependencies

# helper function: get_confedit_expr ( key, newval )
#  *** applies strip() to key and qstrip() to newval ***
#  !!! this assumes that key already exists in journald.conf/logind.conf
#      (true for the keys by this file)
#
define SYSTEMD_HACKS__GET_CONFEDIT_EXPR
	-e 's@^\#?($(strip $(1))=).*$$@\1$(call qstrip,$(2))@i'
endef


### journald.conf edits
SYSTEMD_HACKS__JOURNALD_SED =

ifneq ($(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_JOURNALD_VOLATILE)),)
SYSTEMD_HACKS__JOURNALD_SED += \
	$(call SYSTEMD_HACKS__GET_CONFEDIT_EXPR,Storage,\
		$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_JOURNALD_VOLATILE))
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_MISC_JOURNALD_COMPRESS),y)
SYSTEMD_HACKS__JOURNALD_SED += \
	$(call SYSTEMD_HACKS__GET_CONFEDIT_EXPR,Compress,yes)
endif

ifneq ($(SYSTEMD_HACKS__JOURNALD_SED),)
define SYSTEMD_HACKS_DO_SED_JOURNALD
	sed -r -i '$(TARGET_DIR)/etc/systemd/journald.conf' \
		$(SYSTEMD_HACKS__JOURNALD_SED)
endef
SYSTEMD_HACKS_POST_INSTALL_TARGET_HOOKS += SYSTEMD_HACKS_DO_SED_JOURNALD
endif
### end journald.conf

### timesyncd.conf edits
SYSTEMD_HACKS__TIMESYNCD_SED =

ifneq ($(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_TIMESYNCD_NTP)),)
SYSTEMD_HACKS__TIMESYNCD_SED += \
	$(call SYSTEMD_HACKS__GET_CONFEDIT_EXPR,NTP,\
		$(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_TIMESYNCD_NTP)))
endif

ifneq ($(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_TIMESYNCD_NTP_FALLBACK)),)
SYSTEMD_HACKS__TIMESYNCD_SED += \
	$(call SYSTEMD_HACKS__GET_CONFEDIT_EXPR,FallbackNTP,\
		$(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_TIMESYNCD_NTP_FALLBACK)))
endif

ifneq ($(SYSTEMD_HACKS__TIMESYNCD_SED),)
define SYSTEMD_HACKS_DO_SED_TIMESYNCD
	sed -r -i '$(TARGET_DIR)/etc/systemd/timesyncd.conf' \
		$(SYSTEMD_HACKS__TIMESYNCD_SED)
endef
SYSTEMD_HACKS_POST_INSTALL_TARGET_HOOKS += SYSTEMD_HACKS_DO_SED_TIMESYNCD
endif
### end timesyncd.conf

### logind.conf edits
SYSTEMD_HACKS__LOGIND_SED =

ifneq ($(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_POWER_KEY)),)
SYSTEMD_HACKS__LOGIND_SED += \
	$(call SYSTEMD_HACKS__GET_CONFEDIT_EXPR,HandlePowerKey,\
		$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_POWER_KEY))
endif

ifneq ($(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_SUSPEND_KEY)),)
SYSTEMD_HACKS__LOGIND_SED += \
	$(call SYSTEMD_HACKS__GET_CONFEDIT_EXPR,HandleSuspendKey,\
		$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_SUSPEND_KEY))
endif

ifneq ($(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_HIBERNATE_KEY)),)
SYSTEMD_HACKS__LOGIND_SED += \
	$(call SYSTEMD_HACKS__GET_CONFEDIT_EXPR,HandleHibernateKey,\
		$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_HIBERNATE_KEY))
endif

ifneq ($(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_LID_SWITCH)),)
SYSTEMD_HACKS__LOGIND_SED += \
	$(call SYSTEMD_HACKS__GET_CONFEDIT_EXPR,HandleLidSwitch,\
		$(BR2_PACKAGE_SYSTEMD_HACKS_MISC_LID_SWITCH))
endif

ifneq ($(SYSTEMD_HACKS__LOGIND_SED),)
define SYSTEMD_HACKS_DO_SED_LOGIND
	sed -r -i '$(TARGET_DIR)/etc/systemd/logind.conf' \
		$(SYSTEMD_HACKS__LOGIND_SED)
endef
SYSTEMD_HACKS_POST_INSTALL_TARGET_HOOKS += SYSTEMD_HACKS_DO_SED_LOGIND
endif

### end logind.conf

### symlink fixup
ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_FIXUP_SYMLINKED_DIRS),y)
# helper function: replace_sym_with_dir ( relpath, [mkdir_opts] )
#  relpath := path relative to TARGET_DIR
define SYSTEMD_HACKS__REPLACE_SYM_WITH_DIR
	test ! -h '$(TARGET_DIR)/$(1)' || rm -- '$(TARGET_DIR)/$(1)'
	mkdir -p $(2) -- '$(TARGET_DIR)/$(1)'
endef

# helper function: replace_sym_with_sym ( relpath, link_dest )
#  "ln -s -- link_dest TARGET_DIR/relpath" + sanity checks
#  if relpath exists, it has to be a symlink or a directory
define SYSTEMD_HACKS__REPLACE_SYM_WITH_SYM
	test ! -h '$(TARGET_DIR)/$(1)' || rm -- '$(TARGET_DIR)/$(1)'
	if test -e '$(TARGET_DIR)/$(1)'; then \
		test -d '$(TARGET_DIR)/$(1)'; \
	else \
		mkdir -p -- '$(dir $(TARGET_DIR)/$(1))' && \
		ln -s -- '$(2)' '$(TARGET_DIR)/$(1)'; \
	fi
endef

define SYSTEMD_HACKS_DO_FIXUP_SYMLINKED_DIRS
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_DIR,/run)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_SYM,/var/run,../run)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_SYM,/var/lock,run/lock)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_DIR,/var/lib/dbus)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_DIR,/var/lib/misc)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_DIR,/var/lib/pcmcia)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_SYM,/var/pcmcia,lib/pcmcia)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_DIR,/var/spool)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_DIR,/var/log)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_DIR,/var/tmp,-m 1777)
	$(call SYSTEMD_HACKS__REPLACE_SYM_WITH_DIR,/var/cache)
endef

SYSTEMD_HACKS_POST_INSTALL_TARGET_HOOKS += \
	SYSTEMD_HACKS_DO_FIXUP_SYMLINKED_DIRS
endif
### end symlink fixup

### network config

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_NET_PREDICTABLE),y)
else
define SYSTEMD_HACKS_DO_DISABLE_NET_PREDICTABLE
	mkdir -p -- '$(TARGET_DIR)/etc/systemd/network'
	rm -f -- '$(TARGET_DIR)/etc/systemd/network/99-default.link'
	ln -s -- /dev/null '$(TARGET_DIR)/etc/systemd/network/99-default.link'
endef
SYSTEMD_HACKS_POST_INSTALL_TARGET_HOOKS += \
	SYSTEMD_HACKS_DO_DISABLE_NET_PREDICTABLE
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_NET_DEFAULT_BRIDGE),y)
define SYSTEMD_HACKS__DEFBRIDGE_QOR
	$(or $(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_NET_DEFAULT_BRIDGE_$(1))),$(2))
endef

define SYSTEMD_HACKS_DO_GEN_NETWORKD_CONFIG
	test ! -d "$(@D)/netconfig"
	sh '$(@D)/files/gen-defbridge.sh' -O "$(@D)/netconfig" \
		--bridge-name $(call SYSTEMD_HACKS__DEFBRIDGE_QOR,NAME,lan0) -- \
		--bridge-interfaces $(call SYSTEMD_HACKS__DEFBRIDGE_QOR,INTERFACES,) --\
		--dhcp $(call SYSTEMD_HACKS__DEFBRIDGE_QOR,DHCP,) -- \
		--macaddr $(call SYSTEMD_HACKS__DEFBRIDGE_QOR,MACADDR,) --
	test -d "$(@D)/netconfig"
endef
SYSTEMD_HACKS_POST_BUILD_HOOKS += SYSTEMD_HACKS_DO_GEN_NETWORKD_CONFIG

define SYSTEMD_HACKS_DO_INSTALL_NETWORKD_CONFIG
	test -n "$(SHELL)"
	cd "$(@D)/netconfig" && \
		find ./ -type f -print0 | \
			xargs -0 -n 1 -I '{FILE}' $(SHELL) -c \
				'set -- install -m 0644 -D -- "{FILE}" \
					"$(TARGET_DIR)/etc/systemd/network/{FILE}" && \
				printf "%s\n" "$${*}" && \
				"$${@}"'
endef
SYSTEMD_HACKS_POST_INSTALL_TARGET_HOOKS += \
	SYSTEMD_HACKS_DO_INSTALL_NETWORKD_CONFIG
endif

### end network config



### system unit setup/activation/installation

# copy files/ from pkgdir
define SYSTEMD_HACKS_DO_IMPORT_FILES
	cp -a -- '$(PKGDIR)/files/' '$(@D)/files/'
endef
SYSTEMD_HACKS_POST_EXTRACT_HOOKS += SYSTEMD_HACKS_DO_IMPORT_FILES

# use this instead of defining trivial hooks:
#  (command execution order as listed here)
#
# * install/replace
SYSTEMD_HACKS__UNITS_TO_INSTALL =
# * disable units linking to any unit in the following list
SYSTEMD_HACKS__UNITS_TO_DISABLE =
# * units to enable (using enable_single_unit() <unit>[:=<target>])
SYSTEMD_HACKS__UNITS_TO_ENABLE =
# * same, but using enable_matching_units() (<unit>[:=<target>])
SYSTEMD_HACKS__UNITS_TO_ENABLE_MATCHING =
# * disable units by name (<unit>[:=<target>])
SYSTEMD_HACKS__UNITS_TO_DISABLE_NAME =

SYSTEMD_HACKS__UNITS_TO_ENABLE += \
	$(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_SETUP_ENABLE_UNITS))

SYSTEMD_HACKS__UNITS_TO_DISABLE_NAME += \
	$(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_SETUP_DISABLE_UNITS))


# create almost empty unit setup file (gets populated in POST_BUILD hooks)
define SYSTEMD_HACKS_BUILD_CMDS
	mkdir -p -- '$(@D)/recipes'
	{ \
		printf "%s\n"      'set -u' && \
		printf "D=%s\n"    '$(@D)'  && \
		printf "SVC=%s\n"  '$(@D)/files/service'; \
	} > '$(@D)/recipes/unit_setup'
endef

# helper functions for writing to this file
define SYSTEMD_HACKS__ADDSETUP_CMD
	printf "%s\n" "$(strip $(1))" >> '$(@D)/recipes/unit_setup'
endef
define SYSTEMD_HACKS__ADDSETUP
	printf "%s\n" "autodie systemd_hacks_$(strip $(1))" >> '$(@D)/recipes/unit_setup'
endef

# also define how to process the unit file during target install
define SYSTEMD_HACKS_INSTALL_TARGET_CMDS
	# show final config
	cat '$(@D)/recipes/unit_setup'

	$(@D)/systemd-hacks.sh -T '$(TARGET_DIR)' \
		-L $(SYSTEMD_HACKS__SYSTEMD_LIBDIR) -f '$(@D)/recipes/unit_setup'
endef

# move units from /etc/systemd/system/ to SYSTEMD_LIBDIR/system/
#  (and fix up links to moved files)
ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_FIXUP_LIBDIR_ALL),y)
define SYSTEMD_HACKS_DO_FIXUP_LIBDIR_ALL
	$(call SYSTEMD_HACKS__ADDSETUP,move_units_to_libdir)
endef
SYSTEMD_HACKS_POST_BUILD_HOOKS += SYSTEMD_HACKS_DO_FIXUP_LIBDIR_ALL
endif


ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_FIXUP_AVAHI_DAEMON),y)
define SYSTEMD_HACKS_DO_FIXUP_AVAHI_DAEMON
	$(call SYSTEMD_HACKS__ADDSETUP,move_units_to_libdir 'avahi*')
	# move_units_to_libdir() fixes up links, no need to relink again
	$(call SYSTEMD_HACKS__ADDSETUP,install_unit "\$${SVC}/avahi-daemon.service")
endef
SYSTEMD_HACKS_POST_BUILD_HOOKS += SYSTEMD_HACKS_DO_FIXUP_AVAHI_DAEMON
endif


# install unit files (after move_units_to_libdir())
define SYSTEMD_HACKS_DO_INSTALL_UNIT_FILES
	# SYSTEMD_HACKS__UNITS_TO_INSTALL
	{ \
		$(foreach unit,$(call qstrip,$(SYSTEMD_HACKS__UNITS_TO_INSTALL)), \
			printf "%s %s %s\n" \
				"autodie" "systemd_hacks_replace_unit" \
				"\$${SVC}/$(unit)" && \
		) true; \
	} >> '$(@D)/recipes/unit_setup'

	# SYSTEMD_HACKS__UNITS_TO_DISABLE
	{ \
		$(foreach unit,$(call qstrip,$(SYSTEMD_HACKS__UNITS_TO_DISABLE)), \
			printf "%s %s %s\n" \
				"autodie" "systemd_hacks_disable_units_linking_to" \
				"'$(unit)'" && \
		) true; \
	} >> '$(@D)/recipes/unit_setup'

	# SYSTEMD_HACKS__UNITS_TO_ENABLE
	{ \
		$(foreach unit,$(call qstrip,$(SYSTEMD_HACKS__UNITS_TO_ENABLE)), \
			printf "%s %s %s %s\n" \
				"autodie" "systemd_hacks_enable_single_unit" \
				"$(strip $(call SYSTEMD_HACKS__KV_GET_KEY,$(unit)))" \
				"$(strip $(call SYSTEMD_HACKS__KV_GET_VAL,$(unit),multi-user))" && \
		) true; \
	} >> '$(@D)/recipes/unit_setup'

	# SYSTEMD_HACKS__UNITS_TO_ENABLE_MATCHING
	{ \
		$(foreach unit,$(call qstrip,$(SYSTEMD_HACKS__UNITS_TO_ENABLE_MATCHING)), \
			printf "%s %s %s %s\n" \
				"autodie" "systemd_hacks_enable_matching_units" \
				"'$(strip $(call SYSTEMD_HACKS__KV_GET_KEY,$(unit)))'" \
				"$(strip $(call SYSTEMD_HACKS__KV_GET_VAL,$(unit),multi-user))" && \
		) true; \
	} >> '$(@D)/recipes/unit_setup'

	# SYSTEMD_HACKS__UNITS_TO_DISABLE_NAME
	{ \
		$(foreach unit,$(call qstrip,$(SYSTEMD_HACKS__UNITS_TO_DISABLE_NAME)), \
			printf "%s %s %s %s\n" \
				"autodie" "systemd_hacks_disable_unit" \
				"$(strip $(call SYSTEMD_HACKS__KV_GET_KEY,$(unit)))" \
				"$(strip $(call SYSTEMD_HACKS__KV_GET_VAL,$(unit),multi-user))" && \
		) true; \
	} >> '$(@D)/recipes/unit_setup'
endef
SYSTEMD_HACKS_POST_BUILD_HOOKS += SYSTEMD_HACKS_DO_INSTALL_UNIT_FILES



ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVCFILE_MONGOOSE),y)
SYSTEMD_HACKS__UNITS_TO_INSTALL += mongoose.service
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVCFILE_RCLOCAL),y)
SYSTEMD_HACKS__UNITS_TO_INSTALL += rc-local.service

define SYSTEMD_HACKS_DO_SVCFILE_RCLOCAL_INSTALL
	# create /etc/rc.local if necessary
	mkdir -p -- "$(TARGET_DIR)/etc"
	for f in $(TARGET_DIR)/etc/rc.local; do \
		test -h $$f || test -e $$f || touch $$f; \
	done
endef
SYSTEMD_HACKS_POST_INSTALL_TARGET_HOOKS += \
	SYSTEMD_HACKS_DO_SVCFILE_RCLOCAL_INSTALL
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVCFILE_RPCBIND),y)
SYSTEMD_HACKS__UNITS_TO_INSTALL += rpcbind.service
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVCFILE_NFS),y)
SYSTEMD_HACKS__UNITS_TO_INSTALL += nfsd.service
SYSTEMD_HACKS__UNITS_TO_INSTALL += rpc-mountd.service
SYSTEMD_HACKS__UNITS_TO_INSTALL += rpc-statd.service
SYSTEMD_HACKS__UNITS_TO_INSTALL += proc-fs-nfsd.mount
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVCFILE_TVHEADEND),y)
SYSTEMD_HACKS__UNITS_TO_INSTALL += tvheadend.service
SYSTEMD_HACKS__UNITS_TO_INSTALL += tvheadend-resume.service
endif


# --- big setup block starts here ---
ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP),y)

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_SERIALTTY),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE += serial-getty@.service=getty

else
SYSTEMD_HACKS__UNITS_TO_DISABLE += serial-getty@.service
endif


ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_GETTY_TTY1),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE += getty@tty1.service=getty
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_GETTY_AGETTY),y)
define SYSTEMD_HACKS_DO_GEN_GETTY_AGETTY
	{ \
		set -- \
			"-/sbin/agetty" \
			$(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_GETTY_AGETTY_OPTIONS)) \
			"%I" \
			$(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_GETTY_AGETTY_BAUDRATE)) \
			$(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_GETTY_AGETTY_TERMTYPE)) && \
		printf "%s\n%s\n%s\n" "[Service]" "ExecStart=" "ExecStart=$$*"; \
	} > '$(@D)/getty_agetty.conf'
endef
SYSTEMD_HACKS_POST_BUILD_HOOKS += SYSTEMD_HACKS_DO_GEN_GETTY_AGETTY

define SYSTEMD_HACKS_DO_INS_GETTY_AGETTY
	$(INSTALL) -D -m 0644 -- '$(@D)/getty_agetty.conf' \
		'$(TARGET_DIR)/etc/systemd/system/getty@.service.d/03-agetty.conf'
endef
SYSTEMD_HACKS_POST_INSTALL_TARGET_HOOKS += SYSTEMD_HACKS_DO_INS_GETTY_AGETTY
endif
# end BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_GETTY_AGETTY

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_AGETTY_AUTOLOGIN),y)
define SYSTEMD_HACKS_DO_GEN_GETTY_AGETTY_AUTOLOGIN
	{ \
		set -- \
			"-/sbin/agetty" \
			$(or $(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_GETTY_AGETTY_OPTIONS)),--noclear) \
			"--autologin" \
			$(or $(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_AGETTY_AUTOLOGIN_USER),root) \
			"%I" \
			$(or $(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_GETTY_AGETTY_BAUDRATE)),115200) \
			$(or $(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_GETTY_AGETTY_TERMTYPE)),linux) && \
		printf "%s\n%s\n%s\n" "[Service]" "ExecStart=" "ExecStart=$$*"; \
	} > '$(@D)/getty_agetty_autologin.conf'
endef
SYSTEMD_HACKS_POST_BUILD_HOOKS += SYSTEMD_HACKS_DO_GEN_GETTY_AGETTY_AUTOLOGIN

define SYSTEMD_HACKS_DO_INS_GETTY_AGETTY_AUTOLOGIN
	$(INSTALL) -D -m 0644 -- '$(@D)/getty_agetty_autologin.conf' \
		'$(TARGET_DIR)/etc/systemd/system/getty@$(or $(call qstrip,$(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_AGETTY_AUTOLOGIN_TTY)),tty1).service.d/05-autologin.conf'
endef
SYSTEMD_HACKS_POST_INSTALL_TARGET_HOOKS += \
	SYSTEMD_HACKS_DO_INS_GETTY_AGETTY_AUTOLOGIN
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_NETWORKD),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += systemd-networkd
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += systemd-networkd
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_TIMESYNCD),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += systemd-timesyncd
SYSTEMD_HACKS__UNITS_TO_ENABLE  += systemd-timesyncd=sysinit
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += systemd-timesyncd
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_RESOLVED),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += systemd-resolved
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += systemd-resolved
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_REMOTEFS_TARGET),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += remote-fs.target
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += remote-fs.target
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_AVAHI_DAEMON),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += $(addprefix avahi-daemon.,service socket)
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += $(addprefix avahi-daemon.,service socket)
endif


ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_DROPBEAR),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += dropbear
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += dropbear
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_MONGOOSE),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += mongoose
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += mongoose
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_RCLOCAL),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += rc-local
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += rc-local
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_RPCBIND),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += rpcbind
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += rpcbind
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_NFS),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += nfsd.service
SYSTEMD_HACKS__UNITS_TO_ENABLE  += rpc-mountd.service
SYSTEMD_HACKS__UNITS_TO_ENABLE  += rpc-statd.service
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += nfsd.service
SYSTEMD_HACKS__UNITS_TO_DISABLE += rpc-mountd.service
SYSTEMD_HACKS__UNITS_TO_DISABLE += rpc-statd.service
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_TLP),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += tlp
SYSTEMD_HACKS__UNITS_TO_ENABLE  += tlp-sleep=sleep
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += tlp
SYSTEMD_HACKS__UNITS_TO_DISABLE += tlp-sleep
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP_TVHEADEND),y)
SYSTEMD_HACKS__UNITS_TO_ENABLE  += tvheadend
SYSTEMD_HACKS__UNITS_TO_ENABLE  += tvheadend-resume=sleep
else
SYSTEMD_HACKS__UNITS_TO_DISABLE += tvheadend
SYSTEMD_HACKS__UNITS_TO_DISABLE += tvheadend-resume
endif

endif
# end BR2_PACKAGE_SYSTEMD_HACKS_SVC_SETUP

### end system unit setup/activation/installation


$(eval $(generic-package))
