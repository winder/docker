#!/usr/bin/env bash

set -e

CWD=$(pwd)

echo "Running docker deploy script at $(date)"
echo "CWD: $CWD"

help() {
  echo "Clone / update a go-algorand git repository and attempt to build"
  echo "docker containers."
  echo ""
  echo "Arguments:"
  echo " -d <dir>   directory with algod dockerfile"
  echo " -g <dir>   location to create or look for git repository"
  echo " -n <name>  name of container to publish"
}

if ! docker login; then
  echo "Must be authenticated with 'docker login' to run this script."
  exit 1
fi

while getopts "d:g:n:" opt; do
  case "$opt" in
    d) DOCKER_DIR=$OPTARG; ;;
    g) GIT_DIR=$OPTARG; ;;
    n) IMAGE_NAME=$OPTARG; ;;
    *) echo "unknown flag"; help; exit 1;;
  esac
done

if [ -z "$DOCKER_DIR" ]; then
  echo "docker directory must be provided with '-d <docker dir>'"
  exit 1
fi

if [ -z "$GIT_DIR" ]; then
  echo "git directory must be provided with '-g <git dir>'"
  exit 1
fi

if [ -z "$IMAGE_NAME" ]; then
  echo "image name must be provided with '-n <name>'"
  exit 1
fi

echo "Parameters:"
echo " DOCKER_DIR = $DOCKER_DIR"
echo " GIT_DIR    = $CWD/$GIT_DIR"
echo " IMAGE_NAME = $IMAGE_NAME"

# Attempt to build and push a container.
# Multiple labels can be provided. 
# arguments:
#   commit hash
#   one or more image labels
build_and_push_container() {
  # both arguments are required.
  if [ "$#" -lt 2 ]; then
    echo "build_and_push_container: two arguments required $# arguments provided."
    exit 1
  fi

  local COMMIT_HASH="$1"
  shift

  local FIRST_TAG="$1"
  local DEFAULT_TAG="$IMAGE_NAME:$1"
  shift

  # if the container already exists, exit
  if docker manifest inspect "$DEFAULT_TAG" > /dev/null 2>&1; then
    echo "Skipping build for: $DEFAULT_TAG ($FIRST_TAG $@)"
    return
  fi

  echo "Building container for: $DEFAULT_TAG ($FIRST_TAG $@)"

  cd "$DOCKER_DIR"
  docker build \
    -t "$DEFAULT_TAG" \
    --build-arg CHANNEL= \
    --build-arg URL=https://github.com/algorand/go-algorand \
    --build-arg SHA="$COMMIT_HASH" \
    . > "$CWD/docker_build_$FIRST_TAG.log" 2>&1

  echo " * pushing $DEFAULT_TAG"
  docker push "$DEFAULT_TAG" > "$CWD/docker_push_$FIRST_TAG.log" 2>&1

  # If there is more than one tag, create them and push them too.
  for tag in "$@"; do
    local NEW_TAG="$IMAGE_NAME:$tag"
    echo " * pushing $NEW_TAG"
    docker tag "$DEFAULT_TAG" "$NEW_TAG" > "$CWD/docker_push_$tag.log" 2>&1
  done
  echo " Done."
}

# bootstrap directory with go-algorand if it's missing
#git clone git@github.com:algorand/go-algorand.git "$GIT_DIR" || true
git clone https://github.com/algorand/go-algorand.git "$GIT_DIR" || true
pushd "$GIT_DIR"

# get latest tags and check for new stable/beta tags.
git fetch --tags
STABLE_TAG=$(git tag|grep stable|sort -V|tail -n 1)
STABLE_HASH=$(git rev-list -n 1 $STABLE_TAG)
BETA_TAG=$(git tag|grep beta|sort -V|tail -n 1)
BETA_HASH=$(git rev-list -n 1 $BETA_TAG)

# use the head of master for the nightly build.
git checkout master
git pull
NIGHTLY_HASH=$(git log -1 --format=format:"%H")
NIGHTLY_TAG="$(git log -1 --format=format:"%h")-dev"

# no tags for nightly, so grab the latest build number
# look for commit oneline with 'HASHCODE Build 1234 Data'
#NIGHTLY_TAG=$(git log --oneline|grep "[[:alnum:]]\{8\} Build [[:digit:]]\+ Data\$"|head -n 1)

popd

echo "======="
echo "Stable : $STABLE_TAG ($STABLE_HASH)"
echo "Beta   : $BETA_TAG ($BETA_HASH)"
echo "Nightly: $NIGHTLY_TAG ($NIGHTLY_HASH)"
echo "======="

build_and_push_container "$STABLE_HASH" "$STABLE_TAG" "stable" "latest"
build_and_push_container "$BETA_HASH" "$BETA_TAG" "beta"
build_and_push_container "$NIGHTLY_HASH" "$NIGHTLY_TAG" "dev"

echo "------------------------------------"
