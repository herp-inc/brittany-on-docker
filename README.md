# brittany-on-docker

[![CircleCI](https://circleci.com/gh/herp-inc/brittany-on-docker.svg?style=svg)](https://circleci.com/gh/herp-inc/brittany-on-docker)
[![MicroBadger](https://images.microbadger.com/badges/image/herpinc/brittany.svg)](https://microbadger.com/images/herpinc/brittany)
[![Docker Pulls](https://img.shields.io/docker/pulls/herpinc/brittany)](https://hub.docker.com/r/herpinc/brittany)

a docker image for [brittany](https://github.com/lspitzner/brittany/) haskell source code formatter. See [herpinc/brittany on Docker Hub](https://hub.docker.com/r/herpinc/brittany/tags) to list all available tags.

## Usage

```shell
alias brittany="docker run --rm -v $(pwd):/work herpinc/brittany:latest brittany"
```

## Build

You can use `./scripts/build.sh` to build an image locally for a specific version of brittany.

```shell
# usage: ./scripts/build.sh <image_name> <version>
./scripts/build.sh brittany:0.12.1.1 0.12.1.1
```
