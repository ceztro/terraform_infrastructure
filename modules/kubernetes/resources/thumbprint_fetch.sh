#!/bin/bash

# Fetch the OIDC issuer URL from the input
OIDC_URL=$1

# Fetch the OIDC thumbprint using openssl
THUMBPRINT=$(echo | openssl s_client -servername $OIDC_URL -showcerts -connect $OIDC_URL:443 2>/dev/null | \
openssl x509 -fingerprint -noout -in /dev/stdin | cut -d"=" -f2 | tr -d ":")

# Output the thumbprint in JSON format
echo "{\"thumbprint\": \"$THUMBPRINT\"}"