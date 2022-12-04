################################################################################
#
# kexecboot
#
################################################################################

KEXECBOOT_VERSION = 6479d816fa0f61d6aadf78a509836f401b352a14
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
