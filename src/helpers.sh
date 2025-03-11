_normalize() {
  cat | tr ' .:' '-' | tr '[:upper:]' '[:lower:]'
}

# helper functions
get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value
  option_value=$(tmux show-option -gqv "$option")
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

# Prevents overriding user's options
set_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value
  option_value=$(tmux show-option -gqv "$option")
  if [ -z "$option_value" ]; then
    tmux set-option -g "$option" "$default_value"
  fi
}

attach_to_tmux_session() {
  local session_name
  local window

  session_name="$1"
  window="$2"
  # Attach to session
  # Escape tilde which if it appears by itself, tmux will interpret as a marked target
  # https://github.com/tmux/tmux/blob/master/cmd-find.c#L1024C51-L1024C57
  #
  session_name=$(echo "$session_name" | sed 's/^~$/\\~/')
  # TODO: This should be removed and I should use some kind of test double (mock) for tmux
  if [ -n "$BATS_TEST_TMPDIR" ]; then
    echo "$session_name" >"$BATS_TEST_TMPDIR/attached_session"
    exit 0
  fi
  if [ -z "$TMUX" ]; then
    tmux attach -t "$session_name"
  else
    tmux switch-client -t "$session_name"
  fi

  if [ -n "$window" ]; then
    tmux select-window -t "$session_name:$window"
  fi
}

session_name() {
  if [ "$1" = "--directory" ]; then
    shift
    basename "$@" | _normalize
  elif [ "$1" = "--full-path" ]; then
    shift
    echo "$@" | _normalize | sed 's/\/$//'
  elif [ "$1" = "--short-path" ]; then
    shift
    echo "$(echo "${@%/*}" | sed -r 's;/([^/]{1,2})[^/]*;/\1;g' | _normalize)/$(basename "$@" | _normalize)"
  else
    echo "Wrong argument, you can use --directory, --full-path or --short-path, got $1"
    return 1
  fi
}

log_message() {
  local log_file
  log_file=$(get_tmux_option "@session-wizard-log-file")
  if [ -z "$log_file" ]; then
    return 0
  fi
  local message="$1"
  local timestamp
  local log_entry
  timestamp=$(date +"%Y-%m-%d %H:%M:%s")
  log_entry="${timestamp} ${message}"
  echo "$log_entry" >>"$log_file"
}

HOME_REPLACER=""                                          # default to a noop
TILDE_REPLACER=""                                         # default to a noop
echo "$HOME" | grep -E "^[a-zA-Z0-9\-_/.@]+$" &>/dev/null # chars safe to use in sed
HOME_SED_SAFE=$?
if [ $HOME_SED_SAFE -eq 0 ]; then # $HOME should be safe to use in sed
  HOME_REPLACER="s|^$HOME|~|"
  TILDE_REPLACER="s|^~|$HOME|"
fi

__fzfcmd() {
  [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}
