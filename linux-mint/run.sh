#!/usr/bin/with-contenv bashio

# ---------------------------------------------------------------------------
# Read configuration
# ---------------------------------------------------------------------------
RESOLUTION=$(bashio::config 'resolution')
VNC_PASSWORD=$(bashio::config 'vnc_password')
USERNAME=$(bashio::config 'username')

# Defaults
RESOLUTION="${RESOLUTION:-1920x1080}"
USERNAME="${USERNAME:-user}"

# Parse resolution into width and height
WIDTH=$(echo "${RESOLUTION}" | cut -dx -f1)
HEIGHT=$(echo "${RESOLUTION}" | cut -dx -f2)

bashio::log.info "Starting Linux Mint Cinnamon desktop environment"
bashio::log.info "Resolution: ${WIDTH}x${HEIGHT}"
bashio::log.info "Username: ${USERNAME}"

# ---------------------------------------------------------------------------
# Create the user account if it doesn't exist
# ---------------------------------------------------------------------------
if ! id "${USERNAME}" &>/dev/null; then
    bashio::log.info "Creating user account: ${USERNAME}"
    useradd -m -s /bin/bash "${USERNAME}"
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

HOME_DIR="/home/${USERNAME}"
export HOME="${HOME_DIR}"
export USER="${USERNAME}"

# ---------------------------------------------------------------------------
# Start dbus system daemon
# ---------------------------------------------------------------------------
if [ ! -d /var/run/dbus ]; then
    mkdir -p /var/run/dbus
fi
dbus-daemon --system --fork 2>/dev/null || true

# ---------------------------------------------------------------------------
# Start Xvfb (virtual framebuffer)
# ---------------------------------------------------------------------------
bashio::log.info "Starting Xvfb on :1 with resolution ${WIDTH}x${HEIGHT}"
Xvfb :1 -screen 0 "${WIDTH}x${HEIGHT}x24" -ac +extension GLX +render -noreset &
XVFB_PID=$!
export DISPLAY=:1

# Wait for Xvfb to be ready
sleep 2

# ---------------------------------------------------------------------------
# Start Cinnamon desktop session
# ---------------------------------------------------------------------------
bashio::log.info "Starting Cinnamon desktop session"
su -c "DISPLAY=:1 DBUS_SESSION_BUS_ADDRESS= dbus-launch cinnamon-session &" "${USERNAME}"
sleep 5

# ---------------------------------------------------------------------------
# Start x11vnc
# ---------------------------------------------------------------------------
bashio::log.info "Starting x11vnc on port 5900"
if bashio::config.has_value 'vnc_password' && [ -n "${VNC_PASSWORD}" ]; then
    bashio::log.info "VNC password protection enabled"
    x11vnc -display :1 -forever -shared -rfbport 5900 -passwd "${VNC_PASSWORD}" -noxdamage &
else
    bashio::log.info "VNC running without password"
    x11vnc -display :1 -forever -shared -rfbport 5900 -nopw -noxdamage &
fi
VNC_PID=$!

sleep 1

# ---------------------------------------------------------------------------
# Start websockify / noVNC on port 6080
# ---------------------------------------------------------------------------
NOVNC_PATH="/usr/share/novnc"
if [ ! -d "${NOVNC_PATH}" ]; then
    NOVNC_PATH="/usr/share/webapps/novnc"
fi

# Create a custom index.html that auto-connects with a relative WebSocket path.
# Using a relative path for websockify ensures the connection works whether
# accessed directly (port 6080) or via Home Assistant ingress (which rewrites
# the URL prefix).
cat > "${NOVNC_PATH}/index.html" << 'INDEXEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Linux Mint Desktop</title>
    <script>
        // Redirect to vnc.html with autoconnect and relative websocket path.
        // Using a relative path for websockify ensures it works through HA ingress.
        var loc = window.location;
        var basePath = loc.pathname.replace(/\/+$/, '');
        var wsPath = basePath + '/websockify';
        // Remove leading slash for the path parameter
        wsPath = wsPath.replace(/^\/+/, '');
        var target = 'vnc.html?autoconnect=true&resize=remote&reconnect=true&reconnect_delay=1000&path=' + encodeURIComponent(wsPath);
        window.location.href = target;
    </script>
</head>
<body>
    <p>Connecting to Linux Mint desktop...</p>
</body>
</html>
INDEXEOF

bashio::log.info "Starting noVNC/websockify on port 6080 (proxying VNC on 5900)"
websockify --web "${NOVNC_PATH}" 0.0.0.0:6080 localhost:5900 &
WEBSOCKIFY_PID=$!

bashio::log.info "Linux Mint Cinnamon desktop is ready!"
bashio::log.info "Access via Home Assistant sidebar or http://<your-ha-ip>:6080"

# ---------------------------------------------------------------------------
# Graceful shutdown
# ---------------------------------------------------------------------------
trap 'bashio::log.info "Shutting down..."; kill ${WEBSOCKIFY_PID} ${VNC_PID} ${XVFB_PID} 2>/dev/null; exit 0' SIGTERM SIGINT

# Wait for any background process to exit
wait ${WEBSOCKIFY_PID}
