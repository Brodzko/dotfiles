# chalk.zsh — Composable ANSI color and style utilities for zsh

typeset -A ANSI_COLORS=(
  black $'\e[30m'
  red $'\e[31m'
  green $'\e[32m'
  yellow $'\e[33m'
  blue $'\e[34m'
  magenta $'\e[35m'
  cyan $'\e[36m'
  white $'\e[37m'
  bright_black $'\e[90m'
  bright_red $'\e[91m'
  bright_green $'\e[92m'
  bright_yellow $'\e[93m'
  bright_blue $'\e[94m'
  bright_magenta $'\e[95m'
  bright_cyan $'\e[96m'
  bright_white $'\e[97m'
)

typeset -A ANSI_BG_COLORS=(
  bg_black $'\e[40m'
  bg_red $'\e[41m'
  bg_green $'\e[42m'
  bg_yellow $'\e[43m'
  bg_blue $'\e[44m'
  bg_magenta $'\e[45m'
  bg_cyan $'\e[46m'
  bg_white $'\e[47m'
  bg_bright_black $'\e[100m'
  bg_bright_red $'\e[101m'
  bg_bright_green $'\e[102m'
  bg_bright_yellow $'\e[103m'
  bg_bright_blue $'\e[104m'
  bg_bright_magenta $'\e[105m'
  bg_bright_cyan $'\e[106m'
  bg_bright_white $'\e[107m'
)

typeset -A ANSI_STYLES=(
  bold $'\e[1m'
  dim $'\e[2m'
  italic $'\e[3m'
  underline $'\e[4m'
  blink $'\e[5m'
  rapid_blink $'\e[6m'
  reverse $'\e[7m'
  hidden $'\e[8m'
  strikethrough $'\e[9m'
  underline_double $'\e[21m'
)

RESET=$'\e[0m'


# Compose and apply styles/colors
# Usage: chalk_apply style1 style2 ... styleN "text"
chalk() {
  local end=$(( $# - 1 ))
  local styles=("${(@)argv[1,$end]}")
  local text="${(@)argv[-1]}"

  local codes=""
  for style in "${styles[@]}"; do
    if [[ -n ${ANSI_COLORS[$style]} ]]; then
      codes+="${ANSI_COLORS[$style]}"
    elif [[ -n ${ANSI_BG_COLORS[$style]} ]]; then
      codes+="${ANSI_BG_COLORS[$style]}"
    elif [[ -n ${ANSI_STYLES[$style]} ]]; then
      codes+="${ANSI_STYLES[$style]}"
    else
      echo "Warning: Unknown style/color '$style'" >&2
    fi
  done

  echo -e "${codes}${text}${RESET}"
}

chalk_test() {
  echo "=== Foreground Colors ==="
  for name color in ${(kv)ANSI_COLORS}; do
    echo "$(chalk $name "$name")"
  done

  echo "\n=== Background Colors ==="
  for name color in ${(kv)ANSI_BG_COLORS}; do
    echo "$(chalk $name "$name")"
  done

  echo "\n=== Text Styles ==="
  for name style in ${(kv)ANSI_STYLES}; do
    echo "$(chalk $name "$name")"
  done

  echo "\n=== Combo Examples ==="
  echo "$(chalk bold italic red bg_yellow "Bold + Italic + Red + Yellow BG")"
  echo "$(chalk underline bright_cyan bg_bright_black "Underline + Bright Cyan + Bright Black BG")"
  echo "$(chalk reverse strikethrough bright_green "Reverse + Strikethrough + Bright Green")"
  echo "$(chalk blink dim magenta "Blink + Dim + Magenta")"
  echo "$(chalk underline_double bright_yellow "Double Underline + Bright Yellow")"
}

