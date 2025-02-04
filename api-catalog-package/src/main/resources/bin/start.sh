#!/bin/sh

################################################################################
# This program and the accompanying materials are made available under the terms of the
# Eclipse Public License v2.0 which accompanies this distribution, and is available at
# https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright IBM Corporation 2021
################################################################################

# Variables required on shell:
# - JAVA_HOME
# - ZWE_STATIC_DEFINITIONS_DIR
# - ZWE_zowe_certificate_keystore_alias - The default alias of the key within the keystore
# - ZWE_zowe_certificate_keystore_file - The default keystore to use for SSL certificates
# - ZWE_zowe_certificate_keystore_password - The default password to access the keystore supplied by KEYSTORE
# - ZWE_zowe_certificate_truststore_file
# - ZWE_zowe_job_prefix
# - ZWE_zowe_logDirectory

# Optional variables:
# - CMMN_LB
# - LIBPATH
# - LIBRARY_PATH
# - ZWE_components_discovery_port - the port the discovery service will use
# - ZWE_components_gateway_apiml_security_authorization_endpoint_enabled
# - ZWE_components_gateway_apiml_security_authorization_endpoint_url
# - ZWE_components_gateway_apiml_security_authorization_provider
# - ZWE_components_gateway_apiml_security_authorization_resourceClass
# - ZWE_components_gateway_port - the port the api gateway service will use
# - ZWE_components_gateway_server_ssl_enabled
# - ZWE_configs_certificate_keystore_alias - The alias of the key within the keystore
# - ZWE_configs_certificate_keystore_file - The keystore to use for SSL certificates
# - ZWE_configs_certificate_keystore_password - The password to access the keystore supplied by KEYSTORE
# - ZWE_configs_certificate_keystore_type - The keystore type to use for SSL certificates
# - ZWE_configs_certificate_truststore_file
# - ZWE_configs_certificate_truststore_type
# - ZWE_configs_debug
# - ZWE_configs_port - the port the api catalog service will use
# - ZWE_configs_spring_profiles_active
# - ZWE_DISCOVERY_SERVICES_LIST
# - ZWE_GATEWAY_HOST
# - ZWE_haInstance_hostname
# - ZWE_zowe_certificate_keystore_type - The default keystore type to use for SSL certificates
# - ZWE_zowe_verifyCertificates - if we accept only verified certificates
if [ -n "${LAUNCH_COMPONENT}" ]
then
    JAR_FILE="${LAUNCH_COMPONENT}/api-catalog-services-lite.jar"
else
    JAR_FILE="$(pwd)/bin/api-catalog-services-lite.jar"
fi
echo "jar file: "${JAR_FILE}
# script assumes it's in the catalog component directory and common_lib needs to be relative path

if [ -z "${CMMN_LB}" ]
then
    COMMON_LIB="../apiml-common-lib/bin/api-layer-lite-lib-all.jar"
else
    COMMON_LIB=${CMMN_LB}
fi

if [ -z "${LIBRARY_PATH}" ]
then
    LIBRARY_PATH="../common-java-lib/bin/"
fi
# API Mediation Layer Debug Mode
export LOG_LEVEL=

if [ "${ZWE_configs_debug}" = "true" ]
then
  export LOG_LEVEL="debug"
fi

# FIXME: APIML_DIAG_MODE_ENABLED is not officially mentioned. We can still use it behind the scene,
# or we can define configs.diagMode in manifest, then use "$ZWE_configs_diagMode".
# if [[ ! -z "${APIML_DIAG_MODE_ENABLED}" ]]
# then
#     LOG_LEVEL=${APIML_DIAG_MODE_ENABLED}
# fi

# NOTE: ZWEAD_EXTERNAL_STATIC_DEF_DIRECTORIES is not defined in Zowe level any more, never heard anyone use it.
#        will just use $ZWE_STATIC_DEFINITIONS_DIR directly.
# If set append $ZWEAD_EXTERNAL_STATIC_DEF_DIRECTORIES to $ZWE_STATIC_DEFINITIONS_DIR
# export APIML_STATIC_DEF=${ZWE_STATIC_DEFINITIONS_DIR}
# if [[ ! -z "$ZWEAD_EXTERNAL_STATIC_DEF_DIRECTORIES" ]]
# then
#   export APIML_STATIC_DEF="${APIML_STATIC_DEF};${ZWEAD_EXTERNAL_STATIC_DEF_DIRECTORIES}"
# fi

# how to verifyCertificates
verify_certificates_config=$(echo "${ZWE_zowe_verifyCertificates}" | tr '[:lower:]' '[:upper:]')
if [ "${verify_certificates_config}" = "DISABLED" ]; then
  verifySslCertificatesOfServices=false
  nonStrictVerifySslCertificatesOfServices=false
elif [ "${verify_certificates_config}" = "NONSTRICT" ]; then
  verifySslCertificatesOfServices=false
  nonStrictVerifySslCertificatesOfServices=true
else
  # default value is STRICT
  verifySslCertificatesOfServices=true
  nonStrictVerifySslCertificatesOfServices=true
fi

if [ "$(uname)" = "OS/390" ]
then
    QUICK_START=-Xquickstart
fi
LIBPATH="$LIBPATH":"/lib"
LIBPATH="$LIBPATH":"/usr/lib"
LIBPATH="$LIBPATH":"${JAVA_HOME}"/bin
LIBPATH="$LIBPATH":"${JAVA_HOME}"/bin/classic
LIBPATH="$LIBPATH":"${JAVA_HOME}"/bin/j9vm
LIBPATH="$LIBPATH":"${JAVA_HOME}"/lib/s390/classic
LIBPATH="$LIBPATH":"${JAVA_HOME}"/lib/s390/default
LIBPATH="$LIBPATH":"${JAVA_HOME}"/lib/s390/j9vm
LIBPATH="$LIBPATH":"${LIBRARY_PATH}"

