#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)

# Specify the algorithm and usage for the JWK
ALGORITHM="RS256"
USAGE="sig"

# Generate the JWK
GENERATED_JWK=$(jose jwk gen -i "{\"alg\":\"$ALGORITHM\",\"use\":\"$USAGE\"}")

# Create the JWKS using jq
JWKS=$(echo $GENERATED_JWK | jq '{keys: [.]}')

# Save the JWKS to a file
echo $JWKS | jq . > ${REPO_ROOT}/dev/ory/id-token.jwks.json
