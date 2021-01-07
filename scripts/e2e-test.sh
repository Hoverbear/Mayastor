#!/usr/bin/env bash

set -eux

SCRIPTDIR=$(dirname "$(realpath "$0")")
# new tests should be added before the replica_pod_remove test
TESTS="install basic_volume_io replica node_disconnect/replica_pod_remove"
DEVICE=
REGISTRY=
TAG=

help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --device <path>           Device path to use for storage pools.
  --registry <host[:port]>  Registry to pull the mayastor images from.
  --tag <name>              Docker image tag of mayastor images (default "ci")

Examples:
  $0 --registry 127.0.0.1:5000 --tag a80ce0c
EOF
}

# Parse arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -d|--device)
      shift
      DEVICE=$1
      shift
      ;;
    -r|--registry)
      shift
      REGISTRY=$1
      shift
      ;;
    -t|--tag)
      shift
      TAG=$1
      shift
      ;;
    -h|--help)
      help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      help
      exit 1
      ;;
  esac
done

if [ -z "$DEVICE" ]; then
  echo "Device for storage pools must be specified"
  help
  exit 1
fi
export e2e_pool_device=$DEVICE
if [ -n "$TAG" ]; then
  export e2e_image_tag="$TAG"
fi
if [ -n "$REGISTRY" ]; then
  export e2e_docker_registry="$REGISTRY"
fi

test_failed=

for dir in $TESTS; do
  cd "$SCRIPTDIR/../test/e2e/$dir"
  if ! go test -v . -ginkgo.v -ginkgo.progress -timeout 0 ; then
    test_failed=1
    break
  fi
  if ! ("$SCRIPTDIR"/e2e_check_pod_restarts.sh) ; then
      test_failed=1
      break
  fi
done

if [ -n "$test_failed" ]; then
    "$SCRIPTDIR"/e2e-cluster-dump.sh
fi

# must always run uninstall test in order to clean up the cluster
cd "$SCRIPTDIR/../test/e2e/uninstall"
if ! go test -v . -ginkgo.v -ginkgo.progress -timeout 0 ; then
    "$SCRIPTDIR"/e2e-cluster-dump.sh --clusteronly
fi

if [ -n "$test_failed" ]; then
  exit 1
fi

echo "All tests have passed"
exit 0
