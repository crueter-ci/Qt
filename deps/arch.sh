#!/bin/sh -e

pacman -Syu --needed --noconfirm \
	base-devel cmake ninja git unzip python \
	vulkan-headers vulkan-icd-loader mesa libglvnd glu \
	pkgconf libxrandr libxkbcommon-x11 zstd \
	gtk3 dbus alsa-lib libpulse fontconfig libpng libjpeg-turbo \
	libdrm libva xcb-util-cursor \
	libxcb xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm \
	zlib tar xz
