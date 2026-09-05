#!/usr/bin/env bash

# Mint Clean - interactive maintenance for Linux Mint / Ubuntu systems.
# Nothing is cleaned until the user selects an action and confirms it.

set -u

readonly VERSION="1.5.0"
readonly ESC=$'\033'
readonly RESET="${ESC}[0m"
readonly BOLD="${ESC}[1m"
readonly DIM="${ESC}[2m"
readonly CYAN="${ESC}[38;5;45m"
readonly TEAL="${ESC}[38;5;37m"
readonly BLUE="${ESC}[38;5;39m"
readonly GREEN="${ESC}[38;5;82m"
readonly YELLOW="${ESC}[38;5;220m"
readonly RED="${ESC}[38;5;196m"
readonly BRIGHT_RED="${ESC}[38;5;203m"
readonly DARK_RED="${ESC}[38;5;88m"
readonly WHITE="${ESC}[38;5;255m"
readonly GREY="${ESC}[38;5;245m"
readonly DARK_GREY="${ESC}[38;5;238m"
readonly MAGENTA="${ESC}[38;5;201m"

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mint-clean"
LOG_FILE=""

init_log() {
    mkdir -p -- "$LOG_DIR"
    LOG_FILE="$LOG_DIR/run-$(date '+%Y%m%d-%H%M%S').log"
    : > "$LOG_FILE"
    printf 'Mint Clean %s started %s\n' "$VERSION" "$(date --iso-8601=seconds)" >> "$LOG_FILE"
}

log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG_FILE"
}

pause() {
    printf '\n%sPress Enter to return to the menu...%s' "$GREY" "$RESET"
    read -r
}

