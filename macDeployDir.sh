###############################################################################################
#
# Deploys PingDirectory on mac. Sofware is downloaded from a private repo scalr. The script does the following:
# 
# - downloads PingDirectory
# - installs two PingDirectory instances and configures the cluster
#
###############################################################################################



BASE_DOWNLOAD_URL=http://dc.rsademo.ping-eng.com:8081/software/scriptdownload

DIR_VERSION=6.0.0.2
DIR_FILENAME=PingDirectory-${DIR_VERSION}.zip
JWTHANDLER_FILENAME=JWTOAuthTokenHandler.zip

DOWNLOAD_DIR=Download
PING_INST_DIR=${1}
DIR1_FOLDER=${PING_INST_DIR}/ds1
DIR2_FOLDER=${PING_INST_DIR}/ds2

######################
# Functions
######################

function download()
{
	if ! [ -f ${DOWNLOAD_DIR}/${1} ]; then
		curl -z --fail --insecure --output ${DOWNLOAD_DIR}/${1} ${BASE_DOWNLOAD_URL}/${1}
	else
		echo "File ${DOWNLOAD_DIR}/${1} already present, skipping download"
	fi
}

######################
# Script
######################

if [[ $# -eq 0 ]] ; then
    echo "Usage: $0 destination-folder"
    exit 1
fi

sudo hostname localhost

# Create download dir 
if [ ! -d "${DOWNLOAD_DIR}" ]; then
	echo "Creating ${DOWNLOAD_DIR}"
    mkdir ${DOWNLOAD_DIR}
else
	echo "Download dir ${DOWNLOAD_DIR} already exists, skipping creation"
fi

# Create installation dir 
if [ -d "${PING_INST_DIR}" ]; then
     echo "Destination dir already exists, skipping creation."
else
	echo "Creating ${PING_INST_DIR}"
	mkdir ${PING_INST_DIR}
fi

# Download software
download ${DIR_FILENAME}
download ${JWTHANDLER_FILENAME}

# Unzip pingfederate, install license & deploy config
echo "Unzip: unzip -o ${DOWNLOAD_DIR}/${DIR_FILENAME} -d ${PING_INST_DIR}"
unzip -q -o ${DOWNLOAD_DIR}/${DIR_FILENAME} -d ${PING_INST_DIR}
cp -R ${PING_INST_DIR}/PingDirectory ${DIR1_FOLDER}
cp -R ${PING_INST_DIR}/PingDirectory ${DIR2_FOLDER}
rm -R ${PING_INST_DIR}/PingDirectory

${DIR1_FOLDER}/setup --cli \
	--no-prompt \
	--acceptLicense \
	--ldapPort 1389 \
	--ldapsPort 1636 \
	--generateSelfSignedCertificate \
	--httpsPort 8443 \
	--rootUserDN cn=dmanager \
	--sampleData 10 \
	--script-friendly \
	--rootUserPassword Password01 \
	--baseDN "dc=pingdemo,dc=com" \
	--doNotStart
	
${DIR1_FOLDER}/bin/manage-extension --install ${DOWNLOAD_DIR}/${JWTHANDLER_FILENAME} --no-prompt

${DIR1_FOLDER}/bin/dsconfig create-oauth-token-handler \
    --no-prompt \
    --hostname localhost \
    --port 1389 \
    --bindDN cn=dmanager \
	--bindPassword Password01 \
    --handler-name PFJWT \
    --type third-party  \
    --set extension-class:com.pingidentity.server.PingFederateJWTOAuthTokenHandler  \
    --set extension-argument:username.attr=uid \
    --set extension-argument:idp.cert=MIIC2jCCAcKgAwIBAgIGAVo2uKwMMA0GCSqGSIb3DQEBCwUAMC4xCzAJBgNVBAYTAklUMQ0wCwYDVQQKEwRQaW5nMRAwDgYDVQQDEwdKV1RDZXJ0MB4XDTE3MDIxMzA5MDU1NloXDTE4MDIxMzA5MDU1NlowLjELMAkGA1UEBhMCSVQxDTALBgNVBAoTBFBpbmcxEDAOBgNVBAMTB0pXVENlcnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCBSk1OfHglboFCrijeueNq/paiFYcA/1AX+v30RyDpLBU4PKtyw47KP9czT6sOFTVdH1Ifoz6coMuC8iWqmJpWpZyaq+L5AF7tUd93YEMRrCAaJrpiRlGAaMrlTOdO3YRrETEuiGjGek69s3yjccAcFrrOHkVR+49k2aYI0U0injyrDs29GHnlRcRRTKe2uRKQecP/kCMp0aqpRDYiES7kMDafv65KeGWvI0drUTbxpZ+UNVEE8o8PW7EbjYUN0eE17BXJxtq0sh1f9iKVZJkCT6u4RSIl1+2jfYF2BPWnVDLUyc7mCQmZfaWt60wsyRn9Z+WjtKOcUYdwClFOnv25AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAHfO+fKyWrKpm44F1xO3bmWayyspq0ygryMmDiXfZ9AQcI4jgtEcoCUh050cvCk9iBEB4IZWCPT62uOSRI7cxGv59rPoq5CfmNmG5FJFCe96KFJYZmVS28dao4/lP+nJNPKNo5H/sbbsXKjNr5S0enjUHH+NVGJ/kXHHqJlFb8X3zw93pQse12mINcE6D3XTED8jXWDB6kss1vMgumKGFMw66MtdHQ2ZM/QrsSZA+ZG2E1vjPc5igf+1LgEHU4bHOhlR5mpZ12HE9bBTs4YI61E2vUkOwAFqR0iG3h9Iypzd3rWf44zJnKwrphzKQ1elsrEtzSWgPCVITUt4o2ZPKDI= \
    --set extension-argument:auth.user.base.dn=dc=pingdemo,dc=com \
    --offline

${DIR1_FOLDER}/bin/dsconfig set-http-servlet-extension-prop \
	--no-prompt \
	--hostname localhost \
	--port 1389 \
	--bindDN cn=dmanager \
	--bindPassword Password01 \
	--extension-name SCIM \
	--set oauth-token-handler:PFJWT \
	--offline
	
${DIR2_FOLDER}/setup --cli \
	--no-prompt \
	--acceptLicense \
	--ldapPort 2389 \
	--ldapsPort 2636 \
	--generateSelfSignedCertificate \
	--httpsPort 9443 \
	--rootUserDN cn=dmanager \
	--sampleData 10 \
	--script-friendly \
	--rootUserPassword Password01 \
	--baseDN "dc=pingdemo,dc=com" \
	--doNotStart
	
${DIR2_FOLDER}/bin/manage-extension --install ${DOWNLOAD_DIR}/${JWTHANDLER_FILENAME} --no-prompt

${DIR2_FOLDER}/bin/dsconfig create-oauth-token-handler \
    --no-prompt \
    --hostname localhost \
    --port 2389 \
    --bindDN cn=dmanager \
	--bindPassword Password01 \
    --handler-name PFJWT  \
    --type third-party  \
    --set extension-class:com.pingidentity.server.PingFederateJWTOAuthTokenHandler  \
    --set extension-argument:username.attr=uid \
    --set extension-argument:idp.cert=MIIC2jCCAcKgAwIBAgIGAVo2uKwMMA0GCSqGSIb3DQEBCwUAMC4xCzAJBgNVBAYTAklUMQ0wCwYDVQQKEwRQaW5nMRAwDgYDVQQDEwdKV1RDZXJ0MB4XDTE3MDIxMzA5MDU1NloXDTE4MDIxMzA5MDU1NlowLjELMAkGA1UEBhMCSVQxDTALBgNVBAoTBFBpbmcxEDAOBgNVBAMTB0pXVENlcnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCBSk1OfHglboFCrijeueNq/paiFYcA/1AX+v30RyDpLBU4PKtyw47KP9czT6sOFTVdH1Ifoz6coMuC8iWqmJpWpZyaq+L5AF7tUd93YEMRrCAaJrpiRlGAaMrlTOdO3YRrETEuiGjGek69s3yjccAcFrrOHkVR+49k2aYI0U0injyrDs29GHnlRcRRTKe2uRKQecP/kCMp0aqpRDYiES7kMDafv65KeGWvI0drUTbxpZ+UNVEE8o8PW7EbjYUN0eE17BXJxtq0sh1f9iKVZJkCT6u4RSIl1+2jfYF2BPWnVDLUyc7mCQmZfaWt60wsyRn9Z+WjtKOcUYdwClFOnv25AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAHfO+fKyWrKpm44F1xO3bmWayyspq0ygryMmDiXfZ9AQcI4jgtEcoCUh050cvCk9iBEB4IZWCPT62uOSRI7cxGv59rPoq5CfmNmG5FJFCe96KFJYZmVS28dao4/lP+nJNPKNo5H/sbbsXKjNr5S0enjUHH+NVGJ/kXHHqJlFb8X3zw93pQse12mINcE6D3XTED8jXWDB6kss1vMgumKGFMw66MtdHQ2ZM/QrsSZA+ZG2E1vjPc5igf+1LgEHU4bHOhlR5mpZ12HE9bBTs4YI61E2vUkOwAFqR0iG3h9Iypzd3rWf44zJnKwrphzKQ1elsrEtzSWgPCVITUt4o2ZPKDI= \
    --set extension-argument:auth.user.base.dn=dc=pingdemo,dc=com \
    --offline

${DIR2_FOLDER}/bin/dsconfig set-http-servlet-extension-prop \
	--no-prompt \
	--hostname localhost \
	--port 2389 \
	--bindDN cn=dmanager \
	--bindPassword Password01 \
	--extension-name SCIM \
	--set oauth-token-handler:PFJWT \
	--offline

${DIR1_FOLDER}/bin/start-ds
${DIR2_FOLDER}/bin/start-ds

${DIR1_FOLDER}/bin/dsreplication enable \
	--host1 localhost \
	--port1 1389 \
	--bindDN1 "cn=dmanager" \
	--bindPassword1 Password01 \
	--replicationPort1 1989 \
	--host2 localhost --port2 2389 \
	--bindDN2 "cn=dmanager" \
	--bindPassword2 Password01 \
	--replicationPort2 2989 \
	--baseDN dc=pingdemo,dc=com \
	--adminUID admin \
	--adminPassword Password01 \
	--no-prompt \
	--ignoreWarnings

exit 0