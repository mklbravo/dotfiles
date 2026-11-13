# ------------------------------------------------------------------------------------------
# GUM Wrappers
# ------------------------------------------------------------------------------------------
# Wrapper for gum filter with custom options
gum_filter() {
    printf '%s\n' "$1" | gum filter \
        --indicator "" \
        --placeholder "Select..." \
        --prompt "󰅬 " \
        --sort
}

# ------------------------------------------------------------------------------------------
# SSH
# ------------------------------------------------------------------------------------------
# --------------------
# Copies public ssh key to the selected host
sshc() {
    local CONFIGURED_HOSTS=$(awk '/^Host / {print $2}' "${HOME}/.ssh/config")
    local SELECTED_HOST=$(gum_filter "${CONFIGURED_HOSTS}")

    if [ -z "$SELECTED_HOST" ]; then
        echo "No host selected."
        return 1
    fi

    ssh-copy-id ${SELECTED_HOST}
}

# ------------------------------------------------------------------------------------------
# TMUX
# ------------------------------------------------------------------------------------------
# Select tmux session
tmuxs() {
  local RUNNING_SESSIONS=$(tmux list-sessions -F \#S)

  if [ -z "$RUNNING_SESSIONS" ]; then
    echo "No running tmux sessions"
    return 0
  fi

  local SELECTED_SESSION=$(gum_filter "${RUNNING_SESSIONS}")

  if [ -z "$SELECTED_SESSION" ]; then
    echo "No session selected."
    return 0
  fi

  tmux attach -t "${SELECTED_SESSION}"
}

# ------------------------------------------------------------------------------------------
# BREW
# ------------------------------------------------------------------------------------------
brewup() {
    if ! command -v brew >/dev/null 2>&1 || ! command -v gum >/dev/null 2>&1; then
        echo "brewup requires Homebrew and gum." >&2
        return 1
    fi
    local SPINNER_FOREGROUND="#74c7ec"
    gum spin --title "Updating brew..." --spinner.foreground="${SPINNER_FOREGROUND}" --show-error -- \
        brew update
    gum spin --title "Updating brew packages..." --spinner.foreground="${SPINNER_FOREGROUND}" --show-error -- \
        brew upgrade --yes
    gum spin --title "Autoremoving brew packages..." --spinner.foreground="${SPINNER_FOREGROUND}" --show-error -- \
        brew autoremove
    gum spin --title "Cleaning up brew..." --spinner.foreground="${SPINNER_FOREGROUND}" --show-error -- \
        brew cleanup
}

# ------------------------------------------------------------------------------------------
# Project Helpers
# ------------------------------------------------------------------------------------------
cdd() {
    local base_dir="${HOME}/Development"
    local repositories selected_dir

    if [[ ! -d "$base_dir" ]]; then
        echo "Directory not found: $base_dir"
        return 1
    fi

    repositories=$(find "$base_dir" \
        \( -type d \( -name node_modules -o -name vendor -o -name .venv -o -name venv \
            -o -name dist -o -name build -o -name .next -o -name .cache \) -prune \) \
        -o \( -name .git -prune -exec dirname {} \; \))
    if [[ -z "$repositories" ]]; then
        echo "No Git repositories found in $base_dir"
        return 0
    fi

    selected_dir=$(gum_filter "$repositories") || return 0
    [[ -n "$selected_dir" ]] || return 0

    cd -- "$selected_dir"
}
