#!/bin/bash

INSTALL_PATH=""
while [[ $# > 0 ]]
do
  key="$1"
  case $key in
    -p|--install-path)
      INSTALL_PATH=$2
    ;;
    -h|--help)
      echo "Usage: $0 [--install-path PATH]"
      echo "Install TEMPERA System."
      echo "Optional arguments: "
      echo "  -p, --install-path PATH   installation path. Default: HOME/tempera-server"

      exit 0
    ;;
    *)
    ;;
  esac
  shift
done

if [ "$INSTALL_PATH" = "" ]; then
  INSTALL_PATH=$HOME/tempera-server
fi


RED='\e[0;31m'
GREEN='\e[0;32m'
BLUE='\e[0;34m'
RED_BOLD='\e[1;31m'
GREEN_BOLD='\e[1;32m'
BLUE_BOLD='\e[1;34m'
NC='\e[0m' # No Color

echo -e " "
echo -e "${BLUE_BOLD}============ Tecnología Integral S.A. ============${NC}"
echo -e "${BLUE_BOLD}============ TEMPERA System Installer ============${NC}"
echo -e "${BLUE_BOLD}==================================================${NC}"
echo -e " "
echo -e "${GREEN_BOLD}Instalation path set to ${INSTALL_PATH} ${NC}"
mkdir -p ${INSTALL_PATH}

TMP1=$(mktemp -d) || exit 1

# searches for the line number where finish the script and start the tar.gz
SKIP=$(awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0)
#remember our file name
THIS=$(pwd)/$0
INSTALLER_NAME=$(basename $THIS)

if [ "$INSTALLER_NAME" = "installer.sh" ]; then
  echo -e "${GREEN_BOLD}* Installing using local docker images . ${NC}"
  echo -e "${GREEN_BOLD}* Copying resource files ... ${NC}"

  cp -r $(dirname $THIS)/* ${INSTALL_PATH}

  # Replace default volume path with real installation path
  sed -i "s.\$HOME\/tempera-server.${INSTALL_PATH}.g" ${INSTALL_PATH}/docker-compose.yml

  echo -e "${GREEN_BOLD}* Stopping docker-compose ... ${NC}"
  docker-compose -f ${INSTALL_PATH}/docker-compose.yml stop
else
  echo -e "${GREEN_BOLD}* Extracting tarball from installer ... ${NC}"
  # take the tarfile and pipe it into tar
  tail -n +${SKIP} ${THIS} | tar -xz -C ${TMP1}

  echo -e "${GREEN_BOLD}* Copying resource files ... ${NC}"
  cp -r ${TMP1}/scripts/* ${INSTALL_PATH}

  # Replace default volume path with real installation path
  sed -i "s.\$HOME\/tempera-server.${INSTALL_PATH}.g" ${INSTALL_PATH}/docker-compose.yml

  echo -e "${GREEN_BOLD}* Stopping docker-compose ... ${NC}"
  docker-compose -f ${INSTALL_PATH}/docker-compose.yml stop

  echo -e "${GREEN_BOLD}* Extracting docker images fron tarball ... ${NC}"
  docker load < ${TMP1}/tempera-installer.tar
fi
#mkdir -p ${INSTALL_PATH}/chrony
#mkdir -p ${INSTALL_PATH}/dhcp
#mkdir -p ${INSTALL_PATH}/http
#cat ${TMP1}/eth_conf >> /etc/sysconfig/network-scripts/


#INTERFAZ=$(ip -o a | awk '{print $2}' | grep en)
#cat ${DIR}/

echo -e "${GREEN_BOLD}* Configuring firewall ... ${NC}"
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=67-68/udp
firewall-cmd --add-service=ntp --permanent
firewall-cmd --permanent --add-port=1883/tcp
firewall-cmd --permanent --add-port=1883/udp
firewall-cmd --permanent --add-port=8883/tcp
firewall-cmd --permanent --add-port=8883/udp
firewall-cmd --reload

#cp -r ${TMP1}/scripts/chrony/* ${INSTALL_PATH}/chrony
#cp -r ${TMP1}/scripts/http/* ${INSTALL_PATH}/http
#cp -r ${TMP1}/scripts/dhcp/* ${INSTALL_PATH}/dhcp
#cp ${TMP1}/scripts/docker-compose.yml ${INSTALL_PATH}/
#cp ${TMP1}/scripts/uninstall.sh ${INSTALL_PATH}/
echo -e "${GREEN_BOLD}* Removing unnecessary files ... ${NC}"
rm -f ${INSTALL_PATH}/installer.sh
rm -f ${INSTALL_PATH}/version_info.sh
rm -f ${INSTALL_PATH}/ifcfg*
mv ${INSTALL_PATH}/tempera-tis*.bin ${INSTALL_PATH}/http
mv ${INSTALL_PATH}/tempera-server.conf ${INSTALL_PATH}/http

echo -e "${GREEN_BOLD}* Restarting docker service ... ${NC}"
service docker restart

echo -e "${GREEN_BOLD}* Starting docker-compose ... ${NC}"
docker-compose -f ${INSTALL_PATH}/docker-compose.yml up -d

echo -e "${GREEN_BOLD}* Deleting temporal files ... ${NC}"
rm -rf ${TMP1}
echo -e "${GREEN_BOLD}Done. ${NC}"
echo -e " "

exit 0
__TARFILE_FOLLOWS__
