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

bashio::log.info "Starting Linux Mint desktop environment"
bashio::log.info "Resolution: ${WIDTH}x${HEIGHT}"
bashio::log.info "Username: ${USERNAME}"

# ---------------------------------------------------------------------------
# Create the user account if it doesn't exist
# ---------------------------------------------------------------------------
if ! id "${USERNAME}" &>/dev/null; then
    bashio::log.info "Creating user account: ${USERNAME}"
    adduser -D -s /bin/bash "${USERNAME}"
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

HOME_DIR="/home/${USERNAME}"
export HOME="${HOME_DIR}"
export USER="${USERNAME}"

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
# Start XFCE4 desktop session
# ---------------------------------------------------------------------------
bashio::log.info "Starting XFCE4 desktop session"
su -c "DISPLAY=:1 startxfce4 &" "${USERNAME}"
XFCE_PID=$!

sleep 3

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

bashio::log.info "Starting noVNC on port 6080 (proxying VNC on 5900)"
websockify --web "${NOVNC_PATH}" 6080 localhost:5900 &
WEBSOCKIFY_PID=$!

bashio::log.info "Linux Mint desktop is ready — open the web browser and navigate to port 6080"

# ---------------------------------------------------------------------------
# Graceful shutdown
# ---------------------------------------------------------------------------
trap 'bashio::log.info "Shutting down..."; kill ${WEBSOCKIFY_PID} ${VNC_PID} ${XFCE_PID} ${XVFB_PID} 2>/dev/null; exit 0' SIGTERM SIGINT

# Wait for any background process to exit
wait ${WEBSOCKIFY_PID}
