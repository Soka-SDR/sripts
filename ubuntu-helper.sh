#!/usr/bin/env bash

# Panda Ubuntu Helper
# Interactive Ubuntu Server installer and diagnostic console.

set -u

readonly VERSION="1.1.0"
readonly ESC=$'\033'
readonly RESET="${ESC}[0m"
readonly BOLD="${ESC}[1m"
readonly CYAN="${ESC}[38;5;45m"
readonly GREEN="${ESC}[38;5;82m"
readonly YELLOW="${ESC}[38;5;220m"
readonly RED="${ESC}[38;5;196m"
readonly WHITE="${ESC}[38;5;255m"
readonly GREY="${ESC}[38;5;245m"
readonly DARK_GREY="${ESC}[38;5;238m"

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/panda-ubuntu-helper"
LOG_FILE=""

init_log() {
    mkdir -p -- "$LOG_DIR"
    LOG_FILE="$LOG_DIR/run-$(date '+%Y%m%d-%H%M%S').log"
    : > "$LOG_FILE"
    printf 'Panda Ubuntu Helper %s started %s\n' \
        "$VERSION" "$(date --iso-8601=seconds)" >> "$LOG_FILE"
}

log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG_FILE"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

clear_screen() {
    [[ -t 1 ]] && printf '\033[H\033[2J\033[3J'
}

