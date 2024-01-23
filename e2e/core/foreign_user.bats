#!/usr/bin/env bats

source 'e2e/helpers/_common.bash'
source 'e2e/helpers/auth.bash'

KRATOS_ADMIN_URL="http://localhost:4434"
password="123@WordPass"
firstName="Alice"
lastName="Jackson"

@test "create alice identity via admin" {
    email="alice-$RANDOM@example.com"
    cache_value "email" $email

    variables=$(
        jq -n \
        --arg schema_id "v0" \
        --arg email "$email" \
        --arg firstName "" \
        --arg lastName "" \
        '{schema_id: $schema_id, traits: {email: $email, name: { first: $firstName, last: $lastName }}}'
    )

    ${run_cmd} curl -s \
        -X POST \
        -H "Accept: application/json" -H "Content-Type: application/json" \
        -d "$variables" \
        "${KRATOS_ADMIN_URL}/admin/identities"

    id=$(echo $output | jq -r '.id')
    [[ $id != "null" ]] || exit 1
    cache_value "alice_id" $id
}

@test "alice registers herself - verify whoami returns the same identity id" {
    ${run_cmd} curl -s -X GET "${OATHKEEPER_PROXY}/auth/self-service/registration/api"
    flowId=$(echo $output | jq -r '.id')

    email=$(read_value "email")

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"traits.email\": \"$email\", \"password\": \"$password\", \"traits.name.first\": \"$firstName\", \"traits.name.last\": \"$lastName\", \"method\": \"password\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/registration?flow=$flowId"
    
    echo $output | jq

    verificationFlowId=$(echo $output | jq -r '.continue_with.[].flow.id')
    [[ $verificationFlowId != "" ]] || exit 1

    try_login $email $password
    code=$(get_kratos_code $email)

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$email\", \"code\": \"$code\", \"method\": \"code\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/verification?flow=$verificationFlowId"

    try_login $email $password
    session_token=$(echo $output | jq -r '.session_token')
    [[ $session_token != "null" ]] || exit 1

    ${run_cmd} curl -s \
        -X GET \
        -H "X-Session-Token: $session_token" -H "Accept: application/json" \
        "${OATHKEEPER_PROXY}/auth/sessions/whoami"

    [[ $(echo $output | jq -r '.identity.traits.name.first') == "$firstName" ]] || exit 1
    [[ $(echo $output | jq -r '.identity.traits.name.last') == "$lastName" ]] || exit 1

    user_id=$(echo $output | jq -r '.identity.id')

    echo $user_id
    exit 1
}
