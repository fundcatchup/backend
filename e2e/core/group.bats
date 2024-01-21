#!/usr/bin/env bats

source 'e2e/helpers/_common.bash'
source 'e2e/helpers/auth.bash'

setup_file() {
    create_new_verified_user "alice"
}

@test "create a new group" {
    group_name="Test Group"
    group_type="FRIENDS"

    variables=$(
        jq -n \
        --arg name "$group_name" \
        --arg type "$group_type" \
        '{newGroup: {name: $name, pic: null, type: $type, members: [] }}'
    )
    exec_graphql "alice" "create_group" "$variables"

    [[ $(graphql_output | jq -r '.data.createGroup.id') != "null" ]] || exit 1
    [[ $(graphql_output | jq -r '.data.createGroup.name') == "$group_name" ]] || exit 1
    [[ $(graphql_output | jq -r '.data.createGroup.type') == "$group_type" ]] || exit 1
}
