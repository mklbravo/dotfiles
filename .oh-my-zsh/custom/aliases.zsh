# EZA
if command -v eza >/dev/null 2>&1; then
    alias l="eza --long --icons --git --group --all"
    alias lt="eza --long --icons --git --group --all --tree --level=2"
fi

# Utils
alias used_ports="lsof -PiTCP -sTCP:LISTEN"
if [[ "$OSTYPE" == darwin* ]]; then
    alias flush_dns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
fi

