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
#### Construir imagen de deploy TEMPERA-TIS #####################################

echo -e "${GREEN_BOLD}* Compiling TEMPERA-TIS in mbed container ...${NC}"

ARM_COMPILER="GCC_ARM"
TARGET="NUCLEO_F429ZI"

ARCH_DIR="${DIR}/docker/TIS/tmp"
BIN_DIR="${ARCH_DIR}/BUILD/${TARGET}/${ARM_COMPILER}/"
# echo "BIN_vDIR: ${BIN_DIR}"
rm -rf ${ARCH_DIR}
mkdir -p ${ARCH_DIR}
git --git-dir=${DIR}/src/tempera-tis/.git --work-tree=${DIR}/src/tempera-tis/ archive HEAD | tar xf - -C ${ARCH_DIR}
TIS_VERSION=$(sh ${DIR}/scripts/version_info.sh -d ${DIR}/src/tempera-tis)
# echo "TIS_VERSION: ${TIS_VERSION}"
BIN_TAG_NAME="tempera-tis-${TIS_VERSION}.bin"
# echo "BIN_TAG_NAME: ${BIN_TAG_NAME}"

if [ ! -f "$BIN_TAG_NAME" ]; then
  echo -e "${GREEN}* Creating tecintegral/tidocker_mbed container ...${NC}"

  ## Create mbed comiler container
  if [ ! "$(docker ps -q -f name=mbed_compiler_1)" ]; then
    docker run -d -v ${ARCH_DIR}:/tempera-tis:z -w /tempera-tis --name mbed_compiler_1 tecintegral/tidocker_mbed tail -f /dev/null
  fi
  echo -e "${GREEN}* Compiling tempera-tis ...${NC}"
  ## Create mbed project
  docker exec -it mbed_compiler_1 mbed new .
  ## Compile mbed project
  docker exec -it mbed_compiler_1 mbed compile -t GCC_ARM -m NUCLEO_F429ZI

  BIN_NAME=$(basename $BIN_DIR/*.bin)
  BIN_SHORT_NAME=${BIN_NAME%.*}
  BIN_TAG_NAME="${BIN_SHORT_NAME}-${TIS_VERSION}.bin"
  # echo "BIN_TAG_NAME: ${BIN_TAG_NAME}"

  ## Copy output binaries to root folder
  cp $BIN_DIR$BIN_NAME $BIN_TAG_NAME
  # echo "File name: $BIN_DIR$BIN_NAME"
  ## Delete mbed build files
  docker exec -it mbed_compiler_1 rm -rf BUILD mbed-os .git __pycache__

  ## Stop and remove containers
  echo -e "${GREEN}* Removing tecintegral/tidocker_mbed container ...${NC}"
  docker stop mbed_compiler_1
  docker rm --volumes mbed_compiler_1

  rm -rf ${ARCH_DIR}
else
  echo -e "Binary file ${BIN_TAG_NAME} already exists."
fi

echo -e "${GREEN}* Copying files... ${NC}"
cp ${DIR}/${BIN_TAG_NAME} ${DIR}/scripts
cp -r ${DIR}/scripts/ ${OUT}

echo -e "${GREEN}* Downloading MQTT image...  ${NC}"
docker pull eclipse-mosquitto
#docker build . -f docker/mqtt/Dockerfile \
#    -t tempera_mqtt:${TAG} -t tempera_mqtt:latest

#IMAGES+="eclipse-mosquitto:${TAG} eclipse-mosquitto:latest "
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
