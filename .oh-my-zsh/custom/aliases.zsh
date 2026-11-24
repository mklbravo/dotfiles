# EZA
if command -v eza >/dev/null 2>&1; then
    # TokyoNight Night (truecolor), scoped to eza rather than LS_COLORS.
    # Blue directories, cyan links, green executables, red broken links.
    export EZA_COLORS="di=1;38;2;122;162;247:ln=38;2;125;207;255:ex=38;2;158;206;106:fi=38;2;192;202;245:or=38;2;247;118;142"
    # Muted metadata, purple sizes, and TokyoNight Git status colors.
    EZA_COLORS+=":uu=38;2;115;218;202:un=38;2;115;218;202:uR=38;2;115;218;202:gu=38;2;169;177;214:gn=38;2;169;177;214:gR=38;2;169;177;214:da=38;2;86;95;137:sn=38;2;187;154;247:sb=38;2;187;154;247:xx=38;2;86;95;137"
    EZA_COLORS+=":ur=38;2;125;207;255:uw=38;2;224;175;104:ux=38;2;158;206;106:ue=38;2;158;206;106"
    EZA_COLORS+=":gr=38;2;125;207;255:gw=38;2;224;175;104:gx=38;2;158;206;106:tr=38;2;125;207;255:tw=38;2;224;175;104:tx=38;2;158;206;106"
    EZA_COLORS+=":ga=38;2;158;206;106:gm=38;2;224;175;104:gd=38;2;247;118;142:gv=38;2;187;154;247:gt=38;2;224;175;104:gi=38;2;86;95;137:gc=1;38;2;247;118;142"

    alias l="eza --long --icons --git --group --all"
    alias lt="eza --long --icons --git --group --all --tree --level=2"
fi

# Utils
alias used_ports="lsof -PiTCP -sTCP:LISTEN"
if [[ "$OSTYPE" == darwin* ]]; then
    alias flush_dns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
fi

