# TEMPERA System#

## Build

##### Clone repository with submodules
```
$ git clone git@bitbucket.org:idtecnologiaintegral/tempera-deploy.git --recurse-submodules
$ cd tempera-deploy
$ git submodule update --init --recursive
```

##### Build Docker images and installer
```
$ ./deploy.sh
```

##### Build only Docker images
```
$ ./deploy.sh --build-only
```

## Install
