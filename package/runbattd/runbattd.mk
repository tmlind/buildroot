################################################################################
#
# runbattd
#
################################################################################

RUNBATTD_VERSION = 2968641f7185b0a2bbe87444142730cd75dbd5c6
RUNBATTD_SITE = $(call github,tmlind,runbattd,$(RUNBATTD_VERSION))
RUNBATTD_LICENSE = GPL-2.0
RUNBATTD_LICENSE_FILES = README.md

define RUNBATTD_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		CC="$(TARGET_CC)" COPT_FLAGS="$(TARGET_CFLAGS)"
endef

define RUNBATTD_INSTALL_TARGET_CMDS
	$(INSTALL) -m 755 -D $(@D)/runbattd $(TARGET_DIR)/usr/bin/runbattd
endef

$(eval $(generic-package))
