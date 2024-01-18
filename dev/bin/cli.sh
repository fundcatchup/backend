#!/bin/bash

COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-fundcatchup-dev}"

kratos_pg() {
  DB_USER="user"
  DB_NAME="kratos"

  docker exec "${COMPOSE_PROJECT_NAME}-kratos-pg-1" psql -U $DB_USER -d $DB_NAME -t "$@"
}
