#!/usr/bin/env bats

source 'e2e/helpers/_common.bash'

@test "register an user" {
    curl "http://localhost:4002/auth/self-service/registration/api"
    echo $output
    exit 1
}
