export REPO_ROOT=$(git rev-parse --show-toplevel)
source ${REPO_ROOT}/e2e/helpers/_common.bash
source ${REPO_ROOT}/e2e/helpers/kratos.bash

try_login() {
    ${run_cmd} curl -s -X GET "${OATHKEEPER_PROXY}/auth/self-service/login/api"
    flowId=$(echo $output | jq -r '.id')

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"identifier\": \"$1\", \"password\": \"$2\", \"method\": \"password\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/login?flow=$flowId"
}

create_new_verified_user() {
    email="test-$RANDOM@example.com"
    password="123@WordPass"
    firstName="Jackie"
    lastName="Chan"

    ${run_cmd} curl -s -X GET "${OATHKEEPER_PROXY}/auth/self-service/registration/api"
    flowId=$(echo $output | jq -r '.id')

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"traits.email\": \"$email\", \"password\": \"$password\", \"traits.name.first\": \"$firstName\", \"traits.name.last\": \"$lastName\", \"method\": \"password\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/registration?flow=$flowId"

    verificationFlowId=$(echo $output | jq -r '.continue_with.[].flow.id')
    code=$(get_kratos_code $email)

    ${run_cmd} curl -s \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$email\", \"code\": \"$code\", \"method\": \"code\"}" \
        "${OATHKEEPER_PROXY}/auth/self-service/verification?flow=$verificationFlowId"

    try_login $email $password

    session_token=$(echo $output | jq -r '.session_token')
    [[ $session_token != "null" ]] || exit 1
    
    cache_value $1 $session_token
}
