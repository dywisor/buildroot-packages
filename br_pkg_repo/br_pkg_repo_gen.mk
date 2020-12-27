# Package Repo: (re)init package directories
# ------------------------------------------------------------------------

_BR_PKG_REPO_GEN_PHONY =

_BR_PKG_REPO_GEN_PHONY += repo-init-pkg
ifeq ("","$(PKGV)")
repo-init-pkg:
	$(error PKGV= is empty)
else

_BR_INIT_REPO_DIRS      := $(addprefix $(REPO_PKG)/,$(PKGV))
_BR_INIT_REPO_CONFIG_IN := $(addsuffix /Config.in,$(_BR_INIT_REPO_DIRS))
_BR_INIT_REPO_PKG_MK    := $(foreach w,$(PKGV),$(REPO_PKG)/$(w)/$(w).mk)

repo-init-pkg: $(_BR_INIT_REPO_CONFIG_IN) $(_BR_INIT_REPO_PKG_MK)

$(REPO_PKG):
	mkdir -p -- $@

$(_BR_INIT_REPO_DIRS): | $(REPO_PKG)
	mkdir -p -- $@

f_pname = $(notdir $(call f_lazy_dirname,$(1)))
f_pname_mk = $(call f_convert_name,$(call f_pname,$(1)))

$(_BR_INIT_REPO_CONFIG_IN): $(REPO_PKG)/%/Config.in: | $(REPO_PKG)/%
	{ set -e; \
		if [ -e '$(@)' ] || [ -h '$(@)' ]; then \
			printf 'Skipping: %s\n' '$(@)' 1>&2; \
		else \
			{ \
				mk_name='$(call f_pname_mk,$@)'; \
				bpkg_name="BR2_PACKAGE_$${mk_name:?}"; \
				\
				printf 'menuconfig %s\n' "$${bpkg_name}"; \
				printf '\tbool "%s"\n' '$(call f_pname,$@)'; \
				printf '\n'; \
				printf '\thelp\n'; \
				printf '\t\t%s\n' 'DESCRIPTION'; \
				printf '\n'; \
				printf '\t\t%s\n' 'URL'; \
				printf '\n'; \
				printf 'if %s\n\n' "$${bpkg_name}"; \
				printf 'config %s_...\n' "$${bpkg_name}"; \
				printf '\n'; \
				printf 'endif %s\n' "# $${bpkg_name}"; \
			} > '$(@).make_tmp'; \
			\
			mv -f -- '$(@).make_tmp' '$(@)'; \
		fi; \
	}

# cannot depend on dir here
$(_BR_INIT_REPO_PKG_MK): $(REPO_PKG)/%:
	{ set -e; \
		if [ -e '$(@)' ] || [ -h '$(@)' ]; then \
			printf 'Skipping: %s\n' '$(@)' 1>&2; \
		else \
			mkdir -p -- $(@D) || exit; \
			{ \
				mk_name='$(call f_pname_mk,$@)'; \
				: "$${mk_name:?}"; \
				\
				printf '%s\n' '################################################################################'; \
				printf '%s\n' '#'; \
				printf '%s\n' '# $(call f_pname,$@)'; \
				printf '%s\n' '#'; \
				printf '%s\n' '################################################################################'; \
				printf '\n'; \
				printf '%s_VERSION       =\n' "$${mk_name}"; \
				printf '%s_SOURCE        =\n' "$${mk_name}"; \
				printf '%s_SITE          =\n' "$${mk_name}"; \
				printf '%s_LICENSE       =\n' "$${mk_name}"; \
				printf '%s_LICENSE_FILES =\n' "$${mk_name}"; \
				printf '\n'; \
				printf 'define %s_BUILD_CMDS\n' "$${mk_name}"; \
				printf '\t%s\n' 'false'; \
				printf 'endef\n'; \
				printf '\n'; \
				printf 'define %s_INSTALL_TARGET_CMDS\n' "$${mk_name}"; \
				printf '\t%s\n' 'false'; \
				printf 'endef\n'; \
				printf '\n'; \
				printf '%s\n' '$$(eval $$(generic-package))'; \
			} > '$(@).make_tmp'; \
			\
			mv -f -- '$(@).make_tmp' '$(@)'; \
		fi; \
	}

endif


# Package Repo: update repo Config.in
# ------------------------------------------------------------------------

_BR_PKG_REPO_GEN_PHONY += repo-update-config
repo-update-config: $(REPO_PKG)/Config.in

# should not use f_find_packages here
$(REPO_PKG)/Config.in: FORCE sanity-check-repo-base
	mkdir -p -- $(@D)

	{ set -efu; \
		if [ -h '$(@)' ]; then \
			want_gen=0; \
		elif [ -e '$(@)' ]; then \
			if grep -- '^# br_pkg_repo autogen$$' '$(@)' 1>/dev/null; then \
				want_gen=1; \
			else \
				want_gen=0; \
			fi; \
		else \
			printf '%s\n' '# br_pkg_repo autogen' > '$(@)'; \
			want_gen=1; \
		fi; \
		\
		if [ $${want_gen} -eq 1 ]; then \
			{ \
				printf '%s\n' '# br_pkg_repo autogen'; \
				printf 'menu "%s %s"\n' '$(REPO_NAME)' '[external repo]'; \
				find $(REPO_PKG) -mindepth 2 -type f -name '*.mk' -print0 \
					| xargs -0 -r -n 1 -I '{F}' basename '{F}' .mk \
					| sort \
					| xargs -r printf '\tsource "package/%s/Config.in"\n' \
				; \
				printf 'endmenu\n'; \
			} > '$(@).make_tmp'; \
			\
			mv -f -- '$(@).make_tmp' '$(@)'; \
			\
		else \
			printf 'Skipping: %s\n' '$(@)' 1>&2; \
		fi; \
	}

# fini
.PHONY: $(_BR_PKG_REPO_GEN_PHONY)
