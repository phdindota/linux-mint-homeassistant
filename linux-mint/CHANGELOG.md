# Changelog

## 1.1.0

- Switched from XFCE4 to Linux Mint Cinnamon desktop environment
- Switched to Debian Bookworm base image (required for Cinnamon)
- Fixed Home Assistant ingress/sidebar "failed to connect to server" error
- noVNC now auto-connects with relative WebSocket path for proper ingress support
- Added dbus-daemon startup for Cinnamon session
- Improved desktop session launch with proper dbus-launch
- websockify now listens on 0.0.0.0:6080 for ingress compatibility

## 1.0.0

- Initial release
- Linux Mint-style desktop environment via noVNC
- Configurable resolution, username, and VNC password
- Home Assistant ingress support
- Multi-architecture support (amd64, aarch64)
