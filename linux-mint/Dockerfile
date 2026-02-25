ARG BUILD_FROM
FROM $BUILD_FROM

# Install required packages
RUN apk add --no-cache \
    xfce4 \
    xfce4-terminal \
    thunar \
    x11vnc \
    xvfb \
    novnc \
    websockify \
    bash \
    sudo \
    wget \
    curl \
    nano \
    dbus \
    dbus-x11 \
    firefox \
    ttf-freefont \
    font-noto \
    mesa-gl \
    mesa-dri-gallium \
    shadow

# Create a non-root user with sudo privileges
RUN adduser -D -s /bin/bash linuxmint \
    && echo "linuxmint ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up noVNC symlink so index.html is accessible
RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html || true

# Copy rootfs overlay
COPY rootfs /

# Copy and make entrypoint executable
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Expose noVNC and VNC ports
EXPOSE 6080 5900

CMD ["/run.sh"]
