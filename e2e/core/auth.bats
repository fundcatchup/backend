#!/usr/bin/env bats

source 'e2e/helpers/_common.bash'

emailId="email-$RANDOM@example.com"
password="testing123$RANDOM"
firstName="firstName$RANDOM"
lastName="lastName$RANDOM"

@test "register an user" {
    ${run_cmd} curl -s -X GET "http://localhost:4002/auth/self-service/registration/api"
    flowId=$(echo $output | jq -r '.id')

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"traits.email\": \"$emailId\", \"password\": \"$password\", \"traits.name.first\": \"$firstName\", \"traits.name.last\": \"$lastName\", \"method\": \"password\"}" \
        "http://localhost:4002/auth/self-service/registration?flow=$flowId"

    echo $output | jq
    exit 1
}
