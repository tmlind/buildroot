################################################################################
#
# kexec-droid4
#
################################################################################

KEXEC_DROID4_VERSION = 0dbef4c4d3d1c3e2cb023043d2e7330c09dcf4df
KEXEC_DROID4_SITE = $(call github,Hashcode,kexec-tools,$(KEXEC_DROID4_VERSION))
KEXEC_DROID4_LICENSE = GPL-2.0
KEXEC_DROID4_LICENSE_FILES = COPYING
KEXEC_DROID4_AUTORECONF = YES

# Makefile expects $STRIP -o to work, so needed for !BR2_STRIP_strip
KEXEC_DROID4_MAKE_OPTS = CFLAGS="$(KEXEC_DROID4_CFLAGS)" \
	STRIP="$(TARGET_CROSS)strip"

ifeq ($(BR2_PACKAGE_KEXEC_ZLIB),y)
KEXEC_DROID4_CONF_OPTS += --with-zlib
KEXEC_DROID4_DEPENDENCIES = zlib
else
KEXEC_DROID4_CONF_OPTS += --without-zlib
endif

ifeq ($(BR2_PACKAGE_XZ),y)
KEXEC_DROID4_CONF_OPTS += --with-lzma
KEXEC_DROID4_DEPENDENCIES += xz
else
KEXEC_DROID4_CONF_OPTS += --without-lzma
endif

define KEXEC_REMOVE_LIB_TOOLS
	rm -rf $(TARGET_DIR)/usr/lib/kexec-tools
endef

KEXEC_POST_INSTALL_TARGET_HOOKS += KEXEC_REMOVE_LIB_TOOLS

define KEXEC_DROID4_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/sbin/kexec \
		$(TARGET_DIR)/usr/sbin/kexec-droid4
endef

$(eval $(autotools-package))
