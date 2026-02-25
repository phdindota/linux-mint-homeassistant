# Changelog

## 1.2.0

- Fixed noVNC hanging at "Connecting to Linux Mint desktop..." on both direct port and HA ingress
- Replaced broken JavaScript redirect with proper auto-connect approach
- WebSocket path is now simply "websockify" (works for both direct and ingress access)
- Added python3-websockify package for proper Debian websockify support
- Added process health checks for Xvfb and x11vnc
- Increased Cinnamon startup wait time for reliability
- Added x11vnc auto-retry on failure

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
