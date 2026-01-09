#!/usr/bin/sh

# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

_ver=1.4.335.0
_root=C:/VulkanSDK/$_ver

_exe="vulkansdk-windows-X64-$_ver.exe"
_url="https://sdk.lunarg.com/sdk/download/$_ver/windows/$_exe"
_root_unix=$(cygpath -u "$_root")

# Check if Vulkan SDK is already installed
if [ -d "$_root_unix" ]; then
    echo "-- Vulkan SDK already installed at $_root"
else
    echo "-- Downloading Vulkan SDK $_ver from $_url"
    [ ! -f "./$_exe" ] && curl -L -o "./$_exe" "$_url"
    chmod +x "./$_exe"

    echo "-- Installing Vulkan SDK $_ver..."
    if net session > /dev/null 2>&1; then
        ./"$_exe" --root "$_root" --accept-licenses --default-answer --confirm-command install
    else
        echo "-- ! This script must be run with administrator privileges!"
        exit 1
    fi

    echo "-- Finished installing Vulkan SDK $_ver"
fi

export VULKAN_SDK="$_root"
export PATH="$_root/bin:$PATH"