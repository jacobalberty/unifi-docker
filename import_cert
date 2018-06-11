#!/usr/bin/env bash

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

. /usr/unifi/functions

if [[ ! -d "${CERTDIR}" || ! -f "${CERTDIR}/${CERTNAME}" ]]; then
    exit 0
fi

log 'Cert directory found. Checking Certs'

if `md5sum -c "${CERTDIR}/${CERTNAME}.md5" &>/dev/null`; then
    log "Cert has not changed, not updating controller."
    exit 0
else
    if [ ! -e "${DATADIR}/keystore" ]; then
        log "WARN: Missing keystore, creating a new one"

        if [ ! -d "${DATADIR}" ]; then
            log "Missing data directory, creating..."
            mkdir "${DATADIR}"
        fi

        keytool -genkey -keyalg RSA -alias unifi -keystore "${DATADIR}/keystore" \
            -storepass aircontrolenterprise -keypass aircontrolenterprise -validity 1825 \
            -keysize 4096 -dname "cn=UniFi"
    fi

    TEMPFILE=$(mktemp)
    TMPLIST="${TEMPFILE}"
    CERTTEMPFILE=$(mktemp)
    TMPLIST+=" ${CERTTEMPFILE}"
    CERTURI=$(openssl x509 -noout -ocsp_uri -in "${CERTDIR}/${CERTNAME}")
    # Identrust cross-signed CA cert needed by the java keystore for import.
    # Can get original here: https://www.identrust.com/certificates/trustid/root-download-x3.html
    cat > "${CERTTEMPFILE}" <<'_EOF'
-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----
_EOF

    log "Cert has changed, updating controller..."
    md5sum "${CERTDIR}/${CERTNAME}" > "${CERTDIR}/${CERTNAME}.md5"
    log "Using openssl to prepare certificate..."
    CHAIN=$(mktemp)
    TMPLIST+=" ${CHAIN}"

    if [[ "${CERTURI}" == *"letsencrypt"* && "$CERT_IS_CHAIN" == "true" ]]; then
        awk 1 "${CERTTEMPFILE}" "${CERTDIR}/${CERTNAME}" >> "${CHAIN}"
    elif [[ "${CERTURI}" == *"letsencrypt"* ]]; then
        awk 1 "${CERTTEMPFILE}" "${CERTDIR}/chain.pem" "${CERTDIR}/${CERTNAME}" >> "${CHAIN}"
    elif [[ -f "${CERTDIR}/ca.pem" ]]; then
        awk 1 "${CERTDIR}/ca.pem" "${CERTDIR}/chain.pem" "${CERTDIR}/${CERTNAME}" >> "${CHAIN}"
    else
        awk 1 "${CERTDIR}/chain.pem" "${CERTDIR}/${CERTNAME}" >> "${CHAIN}"
    fi
   openssl pkcs12 -export  -passout pass:aircontrolenterprise \
        -in "${CHAIN}" \
        -inkey "${CERTDIR}/${CERT_PRIVATE_NAME}" \
        -out "${TEMPFILE}" -name unifi
    log "Removing existing certificate from Unifi protected keystore..."
    keytool -delete -alias unifi -keystore "${DATADIR}/keystore" \
        -deststorepass aircontrolenterprise
    log "Inserting certificate into Unifi keystore..."
    keytool -trustcacerts -importkeystore \
        -deststorepass aircontrolenterprise \
        -destkeypass aircontrolenterprise \
        -destkeystore "${DATADIR}/keystore" \
        -srckeystore "${TEMPFILE}" -srcstoretype PKCS12 \
        -srcstorepass aircontrolenterprise \
        -alias unifi
    log "Cleaning up temp files"
    for file in ${TMPLIST}; do
        rm -f "${file}"
    done
    log "Done!"
fi
