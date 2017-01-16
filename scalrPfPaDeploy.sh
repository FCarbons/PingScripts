#!/bin/sh


###############################################################################################
#
# Deploys PF and PA as services on a CentOS / RedHat env. Sofware is downloaded from a repo
# in a private repo scalr. The script does the following:
# 
# - downloads the Oracle JDK 1.8,  PF, PA, the X509 adapter, the FB adapter, the REFID adapter 
#   the OAuth Playground, the PA QuickStart and PF and PA licenses
# - creates a Ping user
# - installs java
# - installs PF and PA and the other adapters / components
# - enables X509 secondary port
# - registers the services (PF & PA)
# - starts the services (PF & PA)
#
###############################################################################################



BASE_DOWNLOAD_URL=http://dc.rsademo.ping-eng.com:8081/software/scriptdownload

PF_VERSION=8.3.0
PA_VERSION=4.2.0

JDK_FILENAME=jdk.rpm
PINGFEDERATE_FILENAME=pingfederate-${PF_VERSION}.zip
FBADAPTER_FILENAME=facebook-adapter.zip
X509ADAPTER_FILENAME=x509-certificate-adapter.zip
REFIDADAPTER_FILENAME=reference-id-adapter.zip
PINGACCESS_FILENAME=pingaccess-${PA_VERSION}.zip
INITSCRIPTS_FILENAME=initscripts.zip
OAUTH_PLAYGROUND_FILENAME=OAuthPlayground.zip
PA_QUICKSTART_FILENAME=PingAccessQuickStart.zip
PF_LIC_FILENAME=pingfederate.lic
PA_LIC_FILENAME=pingaccess.lic

TMP_DIR=/tmp/ping-tmp
PING_INST_DIR=/usr/local

PING_USER=pinguser
JAVA_HOME=/usr/java/jdk1.8.0_111

######################
# Functions
######################

function download()
{
	curl --fail --insecure --output ${TMP_DIR}/${1} ${BASE_DOWNLOAD_URL}/${1}
}

######################
# Script
######################

# Install unzip
yum install -y unzip &> /dev/null

# Create ping user
if [ ! -d "/home/${PING_USER}" ]; then
useradd -d /home/${PING_USER} ${PING_USER}
  if [ ! -d "/home/${PING_USER}" ]; then
    mkdir /home/${PING_USER}
  fi
  chown -R ${PING_USER}:${PING_USER} /home/${PING_USER}
fi

# Create temp dir 
if [ ! -d "${TMP_DIR}" ]; then
     mkdir ${TMP_DIR}
fi

# Download software
download ${JDK_FILENAME}
download ${PINGFEDERATE_FILENAME}
download ${FBADAPTER_FILENAME}
download ${X509ADAPTER_FILENAME}
download ${REFIDADAPTER_FILENAME}
download ${OAUTH_PLAYGROUND_FILENAME}
download ${PA_QUICKSTART_FILENAME}
download ${PINGACCESS_FILENAME}
download ${INITSCRIPTS_FILENAME}
download ${PF_LIC_FILENAME}
download ${PA_LIC_FILENAME}

# Install java
rpm -i ${TMP_DIR}/${JDK_FILENAME}
${TMP_DIR}/${JDK_FILENAME}
echo "export JAVA_HOME=$JAVA_HOME" >> /home/${PING_USER}/.bashrc


# Unzip pingfederate
echo "Unzip PF: unzip -o ${TMP_DIR}/${PINGFEDERATE_FILENAME} -d ${PING_INST_DIR}"
unzip -o ${TMP_DIR}/${PINGFEDERATE_FILENAME} -d ${PING_INST_DIR}
ln -s -f /usr/local/pingfederate-${PF_VERSION}/pingfederate ${PING_INST_DIR}/pingfederate
cp ${TMP_DIR}/${PF_LIC_FILENAME} ${PING_INST_DIR}/pingfederate/server/default/conf
chown -R ${PING_USER}:${PING_USER} ${PING_INST_DIR}/pingfederate*

# Unzip pingfederate adapters & apps
unzip -o ${TMP_DIR}/${FBADAPTER_FILENAME} -d ${PING_INST_DIR}/pingfederate/server/default/deploy
unzip -o ${TMP_DIR}/${X509ADAPTER_FILENAME} -d ${PING_INST_DIR}/pingfederate/server/default/deploy
unzip -o ${TMP_DIR}/${REFIDADAPTER_FILENAME} -d ${PING_INST_DIR}/pingfederate/server/default/deploy
unzip -o ${TMP_DIR}/${OAUTH_PLAYGROUND_FILENAME} -d ${PING_INST_DIR}/pingfederate/server/default/deploy
unzip -o ${TMP_DIR}/${PA_QUICKSTART_FILENAME} -d ${PING_INST_DIR}/pingfederate/server/default/deploy

# Enable secondary port 9032
sed -i "s/pf.secondary.https.port=.*$/pf.secondary.https.port=9032/g" ${PING_INST_DIR}/pingfederate/bin/run.properties

# Unzip pingaccess
unzip -o ${TMP_DIR}/${PINGACCESS_FILENAME} -d ${PING_INST_DIR}
ln -s -f /usr/local/pingaccess-${PA_VERSION} ${PING_INST_DIR}/pingaccess
cp ${TMP_DIR}/${PA_LIC_FILENAME} ${PING_INST_DIR}/pingaccess/conf
chown -R ${PING_USER}:${PING_USER} ${PING_INST_DIR}/pingaccess*

# Register services
unzip -o ${TMP_DIR}/${INITSCRIPTS_FILENAME} -d /etc/init.d
chmod +x /etc/init.d/pingfederate
chkconfig --add pingfederate
chkconfig pingfederate on

chmod +x /etc/init.d/pingaccess
chkconfig --add pingaccess
chkconfig pingaccess on

# Start services
/etc/init.d/pingfederate start
/etc/init.d/pingaccess start
exit 0
