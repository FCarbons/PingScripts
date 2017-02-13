###############################################################################################
#
# Deploys PF on a Mac. Sofware is downloaded from a private repo scalr. The script does the following:
# 
# - downloads PF, the X509 adapter, the FB adapter, the REFID adapter 
#   the OAuth Playground, and PF license
# - installs PF and the other adapters / components
# - enables X509 secondary port
#
###############################################################################################



BASE_DOWNLOAD_URL=http://dc.rsademo.ping-eng.com:8081/software/scriptdownload

PF_VERSION=8.3.0

PINGFEDERATE_FILENAME=pingfederate-${PF_VERSION}.zip
FBADAPTER_FILENAME=facebook-adapter.zip
X509ADAPTER_FILENAME=x509-certificate-adapter.zip
REFIDADAPTER_FILENAME=reference-id-adapter.zip
OAUTH_PLAYGROUND_FILENAME=OAuthPlayground.zip
PF_LIC_FILENAME=pingfederate.lic
PF_DATA_FILENAME=data.zip

DOWNLOAD_DIR=Download
PING_INST_DIR=${1}


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
    echo "Usage: $0 destination_folder"
    exit 1
fi


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
download ${PINGFEDERATE_FILENAME}
download ${FBADAPTER_FILENAME}
download ${X509ADAPTER_FILENAME}
download ${REFIDADAPTER_FILENAME}
download ${OAUTH_PLAYGROUND_FILENAME}
download ${PF_LIC_FILENAME}
download ${PF_DATA_FILENAME}

# Unzip pingfederate, install license & deploy config
echo "Unzip PF: unzip -o ${DOWNLOAD_DIR}/${PINGFEDERATE_FILENAME} -d ${PING_INST_DIR}"
unzip -o ${DOWNLOAD_DIR}/${PINGFEDERATE_FILENAME} -d ${PING_INST_DIR}
cp ${DOWNLOAD_DIR}/${PF_LIC_FILENAME} ${PING_INST_DIR}/pingfederate-${PF_VERSION}/pingfederate/server/default/conf
cp ${DOWNLOAD_DIR}/${PF_DATA_FILENAME} ${PING_INST_DIR}/pingfederate-${PF_VERSION}/pingfederate/server/default/data/drop-in-deployer


# Unzip pingfederate adapters
unzip -o ${DOWNLOAD_DIR}/${FBADAPTER_FILENAME} -d ${PING_INST_DIR}/pingfederate-${PF_VERSION}/pingfederate/server/default/deploy
unzip -o ${DOWNLOAD_DIR}/${X509ADAPTER_FILENAME} -d ${PING_INST_DIR}/pingfederate-${PF_VERSION}/pingfederate/server/default/deploy
unzip -o ${DOWNLOAD_DIR}/${REFIDADAPTER_FILENAME} -d ${PING_INST_DIR}/pingfederate-${PF_VERSION}/pingfederate/server/default/deploy
unzip -o ${DOWNLOAD_DIR}/${OAUTH_PLAYGROUND_FILENAME} -d ${PING_INST_DIR}/pingfederate-${PF_VERSION}/pingfederate/server/default/deploy



# Enable secondary port 9032
# sed -i "s/pf.secondary.https.port=.*$/pf.secondary.https.port=9032/g" ${PING_INST_DIR}/pingfederate-${PF_VERSION}/pingfederate/bin/run.properties

exit 0