pause() {
    printf '\n%sPress Enter to return...%s' "$DARK_GREY" "$RESET"
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

panda_top() {
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
}

panda_row() {
    local colour=$1 text=${2:-}
    printf '%s               ░▓▓░ ░▓%s  %s%-32.32s%s  %s░▒  ░▓▒%s\n' \
        "$GREY" "$RESET" "$colour" "$text" "$RESET" "$GREY" "$RESET"
}

panda_bottom() {
    printf '%s' "$GREY"
    cat <<'PANDA_BOTTOM'
                ░▓▒  ▒▒░                                ░▒▒  ░▓▒
                 ▒▓▒  ░▒▒░                            ░▒▒░  ▒▓▒
                  ░▒░   ░░░░░░                    ░░░░░░   ░▒░
                     ░▒▒▒░   ░▒░                ░▒░   ░▒▒▒░
                         ▒▒░   ░░              ░░   ░▒▒
                           ▒▒▒  ▒▒░          ░▒▒  ▒▒▒
                             ░░░░░░░        ░░░░░░░
                                  ░░░░░░░░░░░░
PANDA_BOTTOM
    printf '%s\n' "$RESET"
}

frame_start() {
    clear_screen
    panda_top
}

frame_end() {
    panda_bottom
    printf '\n'
}

show_main_menu() {
    frame_start
    panda_row "$CYAN$BOLD" " UBUNTU HELPER v$VERSION"
    panda_row "$WHITE" ''
    panda_row "$WHITE" '[1] Update and upgrade Ubuntu'
    panda_row "$WHITE" '[2] Install server utilities'
    panda_row "$WHITE" '[3] AI installs and models'
    panda_row "$WHITE" '[4] System check menus'
    panda_row "$WHITE" ''
    panda_row "$CYAN" '[L] View current log'
    panda_row "$RED" '[Q] Quit'
    panda_row "$WHITE" ''
    panda_row "$DARK_GREY" 'Ubuntu Server setup and checks'
    panda_row "$DARK_GREY" 'Use a normal sudo-enabled account'
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    frame_end
}

tool_status() {
    if have "$1"; then
        printf 'installed'
    else
        printf 'not installed'
    fi
}

show_utilities_menu() {
    frame_start
    panda_row "$CYAN$BOLD" ' INSTALL SERVER UTILITIES'
    panda_row "$WHITE" ''
    panda_row "$WHITE" "[1] sudo      $(tool_status sudo)"
    panda_row "$WHITE" "[2] tmux      $(tool_status tmux)"
    panda_row "$WHITE" "[3] ranger    $(tool_status ranger)"
    panda_row "$WHITE" "[4] btop      $(tool_status btop)"
    panda_row "$WHITE" "[5] fastfetch $(tool_status fastfetch)"
    panda_row "$WHITE" ''
    panda_row "$CYAN" '[B] Back'
    panda_row "$WHITE" ''
    panda_row "$DARK_GREY" 'Select one program to install.'
    panda_row "$DARK_GREY" 'Nothing is installed as a group.'
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    frame_end
}

show_ai_menu() {
    frame_start
    panda_row "$CYAN$BOLD" ' AI INSTALLS AND DOWNLOADS'
    panda_row "$WHITE" ''
    panda_row "$WHITE" '[1] Install Hermes Agent'
    panda_row "$WHITE" '[2] Install or update Ollama'
    panda_row "$WHITE" '[3] Download Qwen models'
    panda_row "$WHITE" '[4] Configure Hermes model'
    panda_row "$WHITE" '[5] Show installed models'
    panda_row "$WHITE" ''
    panda_row "$CYAN" '[B] Back'
    panda_row "$WHITE" ''
    panda_row "$DARK_GREY" 'Models can consume substantial disk'
    panda_row "$DARK_GREY" 'space. Select the size yourself.'
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    frame_end
}

show_qwen_menu() {
    local ram
    ram=$(free -h | awk '/^Mem:/ {print $2}')
    frame_start
    panda_row "$CYAN$BOLD" ' QWEN MODEL DOWNLOADS'
    panda_row "$YELLOW" "Server RAM: $ram"
    panda_row "$WHITE" ''
    panda_row "$WHITE" '[1] qwen3:0.6b'
    panda_row "$WHITE" '[2] qwen3:1.7b'
    panda_row "$WHITE" '[3] qwen3:4b'
    panda_row "$WHITE" '[4] qwen3:8b'
    panda_row "$WHITE" '[5] qwen3:14b'
    panda_row "$WHITE" '[6] qwen3:30b-a3b'
    panda_row "$WHITE" '[7] qwen3.5:27b'
    panda_row "$WHITE" ''
    panda_row "$CYAN" '[B] Back'
    panda_row "$WHITE" ''
    panda_row "$DARK_GREY" 'Smaller models need fewer resources.'
    panda_row "$DARK_GREY" 'A download can be removed later with:'
    panda_row "$DARK_GREY" 'ollama rm MODEL_NAME'
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    frame_end
}

show_checks_menu() {
    frame_start
    panda_row "$CYAN$BOLD" ' SYSTEM CHECKS'
    panda_row "$WHITE" ''
    panda_row "$WHITE" '[1] Hardware overview'
    panda_row "$WHITE" '[2] Failed system services'
    panda_row "$WHITE" '[3] Errors from current boot'
    panda_row "$WHITE" '[4] Kernel hardware errors'
    panda_row "$WHITE" '[5] Storage health'
    panda_row "$WHITE" '[6] Temperatures'
    panda_row "$WHITE" '[7] Network status'
    panda_row "$WHITE" '[8] Create full check report'
    panda_row "$WHITE" ''
    panda_row "$WHITE" '[I] Install diagnostic tools'
    panda_row "$CYAN" '[B] Back'
    panda_row "$WHITE" ''
    panda_row "$DARK_GREY" 'Checks are read-only.'
    panda_row "$DARK_GREY" 'Reports use timestamped filenames.'
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    panda_row "$WHITE" ''
    frame_end
}

update_ubuntu() {
    clear_screen
    printf '%sUbuntu update and upgrade%s\n\n' "$CYAN$BOLD" "$RESET"
    if confirm 'Run apt update and apt upgrade -y?'; then
        run_cmd sudo apt-get update
        run_cmd sudo env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
        printf '\n%sUbuntu update completed.%s\n' "$GREEN" "$RESET"
    fi
    pause
}

install_fastfetch() {
    local arch asset temp_dir package
    if have fastfetch; then
        printf 'fastfetch is already installed.\n'
        return 0
    fi

    if apt-cache show fastfetch 2>/dev/null | grep -q '^Package:'; then
        run_cmd sudo apt-get install -y fastfetch
        return
    fi

    arch=$(dpkg --print-architecture)
    case "$arch" in
        amd64) asset='amd64' ;;
        arm64) asset='aarch64' ;;
        *)
            printf '%sNo supported Fastfetch package mapping for %s.%s\n' \
                "$RED" "$arch" "$RESET"
            return 1
            ;;
    esac

    temp_dir=$(mktemp -d)
    package="$temp_dir/fastfetch.deb"
    if run_cmd curl -fL \
        "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${asset}.deb" \
        -o "$package"; then
        run_cmd sudo apt-get install -y "$package"
    fi
    rm -rf -- "$temp_dir"
}

