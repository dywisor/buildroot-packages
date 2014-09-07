S               := $(abspath $(CURDIR))
PKG_SUBDIR_NAME := dywi__buildroot-packages

ifeq ($(BR),)
$(error buildroot src dir BR not specified!)
endif

_PKG_DIR  := $(BR)/package/$(PKG_SUBDIR_NAME)

PKG_NAMES := $(foreach d,$(wildcard $(S)/package/*/.),$(notdir $(d:%/.=%)))

_PKG_INSTALL_TARGETS   := $(addprefix $(BR)/package/,$(PKG_NAMES))
_PKG_UNINSTALL_TARGETS := $(addprefix uninstall-$(BR)/package/,$(PKG_NAMES))

PHONY += default
default: install

PHONY += sanity-check
sanity-check:
	test -d '$(BR)/package'
	test -d '$(dir $(_PKG_DIR))'
	test -n '$(S)'
	test -d '$(S)/package'
	test -f '$(S)/package/Config.in'


# creates the $(_PKG_DIR) symlink
$(_PKG_DIR): sanity-check
	test ! -h '$(_PKG_DIR)' || rm -- '$(_PKG_DIR)'
	test ! -e '$(_PKG_DIR)'

	ln -s -- '$(S)/package' '$(_PKG_DIR)'

# installs a symlink to a specific package in $(_PKG_DIR)
$(_PKG_INSTALL_TARGETS): $(BR)/package/%: $(_PKG_DIR)
	mkdir -p -- $(@D)
	rm -f    -- $@
	ln -s    -- $(PKG_SUBDIR_NAME)/$(*) $@

# removes a symlink to a specific package
PHONY += $(_PKG_UNINSTALL_TARGETS)
$(_PKG_UNINSTALL_TARGETS): uninstall-%:
	rm -f -- $*

# adds a "source <>/Config.in" line to $BR/package/Config.in
PHONY += register-config
register-config: $(_PKG_DIR)
	if grep -E -- \
		'^\s*source\s+\"?package/$(PKG_SUBDIR_NAME)/Config.in\"?\s*$$' \
		'$(BR)/package/Config.in'; \
	then \
		echo "Config.in already set up."; \
	else \
		echo "setting up Config.in"; \
		sed \
			-e '$$i\\tsource "package/$(PKG_SUBDIR_NAME)/Config.in"' \
			-i '$(BR)/package/Config.in'; \
	fi


# undoes "register-config" -- removes "source <>/Config.in"
PHONY += unregister-config
unregister-config:
	sed -r \
		-e '/^\s*source\s+\"?package\/$(PKG_SUBDIR_NAME)\/Config.in\"?\s*$$/d' \
		-i '$(BR)/package/Config.in'


# creates the package subdir link, links packages and registers Config.in
PHONY += install
install: $(_PKG_DIR) $(_PKG_INSTALL_TARGETS) register-config


# removes package links/subdir and unregisters Config.in
PHONY += uninstall
uninstall: $(_PKG_UNINSTALL_TARGETS) unregister-config
	rm -f -- $(_PKG_DIR)


.PHONY: $(PHONY)
