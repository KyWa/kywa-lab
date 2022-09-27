#!/usr/bin/env bash

# print usage
DOMAIN=$1
if [ -z "$1" ]; then 

    echo "USAGE: $0 domain.lan"
    echo ""
    echo "This will generate a non-secure self-signed wildcard certificate for given domain."
    echo "This should only be used in a development environment."
    exit
fi

# Add wildcard
WILDCARD="*.$DOMAIN"

# Set our CSR variables
SUBJ="
C=US
ST=TX
O=Kywa Lab
localityName=Kywa Lab
commonName=$WILDCARD
organizationalUnitName=Kywa Lab
emailAddress=unixislife@gmail.com
"

# Generate our Private Key, CSR and Certificate
#openssl genrsa -out "$DOMAIN.key" 2048
#openssl req -new -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key "$DOMAIN.key" -out "$DOMAIN.csr"
#openssl x509 -req -days 365 -in "$DOMAIN.csr" -signkey "$DOMAIN.key" -out "$DOMAIN.crt"
openssl req -x509 -newkey rsa:4096 -nodes -keyout "$DOMAIN.key" -out "$DOMAIN.crt" -days 365 -subj "$(echo -n "$SUBJ" | tr "\n" "/")"

echo ""
echo "Next manual steps:"
echo "- Use $DOMAIN.crt and $DOMAIN.key to configure Apache/nginx"
echo "- Import $DOMAIN.crt into Chrome settings: chrome://settings/certificates > tab 'Authorities'"
