# Qt CI

Scripts and CI for debloated Qt, containing Qt Base and Declarative modules.

- [**Releases**](https://github.com/crueter-ci/Qt/releases)
- No UNIX (FreeBSD, OpenBSD, illumos) builds are provided.
- macOS builds are ARM only.

## Building and Usage

See the [spec](https://github.com/crueter-ci/spec). This is slightly different than the others, CPMUtil will have support added for it eventually.

## Dependencies

All: CMake, Ninja, pkg-config, curl, zstd, unzip, working compiler

- Linux: X11 and MESA libraries
- ccache is recommended for all platforms.

See [`deps`](./deps) for specific package installation commands.