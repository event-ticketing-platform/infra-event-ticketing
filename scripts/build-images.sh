#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

NAMESPACE="${DOCKERHUB_NAMESPACE:-parvesshikder}"
TAG="${IMAGE_TAG:-latest}"

build_image() {
  local name="$1"
  local context="$2"
  docker build -t "${NAMESPACE}/${name}:${TAG}" "${ROOT_DIR}/${context}"
}

build_image event-ticketing-api-gateway api-gateway
build_image event-ticketing-booking-service booking-service
build_image event-ticketing-payment-service payment-service
build_image event-ticketing-frontend frontend

echo "Built common images with tag ${NAMESPACE}/*:${TAG}"
