# Dynamic Bubble

A responsive SDDM theme for Arch Linux with Pywal colors, animated login controls and a primary-monitor-only login UI.

<p align="center">
  <img src="assets/01.png" width="31%" />
  <img src="assets/02.png" width="31%" />
</p>

## Features

- Pywal wallpaper and palette synchronization
- `color11` accent with matching Pywal status colors
- Login UI only on the primary SDDM monitor by default
- Responsive scaling for different resolutions
- User and session selection
- PAM authentication/error feedback
- Root-owned theme source with writable runtime cache kept separately
- Automatic user-level Pywal cache watcher
- Qt 6 SDDM theme

## Install

```bash
git clone --depth 1 https://github.com/L4ZY404/SDDM-THEME-Dynamic_bubble.git
cd SDDM-THEME-Dynamic_bubble
./install.sh
```

On Arch, the installer installs missing SDDM/Qt dependencies, installs and selects the theme, and runs an initial Pywal sync when a cache already exists.

Pywal changes are watched automatically through a user systemd path unit. You can also force a refresh manually:

```bash
dynamic-bubble-sync
```

HyprL4zy does not need to own or patch Dynamic Bubble internals.

## Testing

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/Dynamic_bubble
```

## HyprL4zy integration

The HyprL4zy installer only needs to clone this repository and run its installer:

```bash
git clone --depth 1 https://github.com/L4ZY404/SDDM-THEME-Dynamic_bubble.git /tmp/Dynamic_bubble
(
  cd /tmp/Dynamic_bubble
  ./install.sh
)
rm -rf /tmp/Dynamic_bubble
```

The theme installs its own Pywal watcher, so the HyprL4zy installer does not need any extra Dynamic Bubble runtime setup. Calling `dynamic-bubble-sync --quiet` manually is still supported.

## License

Dynamic Bubble is licensed under GPL-3.0. The bundled JetBrains Mono Nerd Font remains under the SIL Open Font License 1.1; its license is included beside the font.
