# .bashrc - Bash Configuration
# Part of my_linux_config ecosystem
# https://github.com/wuyufffan/bashrc-config

# ==============================================================================
# 🎨 ANSI Color Definitions
# ==============================================================================
export RESET='\033[0m'
export BOLD='\033[1m'

export RED='\033[1;31m'
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[1;34m'
export GREY='\033[0;37m'
export PURPLE='\033[1;35m'
export CYAN='\033[1;36m'

# ==============================================================================
# 🕒 Time Functions
# ==============================================================================
export TIME_STYLE_COLOR="${GREY}"

function now() {
    echo -e "${TIME_STYLE_COLOR}[$(date +'%H:%M:%S')]${RESET}"
}

function timestamp() {
    echo -e "${TIME_STYLE_COLOR}[$(date +'%Y-%m-%d %H:%M:%S')]${RESET}"
}

# ==============================================================================
# 1. Source Global Definitions
# ==============================================================================
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# ==============================================================================
# 2. Node Info
# ==============================================================================
HOST_NAME=$(hostname)
echo -e "🖥️  At node: ${BLUE}${HOST_NAME}${RESET} $(timestamp)"

# ==============================================================================
# 3. Optional: Source component configurations
# Components should install their own initialization scripts to:
# ~/.config/my_linux_config/components/
# ==============================================================================
COMPONENTS_DIR="${HOME}/.config/my_linux_config/components"
if [ -d "${COMPONENTS_DIR}" ]; then
    for script in "${COMPONENTS_DIR}"/*.sh; do
        [ -f "$script" ] && source "$script"
    done
fi

# ==============================================================================
# 4. Aliases
# ==============================================================================
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias c='clear'
alias h='history'
alias bashrc='source ~/.bashrc && echo "✅ bashrc reloaded! $(timestamp)"'
alias ll='ls -alF --color=auto'
alias ls='ls --color=auto'
alias tree='tree -C'

# ==============================================================================
# 5. Welcome Message
# ==============================================================================
echo -e "${GREEN}✅ Bash configuration loaded${RESET}"
