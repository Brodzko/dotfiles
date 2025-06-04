# Human readable date difference
date_diff() {
  local input_date="$1"

  # Normalize ISO8601 string: strip milliseconds and convert Z to +0000
  input_date=$(echo "$input_date" | sed -E 's/\.[0-9]+Z$/+0000/; s/Z$/+0000/')

  # Use gdate on macOS if available, otherwise date
  local date_cmd
  if command -v gdate >/dev/null 2>&1; then
    date_cmd=gdate
  else
    date_cmd=date
  fi

  local now_sec=$($date_cmd +%s)
  local input_sec=$($date_cmd -d "$input_date" +%s 2>/dev/null)

  if [[ -z "$input_sec" ]]; then
    echo "Invalid date"
    return 1
  fi

  local diff=$((now_sec - input_sec))

  if ((diff < 0)); then
    echo "in the future"
    return 0
  fi

  if ((diff < 60)); then
    echo "just now"
  elif ((diff < 3600)); then
    local minutes=$((diff / 60))
    echo "$minutes $([[ $minutes -gt 1 ]] && echo "minutes" || echo "minute") ago"
  elif ((diff < 86400)); then
    local hours=$((diff / 3600))
    echo "$hours $([[ $hours -gt 1 ]] && echo "hours" || echo "hour") ago"
  elif ((diff < 172800)); then
    echo "yesterday"
  elif ((diff < 604800)); then
    local days=$((diff / 86400))
    echo "$days $([[ $days -gt 1 ]] && echo "days" || echo "day") ago"
  else
    local weeks=$((diff / 604800))
    echo "$weeks $([[ $weeks -gt 1 ]] && echo "weeks" || echo "week") ago"
  fi
}

trunc() {
  local str="$1"
  local n="$2"
  local len=${#str}
  local cutoff=$((n - 1))

  if ((len > n)); then
    printf '%s…' "${str:0:$cutoff}"
  else
    printf '%s' "$str"
  fi
}

lpad() {
  local str="$1"
  local n="$2"
  printf '%-*s' "$n" "$str"
}

rpad() {
  local str="$1"
  local n="$2"
  printf '%*s' "$n" "$str"
}

# Fixed lenth string
fix_length() {
  local str="$1"
  local n="$2"

  local len=${#str}

  local cutoff=$((n - 1))

  if ((len > n)); then
    # Cut string to n-1 characters, add ellipsis (1 char)
    # Using substring expansion; ellipsis is one character
    printf '%s…' "${str:0:$cutoff}"
  elif ((len < n)); then
    # Pad with spaces to the right
    printf '%-*s' "$n" "$str"
  else
    # Exactly n chars, print as is
    printf '%s' "$str"
  fi
}
