################################################################################
#
# kexecboot
#
################################################################################

KEXECBOOT_VERSION = b3e31b473b6c4012ecab171aa7cfad521f56d8d8
KEXECBOOT_SITE = $(call github,kexecboot,kexecboot,$(KEXECBOOT_VERSION))
KEXECBOOT_LICENSE = GPL-2.0
KEXECBOOT_LICENSE_FILES = License
KEXECBOOT_DEPENDENCIES = kexec
KEXECBOOT_AUTORECONF = YES

KEXECBOOT_CONF_OPTS = --enable-textui \
	--enable-fbui=yes \
	--enable-fbui-update \
	--enable-numkeys \
	--enable-timeout=4 \
	--enable-debug

ifeq ($(BR2_STATIC_LIBS),y)
KEXECBOOT_CONF_OPTS += --enable-static-linking
endif

$(eval $(autotools-package))
