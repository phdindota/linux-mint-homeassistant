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
    python3 \
    python3-websockify \
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

# Verify noVNC installation
RUN echo "=== noVNC files ===" && ls -la /usr/share/novnc/ && \
    echo "=== websockify location ===" && which websockify

# Copy rootfs overlay
COPY rootfs /

# Copy and make entrypoint executable
COPY run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 6080 5900

CMD ["/run.sh"]
