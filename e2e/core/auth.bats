#!/usr/bin/env bats

source 'e2e/helpers/_common.bash'
source 'e2e/helpers/kratos.bash'

password="123@WordPass"
firstName="Jackie"
lastName="Chan"

COOKIE_FILE=$CACHE_DIR/cookie.txt

setup_file() {
    rm $COOKIE_FILE || true
}

try_login() {
    ${run_cmd} curl -s -X GET "${OATHKEEPER_PROXY}/auth/self-service/login/api"
    flowId=$(echo $output | jq -r '.id')

    email=$(read_value "email")

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"identifier\": \"$email\", \"password\": \"$1\", \"method\": \"password\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/login?flow=$flowId"
}

@test "register: new user" {
    email="test-$RANDOM@example.com"
    cache_value "email" $email

    ${run_cmd} curl -s -X GET "${OATHKEEPER_PROXY}/auth/self-service/registration/api"
    flowId=$(echo $output | jq -r '.id')

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"traits.email\": \"$email\", \"password\": \"$password\", \"traits.name.first\": \"$firstName\", \"traits.name.last\": \"$lastName\", \"method\": \"password\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/registration?flow=$flowId"

    verificationFlowId=$(echo $output | jq -r '.continue_with.[].flow.id')

    [[ $verificationFlowId != "" ]] || exit 1
    cache_value "verificationFlowId" $verificationFlowId
}

@test "login: can't login unverified user" {
    try_login $password

    # Account not active yet. Did you forget to verify your email address?
    [[ $(echo $output | jq -r '.ui.messages.[].id') == "4000010" ]] || exit 1
}

@test "verify: email of user" {
    email=$(read_value "email")
    verificationFlowId=$(read_value "verificationFlowId")

    code=$(get_kratos_code $email)

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$email\", \"code\": \"$code\", \"method\": \"code\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/verification?flow=$verificationFlowId"
}

@test "login: verified user" {
    try_login $password
    [[ $(echo $output | jq -r '.session_token') != "null" ]] || exit 1
}

@test "recover: using email" {
    ${run_cmd} curl -s -X GET "${OATHKEEPER_PROXY}/auth/self-service/recovery/api"
    flowId=$(echo $output | jq -r '.id')

    email=$(read_value "email")

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$email\", \"method\": \"code\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/recovery?flow=$flowId"

    code=$(get_kratos_code $email)

    ${run_cmd} curl -s -b $COOKIE_FILE -c $COOKIE_FILE \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"code\": \"$code\", \"method\": \"code\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/recovery?flow=$flowId"

    session_token=$(cat $COOKIE_FILE | grep -oP 'ory_kratos_session\s+\K[^\s]+')
    [[ $session_token != "" ]] || exit 1
}

newPassword="1234@WordPass"
@test "recover + settings: set new password via browser" {
    ${run_cmd} curl -s -b $COOKIE_FILE -c $COOKIE_FILE -H "Accept: application/json" -X GET "${OATHKEEPER_PROXY}/auth/self-service/settings/browser"

    flowId=$(echo $output | jq -r '.id')
    csrfToken=$(echo $output | jq -r '.ui.nodes[] | select(.attributes.name=="csrf_token") | .attributes.value')

    ${run_cmd} curl -s -b $COOKIE_FILE -c $COOKIE_FILE -H "Accept: application/json" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"password\": \"$newPassword\", \"method\": \"password\", \"csrf_token\": \"$csrfToken\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/settings?flow=$flowId"

    [[ $(echo $output | jq -r '.state') == "success" ]] || exit 1
}

@test "login: should fail with old password" {
    try_login $password
    [[ $(echo $output | jq -r '.session_token') == "null" ]] || exit 1
}

@test "login: should succeed with new password" {
    try_login $newPassword

    session_token=$(echo $output | jq -r '.session_token')
    [[ $session_token != "null" ]] || exit 1

    cache_value "session_token" $session_token
}

@test "whoami" {
    session_token=$(read_value "session_token")

    ${run_cmd} curl -s \
        -X GET \
        -H "X-Session-Token: $session_token" -H "Accept: application/json" \
        "${OATHKEEPER_PROXY}/auth/sessions/whoami"

    [[ $(echo $output | jq -r '.identity.traits.name.first') == "$firstName" ]] || exit 1
    [[ $(echo $output | jq -r '.identity.traits.name.last') == "$lastName" ]] || exit 1

    user_id=$(echo $output | jq -r '.identity.id')
    [[ $user_id != "" ]] || exit 1
    cache_value "user_id" $user_id
}

@test "authenticated graphql: test flow between oathkeeper (<> kratos) <> application" {
    exec_graphql "session_token" "whoami"

    user_id_from_whoami_gql=$(graphql_output | jq -r '.data.whoami')
    user_id_from_cache=$(read_value "user_id")

    [[ $user_id_from_whoami_gql == $user_id_from_cache ]] || exit 1
}

@test "unauthenticated graphql: whoami is null" {
    exec_graphql "anon" "whoami"

    [[ $(graphql_output | jq -r '.data.whoami') == "null" ]] || exit 1
}
