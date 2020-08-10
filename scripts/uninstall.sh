#!/bin/bash
CONFIRM="0"
while [[ $# > 0 ]]
do
  key="$1"
  case $key in
    -y|--skip-confirm)
      CONFIRM="1"
    ;;
    -h|--help)
      echo "Usage: $0 [--skip-confirm]"
      echo "Remove TEMPERA System."
      echo "Optional arguments: "
      echo "  -y, --skip-confirm   Do not ask for confirmation before removing software"

      exit 0
    ;;
    *)
    ;;
  esac
  shift
done

INSTALL_PATH=$(dirname $0)

RED='\e[0;31m'
GREEN='\e[0;32m'
BLUE='\e[0;34m'
RED_BOLD='\e[1;31m'
GREEN_BOLD='\e[1;32m'
BLUE_BOLD='\e[1;34m'
NC='\e[0m' # No Color

echo -e " "
echo -e "${BLUE_BOLD}============ Tecnología Integral S.A. ============${NC}"
echo -e "${BLUE_BOLD}=========== TEMPERA System Uninstaller ===========${NC}"
echo -e "${BLUE_BOLD}==================================================${NC}"
echo -e " "
echo -e "Installation path: ${INSTALL_PATH}"
echo -e " "

if [ $CONFIRM != "1" ]
then
  echo 'Are you sure you want to remove this software? [yes/no]'
  read OPTION 'yes' 'no'
else
  OPTION=yes
fi

if [[ ${OPTION} == yes ]]; then
  echo -e "${GREEN_BOLD}* Stopping docker-compose ... ${NC}"
  docker-compose -f ${INSTALL_PATH}/docker-compose.yml stop

  CONTAINERS=$(docker ps -a | awk '{print $NF}' | grep 'tempera_')

  echo -e "${GREEN_BOLD}* Stopping docker containers ... ${NC}"
  docker stop ${CONTAINERS}
  docker stop mbed_compiler_1

  echo -e "${GREEN_BOLD}* Removing docker containers ... ${NC}"
  docker rm -f ${CONTAINERS}
  docker rm -f mbed_compiler_1

  IMAGES=$(docker images | grep 'tempera_' | awk '{print $3}')
  echo -e "${GREEN_BOLD}* Removing docker images ... ${NC}"
  docker rmi -f ${IMAGES}

  echo -e "${GREEN_BOLD}* Removing installation folder ${INSTALL_PATH} ... ${NC}"
  rm -rf $INSTALL_PATH

  rm -rf /tmp/tmp.*

  systemctl daemon-reload
  rm -rf /root/tempera-server
  echo -e "${GREEN_BOLD}Software removed. ${NC}"

else
  echo -e "${GREEN_BOLD}Canceled. ${NC}"

fi
exit 0
