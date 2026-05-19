#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${DOCKERHUB_NAMESPACE:-parvesshikder}"
TAG="${IMAGE_TAG:-latest}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

images=(
  event-ticketing-api-gateway
  event-ticketing-booking-service
  event-ticketing-payment-service
  event-ticketing-frontend
)

IFS="," read -r -a required_platforms <<< "${PLATFORMS}"

for image in "${images[@]}"; do
  ref="${NAMESPACE}/${image}:${TAG}"
  output="$(docker buildx imagetools inspect "${ref}")"

  for platform in "${required_platforms[@]}"; do
    if ! grep -q "Platform:[[:space:]]*${platform}" <<< "${output}"; then
      echo "Missing ${platform} manifest for ${ref}" >&2
      exit 1
    fi
  done

  echo "OK ${ref} has ${PLATFORMS}"
done

echo "All common images have the required platform manifests."
