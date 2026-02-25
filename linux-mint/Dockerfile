ARG BUILD_FROM
FROM $BUILD_FROM

ENV DEBIAN_FRONTEND=noninteractive

# Install Cinnamon desktop and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    cinnamon \
    cinnamon-desktop-environment \
    dbus-x11 \
    x11vnc \
    xvfb \
    novnc \
    websockify \
    bash \
    sudo \
    wget \
    curl \
    nano \
    firefox-esr \
    nemo \
    gnome-terminal \
    fonts-liberation \
    fonts-noto \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    procps \
    net-tools \
    xdg-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user with sudo privileges
RUN useradd -m -s /bin/bash linuxmint \
    && echo "linuxmint ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up noVNC - find the correct path and create index.html
RUN NOVNC_DIR="" && \
    if [ -d "/usr/share/novnc" ]; then NOVNC_DIR="/usr/share/novnc"; \
    elif [ -d "/usr/share/webapps/novnc" ]; then NOVNC_DIR="/usr/share/webapps/novnc"; fi && \
    if [ -n "$NOVNC_DIR" ]; then \
      ln -sf "$NOVNC_DIR/vnc.html" "$NOVNC_DIR/index.html" 2>/dev/null || true; \
    fi

# Copy rootfs overlay
COPY rootfs /

# Copy and make entrypoint executable
COPY run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 6080 5900

CMD ["/run.sh"]
