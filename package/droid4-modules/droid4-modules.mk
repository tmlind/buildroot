################################################################################
#
# droid4-modules
#
################################################################################

DROID4_MODULES_VERSION = 0.4
DROID4_MODULES_SOURCE = droid4-mainline-kexec-$(DROID4_MODULES_VERSION).tar.xz
DROID4_MODULES_SITE = http://muru.com/linux/d4
DROID4_MODULES_LICENSE = GPL-2.0
DROID4_MODULES_LICENSE_FILES = License

define DROID4_MODULES_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/*.ko \
		-t $(TARGET_DIR)/lib/modules/3.0.8-g448a95f/kernel
endef

$(eval $(generic-package))
