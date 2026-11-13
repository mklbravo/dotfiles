# Native package managers. Sourced by scripts/dotfiles.

require_package_manager() {
    command -v "$MANAGER" >/dev/null 2>&1 || fail "Install $MANAGER first; package managers are never bootstrapped automatically."
}

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        command -v sudo >/dev/null 2>&1 || fail 'sudo is required to install system packages.'
        sudo "$@"
    fi
}

package_installed() {
    case "$MANAGER" in
        brew) brew list --formula "$1" >/dev/null 2>&1 ;;
        apt) [ "$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null)" = 'install ok installed' ] ;;
        pacman) pacman -Q "$1" >/dev/null 2>&1 ;;
    esac
}

package_available() {
    case "$MANAGER" in
        brew) brew info --formula "$1" >/dev/null 2>&1 ;;
        apt) apt-cache policy "$1" | grep 'Candidate:' | grep -qv '(none)' ;;
        pacman) pacman -Si "$1" >/dev/null 2>&1 ;;
    esac
}

install_packages() {
    local package unavailable=0 pending_count=0
    local pending=()
    require_package_manager
    while IFS= read -r package || [ -n "$package" ]; do
        case "$package" in ''|'#'*) continue ;; esac
        if package_installed "$package"; then
            printf 'INSTALLED %s\n' "$package"
        elif package_available "$package"; then
            pending+=("$package")
            pending_count=$((pending_count + 1))
        else
            printf 'UNAVAILABLE %s (%s); enable a trusted source or install manually.\n' "$package" "$MANAGER" >&2
            unavailable=$((unavailable + 1))
        fi
    done < "$ROOT/manifests/packages/$MANAGER.txt"
    if [ "$pending_count" -gt 0 ]; then
        case "$MANAGER" in
            brew) HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 brew install --formula "${pending[@]}" ;;
            apt) run_privileged apt-get install --no-upgrade "${pending[@]}" ;;
            # Use the existing sync database: never create a partial upgrade with -Sy.
            pacman) run_privileged pacman -S --needed "${pending[@]}" ;;
        esac
    fi
    if [ "$unavailable" -gt 0 ]; then
        printf 'Warning: %s package(s) unavailable. Other installation steps can continue.\n' "$unavailable" >&2
    fi
}

install_casks() {
    local package
    [ "$PLATFORM" = macos ] || fail 'Casks are only supported on macOS.'
    require_package_manager
    while IFS= read -r package || [ -n "$package" ]; do
        case "$package" in ''|'#'*) continue ;; esac
        if brew list --cask "$package" >/dev/null 2>&1; then
            printf 'INSTALLED %s\n' "$package"
        else
            HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 brew install --cask "$package"
        fi
    done < "$ROOT/manifests/packages/macos-casks.txt"
}
