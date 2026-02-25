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
# Create index.html that auto-connects — NO REDIRECT approach
# ---------------------------------------------------------------------------
# The key problem with redirects is that they lose the ingress path context.
# Instead, we create a self-contained page that loads noVNC's RFB module
# and connects directly. The WebSocket URL is computed from window.location
# which preserves the full ingress path.

cat > "${NOVNC_PATH}/index.html" << 'INDEXEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Linux Mint Desktop</title>
    <style>
        html, body {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            background-color: #1a1a2e;
        }
        #screen {
            width: 100%;
            height: 100%;
        }
        #status {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: #87b37a;
            font-family: sans-serif;
            font-size: 1.2em;
            z-index: 1000;
        }
    </style>
</head>
<body>
    <div id="status">Connecting to Linux Mint desktop...</div>
    <div id="screen"></div>

    <script type="module">
        // Import noVNC's RFB class
        import RFB from './core/rfb.js';

        // Compute WebSocket URL from current location
        // This preserves the full path including HA ingress prefix
        var loc = window.location;
        var wsScheme = loc.protocol === 'https:' ? 'wss' : 'ws';

        // Get the base path, strip trailing filename (like index.html) and slashes
        var basePath = loc.pathname;
        // Remove trailing filename if present
        basePath = basePath.replace(/\/[^\/]*\.[^\/]*$/, '/');
        // Ensure it ends with /
        if (!basePath.endsWith('/')) basePath += '/';

        var wsUrl = wsScheme + '://' + loc.host + basePath + 'websockify';

        var statusEl = document.getElementById('status');
        statusEl.textContent = 'Connecting to Linux Mint desktop...';

        try {
            var rfb = new RFB(
                document.getElementById('screen'),
                wsUrl,
                {}
            );

            rfb.scaleViewport = true;
            rfb.resizeSession = true;

            rfb.addEventListener('connect', function() {
                statusEl.style.display = 'none';
                console.log('Connected to Linux Mint desktop');
            });

            rfb.addEventListener('disconnect', function(e) {
                statusEl.style.display = 'block';
                if (e.detail.clean) {
                    statusEl.textContent = 'Disconnected from desktop.';
                } else {
                    statusEl.textContent = 'Connection lost. Reconnecting in 3s...';
                    setTimeout(function() { location.reload(); }, 3000);
                }
            });

            rfb.addEventListener('credentialsrequired', function() {
                statusEl.textContent = 'VNC password required...';
                var pw = prompt('Enter VNC password:');
                if (pw) rfb.sendCredentials({ password: pw });
            });
        } catch(err) {
            statusEl.textContent = 'Error: ' + err.message;
            console.error('noVNC error:', err);
        }
    </script>
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
