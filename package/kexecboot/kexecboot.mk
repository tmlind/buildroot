################################################################################
#
# kexecboot
#
################################################################################

KEXECBOOT_VERSION = d5ffd81bf6a1a2087cdc6c606cae98099229131c
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
