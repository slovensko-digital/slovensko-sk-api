#!/bin/bash

set -ex

# SECRET_KEY_BASE
# openssl rand -hex 64

# OBO_TOKEN_PRIVATE_KEY_FILE
openssl genrsa -out obo-token.private.pem 2048
openssl rsa -in obo-token.private.pem -pubout -out obo-token.public.pem

# API_TOKEN_PUBLIC_KEY_FILE
openssl genrsa -out api-token.private.pem 2048
openssl rsa -in api-token.private.pem -pubout -out api-token.public.pem

# UPVS_TLS_TS_FILE UPVS_TLS_TS_PASSWORD
echo | openssl s_client -servername 'vyvoj.upvs.globaltel.sk' -connect 'vyvoj.upvs.globaltel.sk:443' | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > security/upvs-dev.pem
echo yes | keytool -import -file upvs-dev.pem -keystore upvs-dev.truststore -storepass password

# UPVS_IDP_METADATA_FILE
# Unavailable for unknown reason
# curl -k https://auth.vyvoj.upvs.globaltel.sk/fed/idp/metadata > upvs-dev-idp.metadata.xml
# curl -k https://prihlasenie.upvsfix.gov.sk/fed/idp/metadata > upvs-fix-idp.metadata.xml
# curl -k https://prihlasenie.slovensko.sk/fed/idp/metadata > upvs-prod-idp.metadata.xml

# UPVS_SP_METADATA_FILE UPVS_SP_KS_FILE UPVS_SP_KS_ALIAS UPVS_SP_KS_PASSWORD UPVS_SP_KS_PRIVATE_PASSWORD
# UPVS_STS_KS_FILE UPVS_STS_KS_ALIAS UPVS_STS_KS_PASSWORD UPVS_STS_KS_PRIVATE_PASSWORD
# Send einvoice-dev.certificate.cer and einvoice-dev.signed.metadata.xml to UPVS.
openssl req -newkey rsa:2048 -nodes -keyout einvoice-dev.key.pem -x509 -days 730 -out einvoice-dev.certificate.cer -subj "/CN=ico-11248756" -extensions usr_cert -outform DER
openssl x509 -inform der -in einvoice-dev.certificate.cer -out einvoice-dev.certificate.pem
openssl pkcs12 -export -inkey einvoice-dev.key.pem -in einvoice-dev.certificate.pem -out einvoice-dev.p12 -name einvoice -password pass:password
keytool -importkeystore -deststorepass password -destkeypass password -destkeystore einvoice-dev.keystore -srckeystore einvoice-dev.p12 -srcstoretype PKCS12 -srcstorepass password -alias einvoice
xmlsec1 --sign --output einvoice-dev.signed.metadata.xml --privkey-pem einvoice-dev.key.pem einvoice-dev.metadata.xml

# Use openssl rand -hex 64 instead of rails secret to generate SECRET_KEY_BASE

# Other useful commands
# https://www.digicert.com/kb/ssl-support/openssl-quick-reference-guide.htm
# openssl x509 -text -in certificate.pem -noout
