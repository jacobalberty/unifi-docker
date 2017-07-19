#!/usr/bin/env bash

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"


if `md5sum -c /var/cert/unifi/cert.pem.md5 &>/dev/null`; then
    echo "Cert has not changed, not updating controller."
    exit 0
else
    TEMPFILE=$(mktemp)
    CERTTEMPFILE=$(mktemp)
    CERTURI=$(openssl x509 -noout -ocsp_uri -in /var/cert/unifi/cert.pem)
    # Identrust cross-signed CA cert needed by the java keystore for import.
    # Can get original here: https://www.identrust.com/certificates/trustid/root-download-x3.html
    cat > ${CERTTEMPFILE} <<'_EOF'
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

    echo "Cert has changed, updating controller..."
    md5sum /var/cert/unifi/cert.pem > /var/cert/unifi/cert.pem.md5 
    echo "Using openssl to prepare certificate..."
    openssl pkcs12 -export  -passout pass:aircontrolenterprise \
        -in /var/cert/unifi/cert.pem \
        -inkey /var/cert/unifi/privkey.pem \
        -out ${TEMPFILE} -name unifi \
        -CAfile /var/cert/unifi/chain.pem -caname root
    echo "Removing existing certificate from Unifi protected keystore..."
    keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore \
        -deststorepass aircontrolenterprise
    echo "Inserting certificate into Unifi keystore..."
    keytool -trustcacerts -importkeystore \
        -deststorepass aircontrolenterprise \
        -destkeypass aircontrolenterprise \
        -destkeystore /usr/lib/unifi/data/keystore \
        -srckeystore ${TEMPFILE} -srcstoretype PKCS12 \
        -srcstorepass aircontrolenterprise \
        -alias unifi
    rm -f ${TEMPFILE}
    echo "Importing cert into Unifi database..."
    if [[ ${CERTURI} == *"letsencrypt"* ]]; then
        java -jar /usr/lib/unifi/lib/ace.jar import_cert \
            /var/cert/unifi/cert.pem \
            /var/cert/unifi/chain.pem \
            ${CERTTEMPFILE}
        rm -f ${CERTTEMPFILE}
    elif [ -f "/var/cert/unifi/ca.pem" ]; then
        java -jar /usr/lib/unifi/lib/ace.jar import_cert \
            /var/cert/unifi/cert.pem \
            /var/cert/unifi/chain.pem \
            /var/cert/unifi/ca.pem
    else
        java -jar /usr/lib/unifi/lib/ace.jar import_cert \
           /var/cert/unifi/cert.pem \
           /var/cert/unifi/chain.pem
    fi
    echo "Done!"
fi