confirm() {
    local answer
    printf '%s%s [y/N]: %s' "$YELLOW" "$1" "$RESET"
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

run_cmd() {
    log "RUN: $*"
    "$@" 2>&1 | tee -a "$LOG_FILE"
    local rc=${PIPESTATUS[0]}
    if (( rc != 0 )); then
        printf '%sCommand exited with status %d.%s\n' "$RED" "$rc" "$RESET"
        log "EXIT: $rc"
    fi
    return "$rc"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

clear_screen() {
    if [[ -t 1 ]]; then
        printf '\033[2J\033[H'
    fi
}

panda_menu_row() {
    local colour=$1 text=${2:-}
    printf '%s               ░▓▓░ ░▓%s  %s%-32.32s%s  %s░▒  ░▓▒%s\n' \
        "$GREY" "$RESET" "$colour" "$text" "$RESET" "$GREY" "$RESET"
}

banner() {
    printf '%s%sMINT CLEAN v%s%s\n\n' "$CYAN" "$BOLD" "$VERSION" "$RESET"
}

disk_line() {
    local used avail percent
    read -r used avail percent < <(df -hP / | awk 'NR==2 {print $3, $4, $5}')
    printf '  %sRoot disk:%s  used %-7s  free %-7s  (%s used)\n' \
        "$BLUE" "$RESET" "$used" "$avail" "$percent"
}

show_menu() {
    local used avail percent status log_name
#    clear_screen
    printf '%s' "$GREY"
    cat <<'PANDA_TOP'
                       ░░                              ░
                   ░▒▓▓▓▓▓▓▓▓▒                   ░▒▓▓▓▓▓▓▓▓▒░
                 ▒▓█▓▓▒░░░▒▒▒█▓                 ░█▓▒▒░░░░▒▒▓▓▓░
                ▒█▓░         ░█▓       ░       ░▓▓░         ░▓▓░
               ▒█▒░           ░▓▒▒▓█████████▓▓▒▓▓            ░▓▓░
              ░█▒           ░▓▓█████████████████▓▓▒░          ░▓▓
              ░▓▓        ░▓██████████████████████████▒        ░▓▓
               ░█▓      ▓██████████████████████████████▓     ░▓▓
              ▒ ░▓▓▓▒ ▒██████████████████████████████████░ ▒▒▓▒  ░
            ░▓▒    ░▒▓████████████████████████████████████▒▒░    ▒▒░
           ▒▓░ ░░   ░██████████████████████████████████████░   ░░ ▒▓░
          ▒▓░ ░░    ███████░  ░▓████████████████▓░  ░██████▓   ░░░░░▓░
          ▓▒ ░░    ▒█████▓       ▒▓██████████▓▒       ▓█████▒    ▒░░▓▒
          ▓▒ ░░    █████▒    ▒▒░░  ▓████████▒  ░░▒▒    ▒████▓    ▒░░▓▒
          ▓▒ ░░   ░████      ▒██▓▒  ████████  ▒▓██▒     ░████░   ░░ ▓▒
          ▓▒ ░▒   ░████▒      ░▒▒░▒██████████▒░▒▒░      ▓███▓   ░▒░ ▓▒
          ▓▒ ▒▓░   ▒████▒       ░▓████████████▓░       ▒███▓▒   ░▓░ ▓▒
          ▓▒  ▒     ▓▓▓██▓▒░   ▒████████████████▒   ░▒▓█▓▓▓▓    ░▒  ▓▒
          ▓▒  ▒     ░▓▓▓▓▓▓█▓  ████▓▒▓▓██▓▓▒▓███▓ ░▓▓▓▓▓▓▓▓░    ░▒  ▓▒
          ▓▒  ░▒░     ░▒▒▒▓▓▓▒ ▓███▓▒     ░▒▓██▓▒ ▒▓▒▒▒▒▒░     ░▒░  ▓▒
          ▓▓    ░▒░      ░░▒▒▒  ▒▓▓▓▓▓▒░░▒▓▓▓▓▓▒  ▒▒▒░░      ░▒░    ▓▒
          ▒▓▓░    ░░              ▒▒▒▒░  ░▒▒▒░              ░░    ░▒▓░
           ░▒▓▒    ▒                   ░▒░                  ▒   ░▒▓▒
             ░▓▓▒  ░▒░                                     ░▒░  ▒▓▒
               ░▓▓░ ░▓                                    ░▒  ░▓▒
PANDA_TOP
    printf '%s' "$RESET"

    panda_menu_row "$CYAN$BOLD" "       MINT CLEAN v$VERSION"
    panda_menu_row "$WHITE" ''
    panda_menu_row "$WHITE" '[1] Inspect cleanup targets'
    panda_menu_row "$WHITE" '[2] Clean APT packages/cache'
    panda_menu_row "$WHITE" '[3] Vacuum system journal'
    panda_menu_row "$WHITE" '[4] Empty trash/thumbnails'
    panda_menu_row "$WHITE" '[5] Remove crash reports'
    panda_menu_row "$WHITE" '[6] Remove unused Flatpak data'
    panda_menu_row "$WHITE" '[7] Clean Docker debris'
    panda_menu_row "$GREEN$BOLD" '[8] Run recommended cleanup'
    panda_menu_row "$WHITE" ''
    panda_menu_row "$CYAN" '[L] View current log'
    panda_menu_row "$RED" '[Q] Quit'
    panda_menu_row "$WHITE" ''
    read -r used avail percent < <(df -hP / | awk 'NR==2 {print $3, $4, $5}')
    printf -v status 'Disk: %s used / %s free' "$used" "$avail"
    panda_menu_row "$YELLOW" "$status"
    panda_menu_row "$YELLOW" "Capacity: $percent"
    log_name=${LOG_FILE##*/}
    panda_menu_row "$DARK_GREY" "Log: $log_name"
    panda_menu_row "$WHITE" ''

    printf '%s' "$GREY"
    cat <<'PANDA_BOTTOM'
                ░▓▒  ▒▒░                                ░▒▒  ░▓▒
                 ▒▓▒  ░▒▒░                            ░▒▒░  ▒▓▒
                  ░▒░   ░░░░░░                    ░░░░░░   ░▒░
                      ░▒▒▒░  ░▒░                ░▒░  ░▒▒▒░
                             ░░░░░░░        ░░░░░░░
                                   ░░░░░░░░░░
PANDA_BOTTOM
    printf '%s\n' "$RESET"
    printf '\n'
}

size_or_zero() {
    local target=$1
    if [[ -e "$target" ]]; then
        du -sh -- "$target" 2>/dev/null | awk '{print $1}'
    else
        printf '0'
    fi
}

inspect_targets() {
    clear_screen
    banner
    printf '%sCleanup target summary%s\n\n' "$BOLD" "$RESET"
    disk_line
    printf '\n  APT package archives:  %s\n' "$(size_or_zero /var/cache/apt/archives)"
    printf '  Your trash:            %s\n' "$(size_or_zero "${XDG_DATA_HOME:-$HOME/.local/share}/Trash")"
    printf '  Your thumbnails:       %s\n' "$(size_or_zero "$HOME/.cache/thumbnails")"
    printf '  Crash reports:         %s\n' "$(size_or_zero /var/crash)"
    if have journalctl; then
        printf '  System journal:        '
        journalctl --disk-usage 2>/dev/null | sed 's/^Archived and active journals take up / /'
    fi
    if have flatpak; then
        printf '\n%sUnused Flatpak runtimes (preview):%s\n' "$BLUE" "$RESET"
        flatpak uninstall --unused --assumeno 2>/dev/null || true
    fi
    if have docker; then
        printf '\n%sDocker disk usage:%s\n' "$BLUE" "$RESET"
        docker system df 2>/dev/null || printf '  Docker is installed but not currently accessible.\n'
    fi
    log "Inspected cleanup targets"
    pause
}

clean_apt() {
    if ! have apt-get; then
        printf '%sAPT was not found. This action supports Mint/Ubuntu/Debian systems.%s\n' "$RED" "$RESET"
        return 1
    fi

    printf '%sAPT preview:%s\n' "$BLUE" "$RESET"
    sudo apt-get --simulate autoremove --purge 2>&1 | tee -a "$LOG_FILE"
    printf '\nThis removes packages APT marks as no longer required and clears downloaded package files.\n'
    if confirm 'Continue with APT cleanup?'; then
        run_cmd sudo apt-get autoremove --purge
        run_cmd sudo apt-get clean
        log "APT cleanup completed"
    else
        log "APT cleanup skipped"
    fi
}

clean_journal() {
    if ! have journalctl; then
        printf '%sjournalctl is not installed.%s\n' "$RED" "$RESET"
        return 1
    fi
    journalctl --disk-usage 2>/dev/null || true
    printf 'This deletes archived system logs older than 7 days.\n'
    if confirm 'Vacuum the system journal?'; then
        run_cmd sudo journalctl --vacuum-time=7d
        log "Journal vacuum completed"
    else
        log "Journal vacuum skipped"
    fi
}

clean_personal() {
    local trash="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
    local thumbs="$HOME/.cache/thumbnails"
    printf 'Targets:\n  %s\n  %s\n' "$trash" "$thumbs"
    printf 'Trash contents cannot be restored after this action.\n'
    if confirm 'Empty your trash and thumbnail cache?'; then
        if have gio; then
            run_cmd gio trash --empty
        else
            find "$trash/files" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
            find "$trash/info" -mindepth 1 -maxdepth 1 -exec rm -f -- {} + 2>/dev/null || true
            log "Emptied trash using find fallback"
        fi
        if [[ -d "$thumbs" ]]; then
            find "$thumbs" -mindepth 1 -delete 2>/dev/null || true
            log "Cleared thumbnail cache"
        fi
        printf '%sPersonal cleanup complete.%s\n' "$GREEN" "$RESET"
    else
        log "Personal cleanup skipped"
    fi
}

clean_crashes() {
    printf 'Target: /var/crash\n'
    printf 'These are diagnostic crash reports, not personal documents.\n'
    if confirm 'Delete stale crash reports?'; then
        if [[ -d /var/crash ]]; then
            run_cmd sudo find /var/crash -mindepth 1 -maxdepth 1 -type f -delete
        fi
        log "Crash reports cleanup completed"
    else
        log "Crash reports cleanup skipped"
    fi
}

clean_flatpak() {
    if ! have flatpak; then
        printf '%sFlatpak is not installed; skipping.%s\n' "$GREY" "$RESET"
        log "Flatpak cleanup unavailable"
        return 0
    fi
    flatpak uninstall --unused --assumeno 2>/dev/null || true
    printf '\nThis removes runtimes and extensions no installed Flatpak app needs.\n'
    if confirm 'Remove unused Flatpak data?'; then
        run_cmd flatpak uninstall --unused
        log "Flatpak cleanup completed"
    else
        log "Flatpak cleanup skipped"
    fi
}

clean_docker() {
    if ! have docker; then
        printf '%sDocker is not installed; skipping.%s\n' "$GREY" "$RESET"
        log "Docker cleanup unavailable"
        return 0
    fi
    printf '%sDocker disk usage:%s\n' "$BLUE" "$RESET"
    docker system df 2>/dev/null || {
        printf '%sDocker is not running or your user cannot access it.%s\n' "$RED" "$RESET"
        return 1
    }
    printf '\nThis removes stopped containers, unused networks, dangling images and build cache.\n'
    printf '%sNamed and anonymous volumes are NOT removed.%s\n' "$GREEN" "$RESET"
    if confirm 'Prune unused Docker objects?'; then
        run_cmd docker system prune
        log "Docker cleanup completed"
    else
        log "Docker cleanup skipped"
    fi
}

recommended_cleanup() {
    printf '%sRecommended cleanup runs APT, journal, trash/thumbnails, crash reports and Flatpak.%s\n' "$BOLD" "$RESET"
    printf 'Each section still asks for confirmation. Docker is not included.\n\n'
    clean_apt
    printf '\n'
    clean_journal
    printf '\n'
    clean_personal
    printf '\n'
    clean_crashes
    printf '\n'
    clean_flatpak
}

open_log() {
    if have less; then
        less "$LOG_FILE"
    else
        sed -n '1,240p' "$LOG_FILE"
        pause
    fi
}

main() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        printf '%sDo not run this entire script as root.%s\n' "$RED" "$RESET"
        printf 'Run it as your normal user; it requests sudo only where needed.\n'
        exit 1
    fi
    if [[ ! -t 0 ]]; then
        printf 'Mint Clean requires an interactive terminal.\n' >&2
        exit 1
    fi

    init_log
    while true; do
        show_menu
        printf '%sSelect an option: %s' "$BOLD" "$RESET"
        read -r choice
        case "${choice,,}" in
            1) inspect_targets ;;
            2) clear_screen; banner; clean_apt; pause ;;
            3) clear_screen; banner; clean_journal; pause ;;
            4) clear_screen; banner; clean_personal; pause ;;
            5) clear_screen; banner; clean_crashes; pause ;;
            6) clear_screen; banner; clean_flatpak; pause ;;
            7) clear_screen; banner; clean_docker; pause ;;
            8) clear_screen; banner; recommended_cleanup; pause ;;
            l) open_log ;;
            q) log "Exited normally"; clear_screen; printf '%sMint Clean finished.%s Log: %s\n' "$GREEN" "$RESET" "$LOG_FILE"; exit 0 ;;
            *) printf '%sUnknown option.%s\n' "$RED" "$RESET"; sleep 1 ;;
        esac
    done
}

main "$@"
