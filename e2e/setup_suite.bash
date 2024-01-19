#!/bin/bash

export REPO_ROOT=$(git rev-parse --show-toplevel)
source "${REPO_ROOT}/e2e/helpers/_common.bash"

TILT_PID_FILE=$REPO_ROOT/e2e/.tilt_pid

setup_suite() {
  background buck2 run //dev:up > "${REPO_ROOT}/e2e/.e2e-tilt.log"
  echo $! > "$TILT_PID_FILE"
  await_stack_is_up
  await_api_is_up
}

teardown_suite() {
  if [[ -f "$TILT_PID_FILE" ]]; then
    kill "$(cat "$TILT_PID_FILE")" > /dev/null || true
  fi

  buck2 run //dev:down
}

await_api_is_up() {
  server_is_up() {
    exec_graphql 'anon' 'globals'
    version="$(graphql_output '.data.globals.version')"
    [[ "${version}" = "0.0.0-development" ]] || exit 1
  }

  retry 300 1 server_is_up
}

await_stack_is_up() {
  stack_up() {
    tilt wait --timeout 1h --for=condition=Ready uiresources oathkeeper
    tilt wait --timeout 1h --for=condition=Ready uiresources api
    tilt wait --timeout 1h --for=condition=Ready uiresources kratos
  }

  retry 300 1 stack_up
}