install_apt_utility() {
    local package=$1 command_name=$2
    clear_screen
    printf '%sInstall %s%s\n\n' "$CYAN$BOLD" "$package" "$RESET"
    if have "$command_name"; then
        printf '%s%s is already installed.%s\n' "$GREEN" "$package" "$RESET"
    elif confirm "Install $package?"; then
        run_cmd sudo apt-get install -y "$package"
    fi
    pause
}

install_fastfetch_option() {
    clear_screen
    printf '%sInstall fastfetch%s\n\n' "$CYAN$BOLD" "$RESET"
    if have fastfetch; then
        printf '%sfastfetch is already installed.%s\n' "$GREEN" "$RESET"
    elif confirm 'Install fastfetch?'; then
        install_fastfetch
    fi
    pause
}

utilities_menu() {
    local choice
    while true; do
        show_utilities_menu
        printf '%sSelect: %s' "$BOLD" "$RESET"
        read -r choice
        case "${choice,,}" in
            1) install_apt_utility 'sudo' 'sudo' ;;
            2) install_apt_utility 'tmux' 'tmux' ;;
            3) install_apt_utility 'ranger' 'ranger' ;;
            4) install_apt_utility 'btop' 'btop' ;;
            5) install_fastfetch_option ;;
            b) return ;;
            *) printf '%sUnknown option.%s\n' "$RED" "$RESET"; sleep 1 ;;
        esac
    done
}

download_and_run_installer() {
    local name=$1 url=$2 temp_file rc=1
    temp_file=$(mktemp)
    printf 'Official source: %s\n' "$url"
    if run_cmd curl -fsSL "$url" -o "$temp_file"; then
        printf '%sDownloaded installer. It will now run as your user.%s\n' \
            "$YELLOW" "$RESET"
        run_cmd bash "$temp_file"
        rc=$?
    fi
    rm -f -- "$temp_file"
    log "$name installer finished with status $rc"
    return "$rc"
}

install_hermes() {
    clear_screen
    printf '%sHermes Agent installation%s\n\n' "$CYAN$BOLD" "$RESET"
    printf 'Hermes will be installed for the current user: %s\n' "$USER"
    if confirm 'Download and run the official Hermes installer?'; then
        run_cmd sudo apt-get install -y curl xz-utils ca-certificates
        download_and_run_installer 'Hermes' \
            'https://hermes-agent.nousresearch.com/install.sh'
        printf '\nReload your shell after installation with:\n'
        printf '%ssource ~/.bashrc%s\n' "$GREEN" "$RESET"
    fi
    pause
}

install_ollama() {
    clear_screen
    printf '%sOllama installation%s\n\n' "$CYAN$BOLD" "$RESET"
    if have ollama; then
        ollama --version 2>/dev/null || true
        printf 'Running the official installer also updates an existing installation.\n'
    fi
    if confirm 'Download and run the official Ollama installer?'; then
        run_cmd sudo apt-get install -y curl ca-certificates
        download_and_run_installer 'Ollama' 'https://ollama.com/install.sh'
        if systemctl list-unit-files ollama.service >/dev/null 2>&1; then
            run_cmd sudo systemctl enable --now ollama
        fi
    fi
    pause
}

ensure_ollama() {
    if ! have ollama; then
        printf '%sOllama is not installed. Install it first.%s\n' "$RED" "$RESET"
        return 1
    fi
    if systemctl list-unit-files ollama.service >/dev/null 2>&1 && \
       ! systemctl is-active --quiet ollama; then
        run_cmd sudo systemctl start ollama || return 1
    fi
    return 0
}

pull_qwen_model() {
    local model=$1
    clear_screen
    printf '%sQwen model download%s\n\n' "$CYAN$BOLD" "$RESET"
    printf 'Selected model: %s%s%s\n' "$YELLOW" "$model" "$RESET"
    if confirm 'Download this model with Ollama?'; then
        ensure_ollama && run_cmd ollama pull "$model"
    fi
    pause
}

qwen_menu() {
    local choice
    while true; do
        show_qwen_menu
        printf '%sSelect: %s' "$BOLD" "$RESET"
        read -r choice
        case "${choice,,}" in
            1) pull_qwen_model 'qwen3:0.6b' ;;
            2) pull_qwen_model 'qwen3:1.7b' ;;
            3) pull_qwen_model 'qwen3:4b' ;;
            4) pull_qwen_model 'qwen3:8b' ;;
            5) pull_qwen_model 'qwen3:14b' ;;
            6) pull_qwen_model 'qwen3:30b-a3b' ;;
            7) pull_qwen_model 'qwen3.5:27b' ;;
            b) return ;;
            *) printf '%sUnknown option.%s\n' "$RED" "$RESET"; sleep 1 ;;
        esac
    done
}

