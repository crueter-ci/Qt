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
	llvm-20.1.8p1 \
	sccache

export CC=/usr/local/bin/clang-20
export CXX=/usr/local/bin/clang++-20