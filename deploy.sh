#!/bin/bash
set -e

############# LEER PARAMETROS ###############
BUILD_ONLY="0"
INTEGRATION_TESTING="0"
while [[ $# > 0 ]]
do
  key="$1"
  case $key in
    -b|--build-only)
      BUILD_ONLY="1"
    ;;
    -n|--no-cache)
      NO_CACHE=" --no-cache "
    ;;
    -t|--test)
      INTEGRATION_TESTING="1"
    ;;
    -h|--help)
      echo "TODO: Agregar una ayuda que sirva, por ahora -b es la unica opcion."
      exit 0
    ;;
    *)
    ;;
  esac
  shift
done

IMAGES=""
#############################################
OUT=$(mktemp -d) || exit 1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "DIR: ${DIR}"
VERSION=$(sh ${DIR}/scripts/version_info.sh | \
    sed s/@/_/ | \
    sed s/+/-/g)
TAG=$(echo $VERSION | sed s/-.*//g)
echo "Deploy TAG: ${TAG}"

RED='\e[0;31m'
GREEN='\e[0;32m'
BLUE='\e[0;34m'
RED_BOLD='\e[1;31m'
GREEN_BOLD='\e[1;32m'
BLUE_BOLD='\e[1;34m'
NC='\e[0m' # No Color

#### Update images from DockerHub #############################################

echo -e "${GREEN_BOLD}* Updating tidocker_mbed from DockerHub ${NC}"
docker pull tecintegral/tidocker_mbed:latest

#############################################

cp -r ${DIR}/scripts/ ${OUT}

echo -e "${GREEN}* Downloading MQTT image...  ${NC}"
docker pull eclipse-mosquitto

IMAGES+="eclipse-mosquitto:latest "
###imagen de los contenedores####
echo -e "${GREEN}* Downloading Alpine Linux image...  ${NC}"
docker pull alpine:3.12
echo -e "${GREEN}* Downloading Centos Linux image...  ${NC}"
docker pull centos:7

echo -e "${GREEN}* Creating minihttp server image...  ${NC}"

docker build . -f docker/http/Dockerfile \
    -t tempera_minihttp:${TAG} -t tempera_minihttp:latest

IMAGES+="tempera_minihttp:${TAG} tempera_minihttp:latest "

echo -e "${GREEN}* Creating NTP server image...  ${NC}"

docker build . -f docker/ntp/Dockerfile \
    -t tempera_ntp:latest  -t tempera_ntp:${TAG}

IMAGES+="tempera_ntp:latest tempera_ntp:${TAG} "

echo -e "${GREEN}* Creating DHCP server image...  ${NC}"

docker build . -f docker/dhcp/Dockerfile \
    -t tempera_dhcp:latest -t tempera_dhcp:${TAG}

IMAGES+="tempera_dhcp:latest tempera_dhcp:${TAG} "


##### Integration test (TODO)
if [ $INTEGRATION_TESTING == "1" ]
then
  echo -e "${GREEN}* Integration Testing ...  ${NC}"

  # TODO use mktemp in final version
  TEST_INSTALL_PATH=$(pwd)/tmp_install

  # run installer
  scripts/installer.sh --install-path $TEST_INSTALL_PATH

  # add testing code here

  # run unistaller
  tmp_install/uninstall.sh --skip-confirm

  # add unistall test code here

  exit 0
fi


##### Finalizando proceso

if [ $BUILD_ONLY != "0" ]
then
    echo -e "${GREEN}* Finished creating TEMEPERA System images.  ${NC}"
    exit 0
fi

echo -e "${GREEN}* Saving TEMEPERA System images...  ${NC}"

docker save ${IMAGES} > ${OUT}/tempera-installer.tar
echo "Done."

###########generacion del tar######################
echo -e "${GREEN}* Generating tarball ... ${NC}"

VERSION=$(sh ${DIR}/scripts/version_info.sh )
tar czvf out.tar.gz -C ${OUT}/ $(ls ${OUT})

echo -e "${GREEN}* Generating installer tempera-installer-${VERSION}.run ...  ${NC}"
cat ${DIR}/scripts/installer.sh out.tar.gz > tempera-installer-${VERSION}.run
chmod +x tempera-installer-${VERSION}.run
echo -e "${GREEN}* Deleting temporal files and folders ... ${NC}"
rm -rf out.tar.gz
rm -rf ${OUT}
echo -e "${GREEN}* Installer gerated succesfully.${NC}"
