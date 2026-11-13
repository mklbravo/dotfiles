# Managed symbolic links. Sourced by scripts/dotfiles.

link_matches() {
    local source=$1 destination=$2 target parent
    [ -L "$destination" ] || return 1
    target=$(readlink "$destination")
    case "$target" in
        /*) ;;
        *) target="$(dirname "$destination")/$target" ;;
    esac
    parent=$(cd "$(dirname "$target")" 2>/dev/null && pwd -P) || return 1
    [ "$parent/$(basename "$target")" = "$source" ]
}

inspect_links() {
    local mode=$1 source destination platform target status errors=0
    while IFS=$'\t' read -r source destination platform; do
        case "$source" in ''|'#'*) continue ;; esac
        applies_to_platform "$platform" || continue
        target=$(resolve_destination "$destination")
        if [ ! -e "$ROOT/$source" ]; then
            status='MISSING SOURCE'
            errors=$((errors + 1))
        elif link_matches "$ROOT/$source" "$target"; then
            status=OK
        elif destination_is_in_repository "$target"; then
            status='UNSAFE PARENT'
            errors=$((errors + 1))
        elif [ -e "$target" ] || [ -L "$target" ]; then
            status=CONFLICT
            if [ "$mode" = check ] || ! "$BACKUP"; then
                errors=$((errors + 1))
            fi
        else
            status=MISSING
            if [ "$mode" = check ]; then
                errors=$((errors + 1))
            fi
        fi
        printf '%-14s %s -> %s\n' "$status" "$target" "$ROOT/$source"
    done < "$ROOT/manifests/links.tsv"
    if [ "$mode" = plan ]; then
        return 0
    fi
    [ "$errors" -eq 0 ]
}

install_links() {
    local source destination platform target
    inspect_links preflight || fail 'Link conflicts or missing sources. Use plan; --backup permits replacing conflicts.'
    while IFS=$'\t' read -r source destination platform; do
        case "$source" in ''|'#'*) continue ;; esac
        applies_to_platform "$platform" || continue
        target=$(resolve_destination "$destination")
        link_matches "$ROOT/$source" "$target" && continue
        if [ -e "$target" ] || [ -L "$target" ]; then
            backup_destination "$target" "links/$source"
        fi
        mkdir -p "$(dirname "$target")"
        ln -s "$ROOT/$source" "$target"
        printf 'LINK %s -> %s\n' "$target" "$ROOT/$source"
    done < "$ROOT/manifests/links.tsv"
}
