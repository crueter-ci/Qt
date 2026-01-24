#!/bin/sh -e

pacman -Syu --needed --noconfirm \
	base-devel cmake ninja git unzip python \
	vulkan-headers vulkan-icd-loader mesa libglvnd glu \
	pkgconf libxrandr libxkbcommon-x11 zstd xcb-util-cursor \
	gtk3 dbus alsa-lib libpulse fontconfig libpng libjpeg-turbo \
	zlib xcb-util tar xz ccache
