################################################################################
#
# perl-netaddr-ip
#
################################################################################

PERL_SOCKET6_VERSION = 0.29
PERL_SOCKET6_SOURCE = Socket6-$(PERL_SOCKET6_VERSION).tar.gz
PERL_SOCKET6_SITE = $(BR2_CPAN_MIRROR)/authors/id/U/UM/UMEMOTO
PERL_SOCKET6_LICENSE = BSD
PERL_SOCKET6_LICENSE_FILES =
PERL_SOCKET6_DISTNAME = Socket6

ifeq ($(BR2_STATIC_LIBS),y)
PERL_SOCKET6_CONF_OPTS = -noxs
endif

$(eval $(perl-package))
