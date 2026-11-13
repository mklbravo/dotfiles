# Git-managed dependencies. Sourced by scripts/dotfiles.

repository_matches() {
    local destination=$1 url=$2 origin
    [ ! -L "$destination" ] && [ -d "$destination/.git" ] || return 1
    origin=$(git -C "$destination" remote get-url origin 2>/dev/null) || return 1
    case "$origin" in
        git@github.com:*) origin="https://github.com/${origin#git@github.com:}" ;;
    esac
    [ "${origin%.git}" = "${url%.git}" ]
}

plan_repositories() {
    local name url destination platform target
    while IFS=$'\t' read -r name url destination platform; do
        case "$name" in ''|'#'*) continue ;; esac
        applies_to_platform "$platform" || continue
        target=$(resolve_destination "$destination")
        printf '  %s: %s -> %s\n' "$name" "$url" "$target"
    done < "$ROOT/manifests/repositories.tsv"
}

inspect_repositories() {
    local name url destination platform target errors=0
    command -v git >/dev/null 2>&1 || fail 'Install Git before managing repositories.'
    while IFS=$'\t' read -r name url destination platform; do
        case "$name" in ''|'#'*) continue ;; esac
        applies_to_platform "$platform" || continue
        target=$(resolve_destination "$destination")
        if destination_is_in_repository "$target"; then
            fail "Unsafe repository destination inside dotfiles: $target"
        fi
        if [ -e "$target" ] || [ -L "$target" ]; then
            if ! repository_matches "$target" "$url"; then
                printf 'REPOSITORY CONFLICT %s (expected %s)\n' "$target" "$url" >&2
                if ! "$BACKUP"; then
                    errors=$((errors + 1))
                fi
            fi
        fi
    done < "$ROOT/manifests/repositories.tsv"
    [ "$errors" -eq 0 ] || fail 'Repository conflicts. Move destinations manually or use --backup.'
}

install_repositories() {
    local name url destination platform target
    inspect_repositories
    while IFS=$'\t' read -r name url destination platform; do
        case "$name" in ''|'#'*) continue ;; esac
        applies_to_platform "$platform" || continue
        target=$(resolve_destination "$destination")
        if repository_matches "$target" "$url"; then
            printf 'PRESENT %s\n' "$target"
            continue
        fi
        if [ -e "$target" ] || [ -L "$target" ]; then
            backup_destination "$target" "repositories/$name"
        fi
        mkdir -p "$(dirname "$target")"
        git clone "$url" "$target"
    done < "$ROOT/manifests/repositories.tsv"
}

update_repositories() {
    local name url destination platform target
    inspect_repositories
    # Preflight every checkout before fetching anything.
    while IFS=$'\t' read -r name url destination platform; do
        case "$name" in ''|'#'*) continue ;; esac
        applies_to_platform "$platform" || continue
        target=$(resolve_destination "$destination")
        repository_matches "$target" "$url" || fail "Missing repository: $target; run repositories first."
        [ -z "$(git -C "$target" status --porcelain)" ] || fail "Dirty repository: $target"
        git -C "$target" symbolic-ref -q HEAD >/dev/null || fail "Detached HEAD: $target"
    done < "$ROOT/manifests/repositories.tsv"
    while IFS=$'\t' read -r name url destination platform; do
        case "$name" in ''|'#'*) continue ;; esac
        applies_to_platform "$platform" || continue
        target=$(resolve_destination "$destination")
        git -C "$target" pull --ff-only
    done < "$ROOT/manifests/repositories.tsv"
}
