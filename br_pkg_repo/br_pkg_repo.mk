SHELL ?= sh

# Common Functions
# ========================================================================
#
# ---
# http://stackoverflow.com/questions/664601/in-gnu-make-how-do-i-convert-a-variable-to-lower-case
#
#  python code for generating these statements:
#
#  LTU = [ chr(i) for i in range ( 0x61, 0x7b ) ]
#  UTL = [ c.upper() for c in LTU ]
#
#  f = lambda v: '$(1)' if not v else '$(subst {},{},{})'.format (v[0],v[0].swapcase(),f(v[1:]))
#
## >>> f(UTL) => lc
## >>> f(LTU) => uc

lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$(1)))))))))))))))))))))))))))
uc = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$(1)))))))))))))))))))))))))))

f_convert_name = $(subst -,_,$(subst /,_,$(call uc,$(1))))
# ---

f_convert_path_name = $(subst /,__,$(1))

f_lazy_dirname = $(patsubst %/,%,$(dir $(1:/=)))

f_find_packages = $(foreach d,$(wildcard $(1)/*/Config.in),$(notdir $(d:%/Config.in=%)))


# Init
# ========================================================================

_BR_PKG_REPO_PHONY =

__BR_PKG_REPO_MK_FILE := $(realpath $(lastword $(MAKEFILE_LIST)))
__BR_PKG_REPO_MK_DIR  := $(call f_lazy_dirname,$(__BR_PKG_REPO_MK_FILE))
# by assumption: default repo root is the parent dir of the dir containing this Makefile
__BR_PKG_REPO_ROOT    := $(call f_lazy_dirname,$(__BR_PKG_REPO_MK_DIR))

__EMPTY :=
__TAB := $(__EMPTY)$(shell printf "\t")$(__EMPTY)


ifeq ("","$(REPO_NAME)")
$(error REPO_NAME is not set)
endif

ifeq ("","$(REPO_ROOT)")
REPO_ROOT := $(__BR_PKG_REPO_ROOT)
endif

ifeq ("","$(REPO_PKG)")
REPO_PKG := $(REPO_ROOT)/package
endif

PKG_SUBDIR_NAME := $(call f_convert_path_name,$(REPO_NAME))

PKG_NAMES := $(call f_find_packages,$(REPO_PKG))


ifeq ("","$(BR)")
HAVE_BR := 0

else
HAVE_BR := 1

_PKG_DIR_IN_BR  := $(BR)/package/$(PKG_SUBDIR_NAME)

_PKG_INSTALL_TARGETS   := $(addprefix $(BR)/package/,$(PKG_NAMES))
_PKG_UNINSTALL_TARGETS := $(addprefix uninstall-$(BR)/package/,$(PKG_NAMES))
endif


# Targets
# ========================================================================

# Implicit Default Target = list-pkg
# ------------------------------------------------------------------------

_BR_PKG_REPO_PHONY += _br_pkg_repo_default
_br_pkg_repo_default: list-pkg


# Package Repo
# ------------------------------------------------------------------------

_BR_PKG_REPO_PHONY += sanity-check-repo-base
sanity-check-repo-base:
	test -n '$(REPO_ROOT)'
	test -d '$(REPO_ROOT)'
	test -n '$(REPO_PKG)'
	test -d '$(REPO_PKG)'

_BR_PKG_REPO_PHONY += sanity-check-repo
sanity-check-repo: sanity-check-repo-base
	test -f '$(REPO_PKG)/Config.in'


_BR_PKG_REPO_PHONY += list-pkg list-packages
list-pkg list-packages:
	@{ :; $(foreach w,$(PKG_NAMES), printf '%s\n' '$(w)';) } | sort


# Buildroot Source Directory
# ------------------------------------------------------------------------
#
#  - install/uninstall package links
#  - register/unregister Config.in
#
ifeq ($(HAVE_BR),1)
_BR_PKG_REPO_PHONY += sanity-check-br
sanity-check-br: sanity-check-repo
	test -d '$(BR)/package'
	test -d '$(dir $(_PKG_DIR_IN_BR))'
	test -d '$(BR)/toolchain/toolchain-buildroot'   # buildroot path


# creates the $(_PKG_DIR_IN_BR) symlink
$(_PKG_DIR_IN_BR): sanity-check-br
	test ! -h '$(_PKG_DIR_IN_BR)' || rm -- '$(_PKG_DIR_IN_BR)'
	test ! -e '$(_PKG_DIR_IN_BR)'

	ln -s -- '$(REPO_PKG)' '$(_PKG_DIR_IN_BR)'

# installs a symlink to a specific package in $(_PKG_DIR_IN_BR)
$(_PKG_INSTALL_TARGETS): $(BR)/package/%: $(_PKG_DIR_IN_BR)
	mkdir -p -- $(@D)
	rm -f    -- $@
	ln -s    -- $(PKG_SUBDIR_NAME)/$(*) $@

# removes a symlink to a specific package
_BR_PKG_REPO_PHONY += $(_PKG_UNINSTALL_TARGETS)
$(_PKG_UNINSTALL_TARGETS): uninstall-%:
	rm -f -- $*

# adds a "source <>/Config.in" line to $BR/package/Config.in
_BR_PKG_REPO_PHONY += register-config
register-config: $(_PKG_DIR_IN_BR)
	if grep -E -- \
		'^\s*source\s+\"?package/$(PKG_SUBDIR_NAME)/Config.in\"?\s*$$' \
		'$(BR)/package/Config.in'; \
	then \
		echo "Config.in already set up."; \
	else \
		echo "setting up Config.in"; \
		sed \
			-e '$$i\$(__TAB)source "package/$(PKG_SUBDIR_NAME)/Config.in"' \
			-i '$(BR)/package/Config.in'; \
	fi


# undoes "register-config" -- removes "source <>/Config.in"
_BR_PKG_REPO_PHONY += unregister-config
unregister-config:
	sed -r \
		-e '/^\s*source\s+\"?package\/$(PKG_SUBDIR_NAME)\/Config.in\"?\s*$$/d' \
		-i '$(BR)/package/Config.in'


# creates the package subdir link, links packages and registers Config.in
_BR_PKG_REPO_PHONY += install
install: $(_PKG_DIR_IN_BR) $(_PKG_INSTALL_TARGETS) register-config


# removes package links/subdir and unregisters Config.in
_BR_PKG_REPO_PHONY += uninstall
uninstall: $(_PKG_UNINSTALL_TARGETS) unregister-config
	rm -f -- $(_PKG_DIR_IN_BR)

else
BR_TARGETS =
BR_TARGETS += sanity-check-br
#BR_TARGETS += $(_PKG_DIR_IN_BR)
#BR_TARGETS += $(_PKG_INSTALL_TARGETS)
#BR_TARGETS += $(_PKG_UNINSTALL_TARGETS)
BR_TARGETS += register-config
BR_TARGETS += unregister-config
BR_TARGETS += install
BR_TARGETS += uninstall

_BR_PKG_REPO_PHONY += $(BR_TARGETS)
$(BR_TARGETS):
	$(error buildroot src dir BR not specified!)

endif

# Legacy/Compat Targets
# ------------------------------------------------------------------------

# sanity-check: either sanity-check-repo or sanity-check-br
_BR_PKG_REPO_PHONY += sanity-check
ifeq ($(HAVE_BR),1)
sanity-check: sanity-check-br
else
sanity-check: sanity-check-repo
endif


# Misc Targets
# ------------------------------------------------------------------------
FORCE:

.PHONY: $(_BR_PKG_REPO_PHONY)
