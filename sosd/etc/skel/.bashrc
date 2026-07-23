# Starlight OS default interactive Bash configuration.

case $- in
    *i*) ;;
    *) return ;;
esac

export OSH=${OSH:-/usr/share/oh-my-bash}
OSH_THEME=${STARLIGHT_OMB_THEME:-agnoster}
plugins=(git sudo bashmarks colored-man-pages)
aliases=(general)

if [[ -s "${OSH}/oh-my-bash.sh" ]]; then
    # shellcheck source=/dev/null
    source "${OSH}/oh-my-bash.sh"
elif command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

if [[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.sdkman/bin/sdkman-init.sh"
fi
