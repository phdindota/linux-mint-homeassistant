# Linux Mint Desktop for Home Assistant

## What This App Does

This add-on provides a Linux Mint Cinnamon desktop environment accessible directly from your Home Assistant instance via a web browser. It uses **Cinnamon** as the desktop environment running inside a Debian Bookworm container, exposed through **noVNC** so you can interact with a full graphical desktop without any additional client software.

> **Note:** Cinnamon is Linux Mint's native desktop environment. It provides an authentic Linux Mint experience but requires more RAM and CPU than lightweight alternatives. A system with at least 2 GB of free RAM is recommended.

---

## Installation

1. In Home Assistant, navigate to **Settings → Add-ons → Add-on Store**.
2. Click the three-dot menu (⋮) in the top-right corner and select **Repositories**.
3. Add the following URL and click **Add**:
   ```
   https://github.com/phdindota/linux-mint-homeassistant
   ```
4. Refresh the page. The **Linux Mint** add-on will appear in the store.
5. Click **Linux Mint**, then click **Install**.

---

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `resolution` | string | `1920x1080` | Screen resolution for the virtual display (e.g. `1280x720`, `1920x1080`) |
| `vnc_password` | string | *(empty)* | Optional password for VNC access. Leave empty to disable password protection |
| `username` | string | `user` | Username for the desktop session account |

### Example Configuration

```yaml
resolution: "1920x1080"
vnc_password: "mysecretpassword"
username: "homeuser"
```

---

## Accessing the Desktop

### Via Home Assistant Sidebar (Ingress)

After starting the add-on, a **Linux Mint** entry will appear in your Home Assistant sidebar. Click it to open the desktop in your browser — no extra configuration needed.

### Via Direct URL

You can also access the noVNC interface directly at:

```
http://<your-ha-ip>:6080
```

Or for VNC clients (e.g. RealVNC, TigerVNC):

```
<your-ha-ip>:5900
```

---

## Known Limitations

- **Higher resource usage:** Cinnamon is Linux Mint's full desktop environment and uses more RAM and CPU than lightweight alternatives. At least 2 GB of free RAM is recommended; consider using `1280x720` resolution on lower-end hardware.
- **No audio:** Audio pass-through is not supported in this add-on.
- **No GPU acceleration:** The virtual framebuffer (Xvfb) does not support 3D/GPU acceleration. Applications requiring hardware-accelerated graphics may not work correctly.
- **Performance:** High resolutions may result in sluggish performance depending on your hardware and network conditions. Consider using `1280x720` on lower-end hardware.
- **Persistence:** Files saved inside the container may be lost on add-on restart unless mapped to persistent storage. Use Home Assistant's `/share` or `/media` directories for persistent files.

---

## Troubleshooting

### Desktop does not load

- Check the add-on **Log** tab for error messages.
- Ensure port `6080` is not blocked by your firewall.
- Try restarting the add-on.

### Black screen in browser

- Wait 10–15 seconds after starting the add-on for all services to initialise.
- Refresh the noVNC page.
- Check logs to confirm `x11vnc` and `websockify` started successfully.

### VNC password not working

- Ensure the password is set in the add-on configuration and the add-on has been restarted after saving.
- If you forget the password, clear the `vnc_password` field and restart the add-on.

### High CPU/memory usage

- Lower the resolution in the add-on configuration.
- Close unused applications inside the desktop session.
