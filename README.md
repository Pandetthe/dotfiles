# Dotfiles

Configuration of my Fedora 44 laptop (Dell Latitude 7430, KDE Plasma, zsh). Comments in the
files are in Polish.

## Layout

`home/` mirrors `$HOME`: every file lives at the same path relative to the home directory.

| Path | What it does |
|---|---|
| `.zshrc`, `.p10k.zsh` | zsh with Oh My Zsh, Powerlevel10k, mise, zoxide and fzf |
| `.local/bin/audio-inhibit.sh` + `.config/autostart/Audio Sleep Inhibitor.desktop` | blocks suspend while an application plays sound (ignores the speaker DSP stream and the video wallpaper) |
| `.local/bin/tv-panel-autohide` + `.config/systemd/user/tv-panel-autohide.service` | auto-hides the Plasma panel shown on the OLED TV (HDMI-A-1) to prevent burn-in |
| `.config/pipewire/pipewire.conf.d/laptop-speakers.conf` | DSP for the built-in speakers: bass enhancer, high-pass, EQ, stereo widening, compressor, limiter |
| `.config/wireplumber/wireplumber.conf.d/50-laptop-speakers-dsp.conf` + `.local/share/wireplumber/scripts/laptop-speakers-dsp.lua` | enables the DSP only while the speakers are the active route, and switches the card profile between HDMI and analog |
| `.config/environment.d/50-qt-audio-pulseaudio.conf` | temporary workaround: Qt Multimedia on PulseAudio, because its PipeWire backend crashes plasmashell on Qt 6.11 |

`setup/` holds the one-off scripts used to set the system up:

| Script | What it does |
|---|---|
| `zsh-omz.sh` | installs zsh, Oh My Zsh, Powerlevel10k and plugins, writes the first `.zshrc` |
| `konsola.sh` | MesloLGS NF font, Catppuccin Mocha colour scheme and a default Konsole profile |
| `snapshoty.sh` | snapper for `/` and `/home`, retention limits, timers and the `dnf-snap` wrapper |

`.zshrc` in `home/` is the current version. It has moved on from the one `zsh-omz.sh` writes.

## Installing

Copy the files you need into place, then reload what uses them:

```sh
cp -a home/. ~/
systemctl --user daemon-reload
systemctl --user enable --now tv-panel-autohide
systemctl --user restart pipewire pipewire-pulse wireplumber
```

`environment.d` and the autostart entry take effect after logging out and back in.
