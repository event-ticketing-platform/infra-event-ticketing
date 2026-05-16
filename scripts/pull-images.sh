#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${DOCKERHUB_NAMESPACE:-parvesshikder}"
TAG="${IMAGE_TAG:-latest}"
TEAM_TAG="${TEAM_IMAGE_TAG:-latest}"

images=(
  event-ticketing-api-gateway
  event-ticketing-booking-service
  event-ticketing-payment-service
  event-ticketing-frontend
)

for image in "${images[@]}"; do
  docker pull "${NAMESPACE}/${image}:${TAG}"
done

docker pull --platform linux/amd64 "deb0tush/user-service:${TEAM_TAG}"
docker pull --platform linux/amd64 "deb0tush/event-service:${TEAM_TAG}"

echo "Pulled common images from Docker Hub namespace ${NAMESPACE} with tag ${TAG}"
echo "Pulled teammate images deb0tush/user-service:${TEAM_TAG} and deb0tush/event-service:${TEAM_TAG}"
