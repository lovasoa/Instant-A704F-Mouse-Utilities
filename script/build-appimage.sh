#!/bin/sh
set -eu
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=${1:-"$source_dir/build/appimage"}
mkdir -p "$build_dir"
build_dir=$(CDPATH= cd -- "$build_dir" && pwd)
tool_dir="$source_dir/build/tools"
mkdir -p "$tool_dir"

case $(uname -m) in
    x86_64) ;;
    *) echo "This script currently packages x86_64 AppImages only." >&2; exit 1 ;;
esac

fetch_tool() {
    name=$1
    url=$2
    checksum=$3
    if [ ! -f "$tool_dir/$name" ]; then
        curl --fail --location "$url" --output "$tool_dir/$name"
    fi
    printf '%s  %s\n' "$checksum" "$tool_dir/$name" | sha256sum --check -
    chmod +x "$tool_dir/$name"
}

fetch_tool linuxdeploy-x86_64.AppImage \
    https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20251107-1/linuxdeploy-x86_64.AppImage \
    c20cd71e3a4e3b80c3483cef793cda3f4e990aca14014d23c544ca3ce1270b4d
fetch_tool linuxdeploy-plugin-qt-x86_64.AppImage \
    https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/1-alpha-20250213-1/linuxdeploy-plugin-qt-x86_64.AppImage \
    15106be885c1c48a021198e7e1e9a48ce9d02a86dd0a1848f00bdbf3c1c92724
ln -sf linuxdeploy-plugin-qt-x86_64.AppImage "$tool_dir/linuxdeploy-plugin-qt"

cmake -S "$source_dir" -B "$build_dir" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "$build_dir" --parallel
app_dir="$build_dir/AppDir"
cmake -E rm -rf "$app_dir"
DESTDIR="$app_dir" cmake --install "$build_dir" --component Runtime

export PATH="$tool_dir:$PATH"
export APPIMAGE_EXTRACT_AND_RUN=1
# The bundled binutils may not understand newer host ELF relocations.
export NO_STRIP=1
export QMAKE=${QMAKE:-$(command -v qmake6)}
export VERSION=$(sed -n 's/^set(CPACK_PACKAGE_VERSION "\([^"]*\)").*/\1/p' "$build_dir/CPackConfig.cmake")
cd "$build_dir"
"$tool_dir/linuxdeploy-x86_64.AppImage" --appdir "$app_dir" \
    --desktop-file "$app_dir/usr/share/applications/a704f-mouse.desktop" \
    --icon-file "$source_dir/img/tray.png" --icon-filename a704f-mouse \
    --plugin qt --output appimage
