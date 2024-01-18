#!/usr/bin/env bats

source 'e2e/helpers/_common.bash'
source 'e2e/helpers/kratos.bash'

password="123@WordPass"
firstName="Jackie"
lastName="Chan"

@test "register an user" {
    email="test-$RANDOM@example.com"
    cache_value "email" $email

    ${run_cmd} curl -s -X GET "${OATHKEEPER_PROXY}/auth/self-service/registration/api"
    flowId=$(echo $output | jq -r '.id')

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"traits.email\": \"$email\", \"password\": \"$password\", \"traits.name.first\": \"$firstName\", \"traits.name.last\": \"$lastName\", \"method\": \"password\"}" \
        "http://localhost:4002/auth/self-service/registration?flow=$flowId"

    verificationFlowId=$(echo $output | jq -r '.continue_with.[].flow.id')

    [[ $verificationFlowId != "" ]] || exit 1
    cache_value "verificationFlowId" $verificationFlowId
}

@test "can't login unverified user" {
    ${run_cmd} curl -s -X GET "${OATHKEEPER_PROXY}/auth/self-service/login/api"
    flowId=$(echo $output | jq -r '.id')

    email=$(read_value "email")

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"identifier\": \"$email\", \"password\": \"$password\", \"method\": \"password\"}" \
        "http://localhost:4002/auth/self-service/login?flow=$flowId"

    # Account not active yet. Did you forget to verify your email address?
    [[ $(echo $output | jq -r '.ui.messages.[].id') == "4000010" ]] || exit 1
}

@test "verify user" {
    email=$(read_value "email")
    verificationFlowId=$(read_value "verificationFlowId")
    code=$(get_kratos_code $email)

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$email\", \"code\": \"$code\", \"method\": \"code\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/verification?flow=$verificationFlowId"
}

@test "login verified user" {
    ${run_cmd} curl -s -X GET "${OATHKEEPER_PROXY}/auth/self-service/login/api"
    flowId=$(echo $output | jq -r '.id')

    email=$(read_value "email")

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"identifier\": \"$email\", \"password\": \"$password\", \"method\": \"password\"}" \
        "http://localhost:4002/auth/self-service/login?flow=$flowId"

    [[ $(echo $output | jq -r '.session_token') != "" ]] || exit 1
}