configure_hermes() {
    clear_screen
    if ! have hermes; then
        printf '%sHermes is not available in the current PATH.%s\n' "$RED" "$RESET"
        printf 'If it was just installed, run: source ~/.bashrc\n'
    else
        printf 'For local Ollama choose the custom/local endpoint and use:\n'
        printf '%shttp://127.0.0.1:11434/v1%s\n\n' "$GREEN" "$RESET"
        run_cmd hermes model
    fi
    pause
}

show_models() {
    clear_screen
    ensure_ollama && run_cmd ollama list
    pause
}

ai_menu() {
    local choice
    while true; do
        show_ai_menu
        printf '%sSelect: %s' "$BOLD" "$RESET"
        read -r choice
        case "${choice,,}" in
            1) install_hermes ;;
            2) install_ollama ;;
            3) qwen_menu ;;
            4) configure_hermes ;;
            5) show_models ;;
            b) return ;;
            *) printf '%sUnknown option.%s\n' "$RED" "$RESET"; sleep 1 ;;
        esac
    done
}

hardware_overview() {
    clear_screen
    printf '%sHardware overview%s\n\n' "$CYAN$BOLD" "$RESET"
    if have fastfetch; then
        run_cmd fastfetch
    else
        printf '%sCPU%s\n' "$YELLOW" "$RESET"
        lscpu | sed -n '1,22p'
        printf '\n%sMemory%s\n' "$YELLOW" "$RESET"
        free -h
        printf '\n%sStorage%s\n' "$YELLOW" "$RESET"
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
        printf '\n%sDisk usage%s\n' "$YELLOW" "$RESET"
        df -hT -x tmpfs -x devtmpfs
    fi
    log 'Displayed hardware overview'
    pause
}

failed_services() {
    clear_screen
    printf '%sFailed system services%s\n\n' "$CYAN$BOLD" "$RESET"
    run_cmd systemctl --failed --no-pager
    pause
}

boot_errors() {
    clear_screen
    printf '%sErrors from the current boot%s\n\n' "$CYAN$BOLD" "$RESET"
    run_cmd journalctl -b -p err --no-pager
    pause
}

kernel_errors() {
    clear_screen
    printf '%sKernel hardware errors%s\n\n' "$CYAN$BOLD" "$RESET"
    run_cmd sudo dmesg --level=emerg,alert,crit,err --ctime
    pause
}

storage_health() {
    local device found=0
    clear_screen
    printf '%sStorage health%s\n\n' "$CYAN$BOLD" "$RESET"
    if ! have smartctl; then
        printf '%ssmartctl is not installed. Use option I in System Checks.%s\n' \
            "$RED" "$RESET"
        pause
        return
    fi
    while read -r device _; do
        [[ -n "$device" ]] || continue
        found=1
        printf '\n%s--- %s ---%s\n' "$YELLOW" "$device" "$RESET"
        run_cmd sudo smartctl -H "$device" || true
    done < <(sudo smartctl --scan-open 2>/dev/null)
    (( found == 0 )) && printf 'No SMART-compatible storage device was detected.\n'
    pause
}

temperatures() {
    clear_screen
    printf '%sTemperature sensors%s\n\n' "$CYAN$BOLD" "$RESET"
    if have sensors; then
        run_cmd sensors
    else
        printf '%sThe sensors command is not installed. Use option I first.%s\n' \
            "$RED" "$RESET"
    fi
    pause
}

network_status() {
    clear_screen
    printf '%sNetwork status%s\n\n' "$CYAN$BOLD" "$RESET"
    printf '%sInterfaces%s\n' "$YELLOW" "$RESET"
    ip -brief address
    printf '\n%sRoutes%s\n' "$YELLOW" "$RESET"
    ip route
    printf '\n%sDNS%s\n' "$YELLOW" "$RESET"
    if have resolvectl; then
        resolvectl status
    else
        sed -n '1,120p' /etc/resolv.conf
    fi
    log 'Displayed network status'
    pause
}

install_diagnostic_tools() {
    clear_screen
    printf '%sDiagnostic tool installation%s\n\n' "$CYAN$BOLD" "$RESET"
    printf 'Packages: smartmontools, lm-sensors, pciutils, usbutils, nvme-cli\n\n'
    if confirm 'Install these diagnostic tools?'; then
        run_cmd sudo apt-get update
        run_cmd sudo apt-get install -y \
            smartmontools lm-sensors pciutils usbutils nvme-cli
    fi
    pause
}

