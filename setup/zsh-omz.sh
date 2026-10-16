#!/usr/bin/env bash
# zsh + Oh My Zsh + Powerlevel10k + wtyczki + przepisana konfiguracja z .bashrc
# Uruchom: bash ~/Admin/laptop/setup/zsh-omz.sh
set -uo pipefail
[[ $EUID -eq 0 ]] && { echo "Nie uruchamiaj jako root."; exit 1; }
sudo -v || exit 1

ok()   { echo -e "\n\033[1;32m✔\033[0m $*"; }
step() { echo -e "\n\033[1;36m▸ $*\033[0m"; }

ZSH_DIR="$HOME/.oh-my-zsh"
CUSTOM="$ZSH_DIR/custom"

# ─── 1. Pakiety ──────────────────────────────────────────────
step "1/6  Pakiety z repozytoriow Fedory"
sudo dnf install -y zsh zsh-autosuggestions zsh-syntax-highlighting \
                    fastfetch zoxide fzf eza fd-find git curl unzip || exit 1
ok "zsh $(zsh --version | awk '{print $2}') + wtyczki jako podpisane RPM-y"

# ─── 2. Oh My Zsh ────────────────────────────────────────────
step "2/6  Oh My Zsh"
if [ -d "$ZSH_DIR" ]; then
  ok "juz zainstalowany ($ZSH_DIR)"
else
  # RUNZSH=no  -> nie przelaczaj sie od razu do zsh
  # CHSH=no    -> nie zmieniaj powloki logowania (zrobimy to sami, swiadomie)
  # KEEP_ZSHRC -> nie nadpisuj .zshrc, piszemy wlasny nizej
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || exit 1
  ok "Oh My Zsh w $ZSH_DIR"
fi

# ─── 3. Powerlevel10k + wtyczki zewnetrzne ───────────────────
step "3/6  Powerlevel10k + zsh-completions"
clone_or_pull() {  # $1=url $2=katalog
  if [ -d "$2" ]; then git -C "$2" pull --quiet && echo "  zaktualizowano: $(basename "$2")"
  else git clone --depth=1 --quiet "$1" "$2" && echo "  sklonowano:   $(basename "$2")"; fi
}
clone_or_pull https://github.com/romkatv/powerlevel10k.git  "$CUSTOM/themes/powerlevel10k"
clone_or_pull https://github.com/zsh-users/zsh-completions.git "$CUSTOM/plugins/zsh-completions"
ok "motyw i wtyczki gotowe"

# ─── 4. Czcionka Nerd Font (p10k jej wymaga) ─────────────────
step "4/6  JetBrainsMono Nerd Font"
if fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd'; then
  ok "juz zainstalowana"
else
  TMP=$(mktemp -d); FONTDIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
  mkdir -p "$FONTDIR"
  if curl -fL --progress-bar -o "$TMP/f.zip" \
       https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
    unzip -qo "$TMP/f.zip" -d "$FONTDIR" -x '*.txt' '*.md' && fc-cache -f "$FONTDIR" >/dev/null
    ok "zainstalowana — USTAW JA W KONSOLI (patrz koniec)"
  else
    echo "  !! Pobieranie nieudane. p10k zadziala, ale bez ikon."
  fi
  rm -rf "$TMP"
fi

