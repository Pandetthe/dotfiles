#!/usr/bin/env bash
# Snapper na Fedorze 44 — subvol=root (/) + subvol=home (/home)
# Uruchom: bash ~/Admin/laptop/setup/snapshoty.sh
set -uo pipefail

[[ $EUID -eq 0 ]] && { echo "Nie uruchamiaj jako root."; exit 1; }
sudo -v || exit 1
U=$(id -un)

ok()   { echo -e "\n\033[1;32m✔\033[0m $*"; }
step() { echo -e "\n\033[1;36m▸ $*\033[0m"; }

# ─────────────────────────────────────────────────────────────
step "1/5  Instalacja"
sudo dnf install -y snapper btrfs-assistant || exit 1
ok "snapper + btrfs-assistant"

# ─────────────────────────────────────────────────────────────
step "2/5  Konfiguracje dla / i /home"
sudo snapper -c root create-config /      2>/dev/null && ok "config: root" || ok "config: root (juz istnial)"
sudo snapper -c home create-config /home  2>/dev/null && ok "config: home" || ok "config: home (juz istnial)"

# ─────────────────────────────────────────────────────────────
step "3/5  Limity retencji (domyslne snappera sa zbyt zachlanne)"
sudo snapper -c root set-config \
  TIMELINE_CREATE=no \
  TIMELINE_CLEANUP=yes \
  NUMBER_CLEANUP=yes \
  NUMBER_LIMIT=15 \
  NUMBER_LIMIT_IMPORTANT=8 \
  EMPTY_PRE_POST_CLEANUP=yes \
  ALLOW_USERS="$U" \
  SYNC_ACL=yes
ok "limity: root (snapshoty tylko przy dnf-snap)"

sudo snapper -c home set-config \
  TIMELINE_CREATE=yes \
  TIMELINE_CLEANUP=yes \
  TIMELINE_LIMIT_HOURLY=6 \
  TIMELINE_LIMIT_DAILY=7 \
  TIMELINE_LIMIT_WEEKLY=4 \
  TIMELINE_LIMIT_MONTHLY=2 \
  TIMELINE_LIMIT_YEARLY=0 \
  NUMBER_CLEANUP=yes \
  NUMBER_LIMIT=20 \
  EMPTY_PRE_POST_CLEANUP=yes \
  ALLOW_USERS="$U" \
  SYNC_ACL=yes
ok "limity: home (co godzine)"

# ─────────────────────────────────────────────────────────────
step "4/5  Timery (snapshot co godzine + sprzatanie)"
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
ok "timery aktywne"

# ─────────────────────────────────────────────────────────────
step "5/5  Snapshot przed aktualizacja (obejscie braku wtyczki do dnf5)"
sudo tee /usr/local/bin/dnf-snap >/dev/null <<'EOF'
#!/usr/bin/env bash
# Snapshot systemu przed transakcja dnf i po niej.
DESC="dnf ${*:-upgrade}"
PRE=$(sudo snapper -c root create -t pre -c number -p -d "$DESC") || exit 1
# snapshot 'post' powstaje ZAWSZE, nawet gdy dnf sie wywroci
trap 'sudo snapper -c root create -t post --pre-number "$PRE" -c number -d "$DESC"; \
      echo "snapshot pre=$PRE (porownanie: snapper -c root status $PRE..$((PRE+1)))"' EXIT
sudo dnf "${@:-upgrade}"
EOF
sudo chmod +x /usr/local/bin/dnf-snap
ok "polecenie: dnf-snap upgrade"

# ─────────────────────────────────────────────────────────────
step "Pierwszy snapshot bazowy"
sudo snapper -c root create -d "baza — po audycie systemu"
sudo snapper -c home create -d "baza — po audycie systemu"

echo -e "\n\033[1;32m═══ GOTOWE ═══\033[0m\n"
sudo snapper -c root list
echo
sudo snapper -c home list
cat <<'EOT'

JAK UZYWAC
  snapper -c root list                    lista snapshotow systemu
  snapper -c home list                    lista snapshotow /home
  snapper -c home status 3..5             co sie zmienilo miedzy 3 a 5
  dnf-snap upgrade                        upgrade ze snapshotem pre/post

ODTWORZENIE PLIKU (najczestszy przypadek):
  ls /home/.snapshots/5/snapshot/pandetthe/
  cp -a /home/.snapshots/5/snapshot/pandetthe/plik.txt ~/

  albo graficznie:  btrfs-assistant

UWAGA: pelny rollback systemu wymaga recznej podmiany subwolumenu
z pendrive'a live — 'snapper rollback' na Fedorze nie zadziala.
EOT
