# Linux Mint for Home Assistant

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Supports amd64](https://img.shields.io/badge/arch-amd64-blue)
![Supports aarch64](https://img.shields.io/badge/arch-aarch64-blue)

A Home Assistant add-on that provides a **Linux Mint Cinnamon desktop environment** accessible via a web browser through [noVNC](https://novnc.com/). Interact with a full graphical Linux desktop directly from your Home Assistant sidebar — no VNC client required.

> **Note:** This add-on uses the **Cinnamon** desktop environment (Linux Mint's native DE) running on a Debian Bookworm base image. Cinnamon provides a full Linux Mint experience but requires more resources than lightweight alternatives.

---

## Screenshot

![Linux Mint Desktop via noVNC](https://raw.githubusercontent.com/phdindota/linux-mint-homeassistant/main/linux-mint/screenshot.png)

*(Screenshot placeholder — actual desktop appearance may vary)*

---

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Click the **⋮** menu and select **Repositories**.
3. Paste the following URL and click **Add**:
   ```
   https://github.com/phdindota/linux-mint-homeassistant
   ```
4. Find **Linux Mint** in the store and click **Install**.

---

## Configuration

| Option | Default | Description |
|---|---|---|
| `resolution` | `1920x1080` | Screen resolution (e.g. `1280x720`) |
| `vnc_password` | *(empty)* | VNC password — leave empty for no password |
| `username` | `user` | Desktop session username |

Example:

```yaml
resolution: "1920x1080"
vnc_password: "mysecretpassword"
username: "homeuser"
```

---

## Usage

After starting the add-on:

- **Sidebar**: Click the **Linux Mint** entry in the HA sidebar to open the desktop in your browser (via ingress).
- **Direct URL**: Navigate to `http://<your-ha-ip>:6080` in any browser.
- **VNC client**: Connect to `<your-ha-ip>:5900`.

---

## Contributing

Contributions are welcome! Please open an issue or pull request on [GitHub](https://github.com/phdindota/linux-mint-homeassistant).

---

## License

This project is licensed under the [MIT License](LICENSE).
