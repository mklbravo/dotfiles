# Shared shell configuration for macOS and Linux.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$XDG_CONFIG_HOME/zsh/custom"

# Homebrew can live in different prefixes on Intel and Apple Silicon Macs.
if [[ "$OSTYPE" == darwin* ]] && ! command -v brew >/dev/null 2>&1; then
    for brew_binary in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$brew_binary" ]]; then
            eval "$("$brew_binary" shellenv)"
            break
        fi
    done
    unset brew_binary
fi

typeset -U path
path=("$HOME/.local/bin" $path)
[[ ! -d /usr/local/sbin ]] || path=(/usr/local/sbin $path)
[[ ! -d "$HOME/.rvm/bin" ]] || path+=("$HOME/.rvm/bin")
export PATH

if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
else
    export EDITOR=vi
fi

plugins=(git vi-mode)
command -v docker >/dev/null 2>&1 && plugins+=(docker docker-compose)
command -v tmux >/dev/null 2>&1 && plugins+=(tmux)
command -v tmuxinator >/dev/null 2>&1 && plugins+=(tmuxinator)
[[ ! -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]] || plugins+=(zsh-autosuggestions)
[[ ! -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh" ]] || plugins+=(zsh-syntax-highlighting)

# Dependency updates are explicit through the dotfiles installer.
zstyle ':omz:update' mode disabled
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    for custom_file in "$ZSH_CUSTOM/aliases.zsh" "$ZSH_CUSTOM/functions.zsh"; do
        [[ ! -r "$custom_file" ]] || source "$custom_file"
    done
    unset custom_file
fi

# Older distribution packages do not support `fzf --zsh`.
if command -v fzf >/dev/null 2>&1; then
    if fzf_init=$(fzf --zsh 2>/dev/null); then
        eval "$fzf_init"
    else
        fzf_directory=
        for candidate in /usr/share/doc/fzf/examples /usr/share/fzf /usr/share/fzf/shell; do
            if [[ -r "$candidate/key-bindings.zsh" ]]; then
                fzf_directory="$candidate"
                break
            fi
        done
        if [[ -z "$fzf_directory" ]] && command -v brew >/dev/null 2>&1; then
            fzf_directory="$(brew --prefix)/opt/fzf/shell"
        fi
        if [[ -n "$fzf_directory" ]]; then
            [[ ! -r "$fzf_directory/key-bindings.zsh" ]] || source "$fzf_directory/key-bindings.zsh"
            [[ ! -r "$fzf_directory/completion.zsh" ]] || source "$fzf_directory/completion.zsh"
        fi
        unset fzf_directory candidate
    fi
    unset fzf_init
fi

export NVM_DIR="$HOME/.nvm"
if [[ -r "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
elif command -v brew >/dev/null 2>&1; then
    nvm_script="$(brew --prefix)/opt/nvm/nvm.sh"
    [[ ! -r "$nvm_script" ]] || source "$nvm_script"
    unset nvm_script
fi

command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# Machine-specific settings are deliberately not managed by this repository.
[[ ! -r "$XDG_CONFIG_HOME/zsh/local.zsh" ]] || source "$XDG_CONFIG_HOME/zsh/local.zsh"
