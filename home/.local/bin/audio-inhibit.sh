#!/bin/bash
# Blokuje uśpienie, gdy jakaś aplikacja odtwarza dźwięk.
# Nie patrzymy na stan sinków (RUNNING), bo trzymają go stale:
#  - strumień wyjściowy DSP głośników (effect_output.*),
#  - tapeta wideo w plasmashell (QtmPulseStream, nawet wyciszona).
playing() {
  pactl --format=json list sink-inputs 2>/dev/null | jq -e '
    any(.[];
      .corked == false
      and ((.properties."node.name" // "") | startswith("effect_output.") | not)
      and (.properties."application.name" // "") != "plasmashell")' >/dev/null
}

while true; do
  if playing; then
    systemd-inhibit --what=sleep --why="Music is playing" --mode=block sleep 65
  else
    sleep 60
  fi
done
