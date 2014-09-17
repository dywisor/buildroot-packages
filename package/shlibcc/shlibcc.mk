################################################################################
#
# shlibcc
#
################################################################################

SHLIBCC_VERSION       = 0.0.13
SHLIBCC__GITREF       = 5ec3e23652b0eb2471c4f931b6e4335796738344
SHLIBCC_SITE          = $(call github,dywisor,shlibcc,$(SHLIBCC__GITREF))
SHLIBCC_LICENSE       = GPLv2+
SHLIBCC_LICENSE_FILES =
SHLIBCC_SETUP_TYPE    = distutils

HOST_SHLIBCC_NEEDS_HOST_PYTHON = python3

SHLIBCC_PROG  = $(HOST_DIR)/usr/bin/python3 $(HOST_DIR)/usr/bin/shlibcc
SHLIBCC_FLAGS = --stable-sort $(call qstrip,$(BR2_TARGET_SHLIBCC_FLAGS))
SHLIBCC       = $(SHLIBCC_PROG) $(SHLIBCC_FLAGS)

$(eval $(python-package))
$(eval $(host-python-package))
