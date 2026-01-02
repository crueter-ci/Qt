#!/bin/sh -e

pkg_add -u

# OpenBSD compiler situation is sad
pkg_add gawk \
	gsed \
	bash \
	vulkan-headers \
	unzip-6.0p18-iconv \
	curl \
	cmake \
	ninja \
	xz \
	zstd \
	gtar-1.35p1 \
	llvm-21.1.2p0

export CC=clang-21
export CXX=clang++-21