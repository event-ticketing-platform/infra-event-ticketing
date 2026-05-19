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

docker pull --platform linux/amd64 "${USER_SERVICE_IMAGE:-deb0tush/user-service}:${TEAM_TAG}"
docker pull --platform linux/amd64 "${EVENT_SERVICE_IMAGE:-mohoshena/event-service}:${TEAM_TAG}"
docker pull --platform linux/amd64 "${VENUE_SERVICE_IMAGE:-mohoshena/venue-service}:${TEAM_TAG}"
docker pull --platform linux/amd64 "${TICKETING_SERVICE_IMAGE:-deb0tush/ticketing-service}:${TEAM_TAG}"
docker pull --platform linux/amd64 "${CHECKIN_SERVICE_IMAGE:-muhammadafaq1/attendee-checkin-service}:${TEAM_TAG}"
docker pull --platform linux/amd64 "${ANALYTICS_SERVICE_IMAGE:-muhammadafaq1/analytics-service}:${TEAM_TAG}"

echo "Pulled common images from Docker Hub namespace ${NAMESPACE} with tag ${TAG}"
echo "Pulled teammate images ${USER_SERVICE_IMAGE:-deb0tush/user-service}:${TEAM_TAG}, ${EVENT_SERVICE_IMAGE:-mohoshena/event-service}:${TEAM_TAG}, ${VENUE_SERVICE_IMAGE:-mohoshena/venue-service}:${TEAM_TAG}, ${TICKETING_SERVICE_IMAGE:-deb0tush/ticketing-service}:${TEAM_TAG}, ${CHECKIN_SERVICE_IMAGE:-muhammadafaq1/attendee-checkin-service}:${TEAM_TAG}, and ${ANALYTICS_SERVICE_IMAGE:-muhammadafaq1/analytics-service}:${TEAM_TAG}"
