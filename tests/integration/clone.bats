# bats file_tags=integration
setup() {
  load ./lib/bats.bash
  _common_setup
}

teardown() {
  _common_teardown
}

@test "Clone session should create new session with same prefix and number" {
  mkdir -p "$TEST_DIR/dir"
  run t "$TEST_DIR/dir"
  assert_tmux_sessions_number 1
  assert_tmux_session_attached "dir"
  run t --clone "$TEST_DIR/dir"
  assert_tmux_sessions_number 2
  assert_tmux_session_exists "dir"
  # NOTE: Assertion that it will be "-2" is a little weak
  assert_tmux_session_exists "dir-2"
  assert_tmux_session_attached "dir-2"
}
