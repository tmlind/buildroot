################################################################################
#
# kexecboot
#
################################################################################

KEXECBOOT_VERSION = 7409a1e0aaea61af87c4eca0149cec18a9f58ab6
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
