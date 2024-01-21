#!/bin/bash

set -e

TARGETS=(
    "//core/api:update-schema"
    "//dev:update-supergraph"
)

buck2 build "${TARGETS[@]}"

for TARGET in "${TARGETS[@]}"; do
  buck2 run "$TARGET"
done
