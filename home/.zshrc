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
  ssh                  # uzupelnia hosty z ~/.ssh/config
  gh                   # uzupelnianie GitHub CLI
  fancy-ctrl-z         # Ctrl+Z dziala w obie strony (tlo <-> powrot)
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

# MUSI byc PO source ~/.p10k.zsh — kreator 'p10k configure' zapisuje tam
# INSTANT_PROMPT=verbose i nadpisalby ustawienie z gory pliku.
# 'quiet' = nie ostrzegaj, ze fastfetch pisze po konsoli przy starcie.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# ══ Powitanie ═══════════════════════════════════════════════
fastfetch --pipe false   # --pipe false = nie gas kolorow, gdy p10k przechwytuje wyjscie