keystore_type="${ZWE_configs_certificate_keystore_type:-${ZWE_zowe_certificate_keystore_type:-PKCS12}}"
keystore_pass="${ZWE_configs_certificate_keystore_password:-${ZWE_zowe_certificate_keystore_password}}"
key_pass="${ZWE_configs_certificate_key_password:-${ZWE_zowe_certificate_key_password:-${keystore_pass}}}"
truststore_type="${ZWE_configs_certificate_truststore_type:-${ZWE_zowe_certificate_truststore_type:-PKCS12}}"
truststore_pass="${ZWE_configs_certificate_truststore_password:-${ZWE_zowe_certificate_truststore_password}}"


# Workaround for Java desiring safkeyring://// instead of just ://
# We can handle both cases of user input by just adding extra "//" if we detect its missing.
ensure_keyring_slashes() {
  keyring_string="${1}"
  only_two_slashes=$(echo "${keyring_string}" | grep "^safkeyring://[^//]")
  if [ -n "${only_two_slashes}" ]; then
    keyring_string=$(echo "${keyring_string}" | sed "s#safkeyring://#safkeyring:////#")
  fi
  # else, unmodified, perhaps its even p12
  echo $keyring_string
}

keystore_location=$(ensure_keyring_slashes "${ZWE_configs_certificate_keystore_file:-${ZWE_zowe_certificate_keystore_file}}")
truststore_location=$(ensure_keyring_slashes "${ZWE_configs_certificate_truststore_file:-${ZWE_zowe_certificate_truststore_file}}")

# NOTE: these are moved from below
#    -Dapiml.service.ipAddress=${ZOWE_IP_ADDRESS:-127.0.0.1} \
#    -Dapiml.service.preferIpAddress=false \

CATALOG_CODE=AC
_BPX_JOBNAME=${ZWE_zowe_job_prefix}${CATALOG_CODE} java \
    -Xms16m -Xmx512m \
    ${QUICK_START} \
    -Dibm.serversocket.recover=true \
    -Dfile.encoding=UTF-8 \
    -Djava.io.tmpdir=${TMPDIR:-/tmp} \
    -Dspring.profiles.active=${ZWE_configs_spring_profiles_active:-} \
    -Dapiml.service.hostname=${ZWE_haInstance_hostname:-localhost} \
    -Dapiml.service.port=${ZWE_configs_port:-7552} \
    -Dapiml.service.discoveryServiceUrls=${ZWE_DISCOVERY_SERVICES_LIST:-"https://${ZWE_haInstance_hostname:-localhost}:${ZWE_components_discovery_port:-7553}/eureka/"} \
    -Dapiml.service.gatewayHostname=${ZWE_GATEWAY_HOST:-${ZWE_haInstance_hostname:-localhost}} \
    -Dapiml.logs.location=${ZWE_zowe_logDirectory} \
    -Dapiml.discovery.staticApiDefinitionsDirectories=${ZWE_STATIC_DEFINITIONS_DIR} \
    -Dapiml.security.ssl.verifySslCertificatesOfServices=${verifySslCertificatesOfServices:-false} \
    -Dapiml.security.ssl.nonStrictVerifySslCertificatesOfServices=${nonStrictVerifySslCertificatesOfServices:-false} \
    -Dapiml.security.authorization.provider=${ZWE_components_gateway_apiml_security_authorization_provider:-} \
    -Dapiml.security.authorization.endpoint.enabled=${ZWE_components_gateway_apiml_security_authorization_endpoint_enabled:-false} \
    -Dapiml.security.authorization.endpoint.url=${ZWE_components_gateway_apiml_security_authorization_endpoint_url:-"https://${ZWE_haInstance_hostname:-localhost}:${ZWE_components_gateway_port}/zss/api/v1/saf-auth"} \
    -Dapiml.security.authorization.resourceClass=${ZWE_components_gateway_apiml_security_authorization_resourceClass:-ZOWE} \
    -Dapiml.catalog.hide.serviceInfo=${ZWE_configs_apiml_catalog_hide_serviceInfo:-false} \
    -Dspring.profiles.include=$LOG_LEVEL \
    -Dserver.address=0.0.0.0 \
    -Dserver.ssl.enabled=${ZWE_components_gateway_server_ssl_enabled:-true}  \
    -Dserver.ssl.keyStore="${keystore_location}" \
    -Dserver.ssl.keyStoreType="${ZWE_configs_certificate_keystore_type:-${ZWE_zowe_certificate_keystore_type:-PKCS12}}" \
    -Dserver.ssl.keyStorePassword="${keystore_pass}" \
    -Dserver.ssl.keyAlias="${ZWE_configs_certificate_keystore_alias:-${ZWE_zowe_certificate_keystore_alias}}" \
    -Dserver.ssl.keyPassword="${key_pass}" \
    -Dserver.ssl.trustStore="${truststore_location}" \
    -Dserver.ssl.trustStoreType="${ZWE_configs_certificate_truststore_type:-${ZWE_zowe_certificate_truststore_type:-PKCS12}}" \
    -Dserver.ssl.trustStorePassword="${truststore_pass}" \
    -Djava.protocol.handler.pkgs=com.ibm.crypto.provider \
    -Dloader.path=${COMMON_LIB} \
    -Djava.library.path=${LIBPATH} \
    -jar "${JAR_FILE}" &
pid=$!
echo "pid=${pid}"

wait %1
