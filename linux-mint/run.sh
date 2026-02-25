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

if ! kill -0 ${XVFB_PID} 2>/dev/null; then
    bashio::log.error "Xvfb failed to start!"
    exit 1
fi

# ---------------------------------------------------------------------------
# Start Cinnamon desktop session
# ---------------------------------------------------------------------------
bashio::log.info "Starting Cinnamon desktop session"
su -c "DISPLAY=:1 DBUS_SESSION_BUS_ADDRESS= dbus-launch cinnamon-session &" "${USERNAME}"
sleep 8

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

sleep 2

if ! kill -0 ${VNC_PID} 2>/dev/null; then
    bashio::log.error "x11vnc failed to start! Retrying..."
    x11vnc -display :1 -forever -shared -rfbport 5900 -nopw -noxdamage &
    VNC_PID=$!
    sleep 2
fi

# ---------------------------------------------------------------------------
# Find noVNC installation path
# ---------------------------------------------------------------------------
NOVNC_PATH=""
for dir in /usr/share/novnc /usr/share/webapps/novnc; do
    if [ -d "$dir" ]; then
        NOVNC_PATH="$dir"
        break
    fi
done

if [ -z "${NOVNC_PATH}" ]; then
    bashio::log.error "noVNC installation not found!"
    exit 1
fi

bashio::log.info "noVNC found at: ${NOVNC_PATH}"

# ---------------------------------------------------------------------------
# Create index.html that auto-connects to VNC with correct websocket path
# ---------------------------------------------------------------------------
# For BOTH direct access (port 6080) and HA ingress, websockify handles
# the /websockify path. HA ingress strips its prefix before forwarding,
# so the container always sees the request at root. Therefore the websocket
# path is always just "websockify" (relative, no leading slash).
#
# We use vnc_lite.html if available (simpler, self-contained) or vnc.html.
# ---------------------------------------------------------------------------

NOVNC_HTML="vnc.html"
if [ -f "${NOVNC_PATH}/vnc_lite.html" ]; then
    NOVNC_HTML="vnc_lite.html"
fi

cat > "${NOVNC_PATH}/index.html" << 'INDEXEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Linux Mint Desktop</title>
</head>
<body>
    <script>
        // Build the noVNC URL with auto-connect parameters.
        // The websocket path is simply "websockify" — this works for both:
        //   - Direct access on port 6080
        //   - Home Assistant ingress (which strips its prefix before forwarding)
        var host = window.location.hostname;
        var port = window.location.port;

        // Determine which noVNC HTML file to use
        var vncPage = 'NOVNC_HTML_PLACEHOLDER';

        // Build URL - use the same origin, just change the page
        var params = new URLSearchParams();
        params.set('autoconnect', 'true');
        params.set('resize', 'remote');
        params.set('reconnect', 'true');
        params.set('reconnect_delay', '1000');
        params.set('path', 'websockify');
        params.set('host', host);
        if (port) params.set('port', port);

        window.location.replace(vncPage + '?' + params.toString());
    </script>
    <noscript>
        <p>JavaScript is required. Please enable JavaScript and reload.</p>
    </noscript>
</body>
</html>
INDEXEOF

# Replace the placeholder with the actual noVNC HTML filename
sed -i "s|NOVNC_HTML_PLACEHOLDER|${NOVNC_HTML}|g" "${NOVNC_PATH}/index.html"

bashio::log.info "Using noVNC page: ${NOVNC_HTML}"
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