# ─── 5. Przepisanie konfiguracji z .bashrc ───────────────────
step "5/6  Zapis ~/.zshrc (przepisane z .bashrc)"
[ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.bak-$(date +%Y%m%d-%H%M%S)" && echo "  backup starego .zshrc"

cat > "$HOME/.zshrc" <<'ZSHRC'
# ══ Powerlevel10k instant prompt — MUSI byc na samej gorze ══
# Pozwala pokazac prompt zanim reszta configu sie zaladuje.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# 'quiet' = nie marudz, ze fastfetch pisze po konsoli przy starcie
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# ══ Oh My Zsh ═══════════════════════════════════════════════
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

zstyle ':omz:update' mode reminder      # przypominaj, nie aktualizuj sam
COMPLETION_WAITING_DOTS="true"

plugins=(
  git                  # ~150 skrotow: gst, gco, gcm, gp...
  sudo                 # ESC ESC dopisuje sudo do ostatniego polecenia
  dotnet               # uzupelnianie dotnet + aliasy
  podman
  dnf                  # skroty do dnf
  systemd              # sc-start, sc-status...
  extract              # 'x plik.tar.gz' rozpakuje cokolwiek
  colored-man-pages
  copypath             # kopiuje sciezke do schowka
  dirhistory           # Alt+strzalki = nawigacja po katalogach
  fzf                  # Ctrl-R, Ctrl-T
  zsh-completions      # dodatkowe definicje uzupelniania
)

source "$ZSH/oh-my-zsh.sh"

# ══ PATH ════════════════════════════════════════════════════
typeset -U path                          # zsh sam usuwa duplikaty
export ANDROID_HOME="$HOME/Android/Sdk"
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  $path
  "$ANDROID_HOME/emulator"
  "$ANDROID_HOME/platform-tools"
  "$ANDROID_HOME/tools"
  "$ANDROID_HOME/tools/bin"
  "$HOME/.maestro/bin"
  "$HOME/.local/share/JetBrains/Toolbox/scripts"
)

# ══ Zmienne srodowiskowe (z .bashrc) ════════════════════════
export SSL_CERT_DIR="$HOME/.aspnet/dev-certs/trust:/etc/pki/tls/certs"
export ASPIRE_CONTAINER_RUNTIME=podman
export ASPIRE_ENABLE_CONTAINER_TUNNEL=true
export MAESTRO_OPTS="-Djava.io.tmpdir=$HOME/.maestro/tmp"

# ══ Historia ════════════════════════════════════════════════
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE
setopt HIST_VERIFY EXTENDED_HISTORY
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS NO_BEEP

# ══ Funkcje i aliasy (z .bashrc) ════════════════════════════
alias ssh-list="grep -i '^Host ' ~/.ssh/config | grep -v '*' | awk '{print \$2}'"
rider()  { (command rider  "$@" >/dev/null 2>&1 &) }
idea()   { (command idea   "$@" >/dev/null 2>&1 &) }
studio() { (command studio "$@" >/dev/null 2>&1 &) }

# neofetch jest zarchiwizowany i nie ma go w Fedorze — fastfetch to nastepca
alias neofetch='fastfetch'
command -v eza >/dev/null && alias ls='eza --group-directories-first' && alias ll='eza -l --git'

# ══ mise — PO oh-my-zsh.sh, zeby zlapal compinit ════════════
command -v mise   >/dev/null && eval "$(mise activate zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ══ Wtyczki z RPM-ow — kolejnosc jest istotna ═══════════════
# autosuggestions -> syntax-highlighting -> history-substring-search
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

bindkey '^[[A' history-search-backward   # strzalka w gore = szukaj po prefiksie
bindkey '^[[B' history-search-forward

# ══ Powerlevel10k — konfiguracja z kreatora ═════════════════
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ══ Powitanie ═══════════════════════════════════════════════
fastfetch
ZSHRC
ok "~/.zshrc zapisany ($(wc -l < "$HOME/.zshrc") linii)"

# ─── 6. Kontrola skladni ─────────────────────────────────────
step "6/6  Sprawdzenie"
if zsh -n "$HOME/.zshrc"; then ok "skladnia .zshrc poprawna"; else echo "!! BLAD skladni"; fi

cat <<'EOT'

═══════════════════ CO DALEJ ═══════════════════

1. CZCIONKA — bez tego p10k pokaze puste prostokaty:
     Konsole → Ustawienia → Edytuj profil → Wyglad → Czcionka
     wybierz:  JetBrainsMono Nerd Font

2. URUCHOM ZSH (bez zmiany powloki logowania):
     zsh

3. KREATOR WYGLADU p10k wystartuje sam przy pierwszym uruchomieniu.
   Gdyby nie — odpal recznie:
     p10k configure
   Pyta o styl (rainbow/lean/classic), ikony, dwuliniowy prompt itd.
   Wynik zapisuje do ~/.p10k.zsh

4. GDY PASUJE — powloka logowania na stale:
     chsh -s /usr/bin/zsh
   (dziala po wylogowaniu; powrot: chsh -s /bin/bash)

UWAGA: ~/.bashrc zostaje nietkniety. Skrypty z #!/bin/bash dzialaja
jak dotad, niezaleznie od powloki logowania.
EOT
