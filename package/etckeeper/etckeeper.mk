################################################################################
#
# etckeeper
#
################################################################################

ETCKEEPER_VERSION       = 1.18.15
ETCKEEPER_SOURCE        = etckeeper-$(ETCKEEPER_VERSION).tar.gz
ETCKEEPER_SITE          = https://git.joeyh.name/index.cgi/etckeeper.git/snapshot
ETCKEEPER_LICENSE       = GPL-2
ETCKEEPER_LICENSE_FILES = COPYRIGHT

ETCKEEPER_CONFDIR = /usr/share/etckeeper

# The original makefile 'install' target installs a lot of files,
# most of which are unnecessary for Buildroot.
#
define ETCKEEPER_INSTALL_TARGET_CMDS
	$(INSTALL) -d -- $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 0755 -- $(@D)/etckeeper $(TARGET_DIR)/usr/bin/etckeeper

	$(INSTALL) -d -- $(TARGET_DIR)$(ETCKEEPER_CONFDIR)
	cp -R -- $(@D)/*.d $(TARGET_DIR)$(ETCKEEPER_CONFDIR)/
	$(INSTALL) -m 0755 -- $(@D)/daily $(TARGET_DIR)$(ETCKEEPER_CONFDIR)/daily
	$(INSTALL) -m 0644 -- $(ETCKEEPER_PKGDIR)/etckeeper.conf $(TARGET_DIR)$(ETCKEEPER_CONFDIR)/etckeeper.conf

	$(INSTALL) -d -- $(TARGET_DIR)/etc/profile.d
	rm -f -- $(TARGET_DIR)/etc/profile.d/etckeeper.sh
	printf 'export ETCKEEPER_CONF_DIR="%s"\n' '$(ETCKEEPER_CONFDIR)' \
		> $(TARGET_DIR)/etc/profile.d/etckeeper.sh
	chmod -- 0644 $(TARGET_DIR)/etc/profile.d/etckeeper.sh
endef

$(eval $(generic-package))
