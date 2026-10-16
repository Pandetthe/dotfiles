#!/usr/bin/env bash
# MesloLGS NF (zalecana przez autora p10k) + profil i schemat kolorow Konsoli
# Uruchom: bash ~/Admin/laptop/setup/konsola.sh
set -uo pipefail
[[ $EUID -eq 0 ]] && { echo "Nie uruchamiaj jako root."; exit 1; }

ok()   { echo -e "\n\033[1;32m✔\033[0m $*"; }
step() { echo -e "\n\033[1;36m▸ $*\033[0m"; }

KDIR="$HOME/.local/share/konsole"
FDIR="$HOME/.local/share/fonts/MesloLGS-NF"
mkdir -p "$KDIR" "$FDIR"

# ─── 1. Czcionka MesloLGS NF ─────────────────────────────────
step "1/4  MesloLGS NF — cztery odmiany"
BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
FAIL=0
for f in "Regular" "Bold" "Italic" "Bold Italic"; do
  out="$FDIR/MesloLGS NF ${f}.ttf"
  if [ -s "$out" ]; then echo "  jest: $f"; continue; fi
  url="$BASE/MesloLGS%20NF%20${f// /%20}.ttf"
  if curl -fLs -o "$out" "$url" && [ -s "$out" ]; then
    echo "  pobrano: $f"
  else
    echo "  !! nie udalo sie: $f"; rm -f "$out"; FAIL=1
  fi
done
fc-cache -f "$FDIR" >/dev/null 2>&1
if fc-list 2>/dev/null | grep -q 'MesloLGS NF'; then
  ok "czcionka widoczna w systemie ($(fc-list 2>/dev/null | grep -c 'MesloLGS NF') odmiany)"
else
  echo "!! Czcionka niedostepna — przerywam, bo profil bylby bezuzyteczny."; exit 1
fi

# ─── 2. Schemat kolorow ──────────────────────────────────────
step "2/4  Schemat kolorow (Catppuccin Mocha)"
cat > "$KDIR/CatppuccinMocha.colorscheme" <<'SCHEME'
[General]
Description=Catppuccin Mocha
Opacity=1
Wallpaper=
Blur=false
ColorRandomization=false

[Background]
Color=30,30,46
[BackgroundFaint]
Color=30,30,46
[BackgroundIntense]
Color=30,30,46

[Foreground]
Color=205,214,244
[ForegroundFaint]
Color=166,173,200
[ForegroundIntense]
Color=205,214,244

[Color0]
Color=69,71,90
[Color0Faint]
Color=49,50,68
[Color0Intense]
Color=88,91,112

[Color1]
Color=243,139,168
[Color1Faint]
Color=200,100,130
[Color1Intense]
Color=243,139,168

[Color2]
Color=166,227,161
[Color2Faint]
Color=130,180,125
[Color2Intense]
Color=166,227,161

[Color3]
Color=249,226,175
[Color3Faint]
Color=200,180,140
[Color3Intense]
Color=249,226,175

[Color4]
Color=137,180,250
[Color4Faint]
Color=110,145,200
[Color4Intense]
Color=137,180,250

[Color5]
Color=245,194,231
[Color5Faint]
Color=196,155,185
[Color5Intense]
Color=245,194,231

[Color6]
Color=148,226,213
[Color6Faint]
Color=118,180,170
[Color6Intense]
Color=148,226,213

[Color7]
Color=186,194,222
[Color7Faint]
Color=150,157,180
[Color7Intense]
Color=166,173,200
SCHEME
ok "$KDIR/CatppuccinMocha.colorscheme"

# ─── 3. Profil ───────────────────────────────────────────────
step "3/4  Profil Konsoli"
cat > "$KDIR/Jakub.profile" <<'PROFILE'
[Appearance]
ColorScheme=CatppuccinMocha
Font=MesloLGS NF,11,-1,5,50,0,0,0,0,0
UseFontLineChararacters=true

[General]
Name=Jakub
Parent=FALLBACK/
TerminalCenter=false
TerminalMargin=4

[Scrolling]
HistoryMode=2
ScrollBarPosition=2

[Terminal Features]
BlinkingCursorEnabled=true
PROFILE
ok "$KDIR/Jakub.profile"

# ─── 4. Ustawienie jako domyslny ─────────────────────────────
step "4/4  Ustawienie profilu jako domyslnego"
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "Jakub.profile"
  ok "zapisane przez kwriteconfig6"
elif ! grep -q 'DefaultProfile' "$HOME/.config/konsolerc" 2>/dev/null; then
  printf '\n[Desktop Entry]\nDefaultProfile=Jakub.profile\n' >> "$HOME/.config/konsolerc"
  ok "dopisane do konsolerc"
else
  sed -i 's|^DefaultProfile=.*|DefaultProfile=Jakub.profile|' "$HOME/.config/konsolerc"
  ok "podmienione w konsolerc"
fi

cat <<'EOT'

═══════════════════ CO DALEJ ═══════════════════

1. ZAMKNIJ WSZYSTKIE OKNA KONSOLI i otworz nowe.
   Otwarte okna trzymaja stary profil — nowy dziala dopiero od nowego okna.

2. SPRAWDZ, czy profil sie zlapal:
     Konsola → Ustawienia → Zarzadzaj profilami → "Jakub" powinien byc domyslny

3. DOSTROJENIE PROMPTU pod nowa czcionke:
     p10k configure
   Teraz kreator pokaze ikony poprawnie i pozwoli wybrac styl,
   ktory z nich korzysta (rainbow / lean z ikonami).

Gdyby cos nie pasowalo — stary stan to po prostu brak plikow:
     rm ~/.local/share/konsole/Jakub.profile
     rm ~/.local/share/konsole/CatppuccinMocha.colorscheme
EOT