full_report() {
    local report_dir report
    report_dir="$HOME/ubuntu-check-reports"
    mkdir -p -- "$report_dir"
    report="$report_dir/report-$(date '+%Y%m%d-%H%M%S').txt"
    clear_screen
    printf '%sFull system report%s\n\n' "$CYAN$BOLD" "$RESET"
    sudo -v || { printf '%sSudo authentication failed.%s\n' "$RED" "$RESET"; pause; return; }

    {
        printf 'UBUNTU SERVER CHECK REPORT\n'
        printf 'Generated: %s\n\n' "$(date --iso-8601=seconds)"
        printf '===== OPERATING SYSTEM =====\n'
        cat /etc/os-release
        printf '\n===== UPTIME =====\n'
        uptime
        printf '\n===== CPU =====\n'
        lscpu
        printf '\n===== MEMORY =====\n'
        free -h
        printf '\n===== STORAGE DEVICES =====\n'
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,SERIAL
        printf '\n===== FILESYSTEM USAGE =====\n'
        df -hT -x tmpfs -x devtmpfs
        printf '\n===== FAILED SERVICES =====\n'
        systemctl --failed --no-pager
        printf '\n===== CURRENT BOOT ERRORS =====\n'
        journalctl -b -p err --no-pager
        printf '\n===== KERNEL ERRORS =====\n'
        sudo dmesg --level=emerg,alert,crit,err --ctime
        printf '\n===== NETWORK =====\n'
        ip -brief address
        ip route
        if have sensors; then
            printf '\n===== TEMPERATURES =====\n'
            sensors
        fi
        if have lspci; then
            printf '\n===== PCI DEVICES =====\n'
            lspci -k
        fi
        if have lsusb; then
            printf '\n===== USB DEVICES =====\n'
            lsusb
        fi
    } > "$report" 2>&1

    log "Created system report: $report"
    printf '%sReport created:%s\n%s\n' "$GREEN" "$RESET" "$report"
    pause
}

checks_menu() {
    local choice
    while true; do
        show_checks_menu
        printf '%sSelect: %s' "$BOLD" "$RESET"
        read -r choice
        case "${choice,,}" in
            1) hardware_overview ;;
            2) failed_services ;;
            3) boot_errors ;;
            4) kernel_errors ;;
            5) storage_health ;;
            6) temperatures ;;
            7) network_status ;;
            8) full_report ;;
            i) install_diagnostic_tools ;;
            b) return ;;
            *) printf '%sUnknown option.%s\n' "$RED" "$RESET"; sleep 1 ;;
        esac
    done
}

view_log() {
    if have less; then
        less "$LOG_FILE"
    else
        sed -n '1,240p' "$LOG_FILE"
        pause
    fi
}

check_platform() {
    if [[ ! -r /etc/os-release ]]; then
        printf '%sCannot identify this operating system.%s\n' "$RED" "$RESET"
        return 1
    fi
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ ${ID:-} != ubuntu ]]; then
        printf '%sThis helper is designed for Ubuntu Server; detected: %s.%s\n' \
            "$YELLOW" "${PRETTY_NAME:-unknown}" "$RESET"
        confirm 'Continue anyway?'
    fi
}

main() {
    local choice
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        printf '%sDo not run this complete helper as root.%s\n' "$RED" "$RESET"
        printf 'Run it as your normal sudo-enabled user.\n'
        exit 1
    fi
    if [[ ! -t 0 ]]; then
        printf 'This helper requires an interactive terminal.\n' >&2
        exit 1
    fi
    check_platform || exit 1
    init_log

    while true; do
        show_main_menu
        printf '%sSelect: %s' "$BOLD" "$RESET"
        read -r choice
        case "${choice,,}" in
            1) update_ubuntu ;;
            2) utilities_menu ;;
            3) ai_menu ;;
            4) checks_menu ;;
            l) view_log ;;
            q)
                log 'Exited normally'
                clear_screen
                printf '%sUbuntu Helper finished.%s\n' "$GREEN" "$RESET"
                exit 0
                ;;
            *) printf '%sUnknown option.%s\n' "$RED" "$RESET"; sleep 1 ;;
        esac
    done
}

main "$@"
