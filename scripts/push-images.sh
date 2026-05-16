#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${DOCKERHUB_NAMESPACE:-parvesshikder}"
TAG="${IMAGE_TAG:-latest}"

images=(
  event-ticketing-api-gateway
  event-ticketing-booking-service
  event-ticketing-payment-service
  event-ticketing-frontend
)

for image in "${images[@]}"; do
  docker push "${NAMESPACE}/${image}:${TAG}"
done

echo "Pushed common images to Docker Hub namespace ${NAMESPACE} with tag ${TAG}"
