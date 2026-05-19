#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

NAMESPACE="${DOCKERHUB_NAMESPACE:-parvesshikder}"
TAG="${IMAGE_TAG:-latest}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
PUSH="${PUSH:-0}"
DRY_RUN="${DRY_RUN:-0}"

image_specs=(
  "event-ticketing-api-gateway|API_GATEWAY_CONTEXT|api-gateway"
  "event-ticketing-booking-service|BOOKING_SERVICE_CONTEXT|booking-service"
  "event-ticketing-payment-service|PAYMENT_SERVICE_CONTEXT|payment-service"
  "event-ticketing-frontend|FRONTEND_CONTEXT|frontend-event-ticketing|frontend"
)

resolve_context() {
  local env_var="$1"
  shift

  local configured="${!env_var:-}"
  local candidate

  if [[ -n "${configured}" ]]; then
    if [[ "${configured}" = /* ]]; then
      candidate="${configured}"
    else
      candidate="${ROOT_DIR}/${configured}"
    fi

    if [[ -d "${candidate}" ]]; then
      echo "${candidate}"
      return
    fi

    echo "Configured ${env_var} does not exist: ${candidate}" >&2
    exit 1
  fi

  for candidate in "$@"; do
    candidate="${ROOT_DIR}/${candidate}"
    if [[ -d "${candidate}" ]]; then
      echo "${candidate}"
      return
    fi
  done

  echo "Could not find a build context for ${env_var}. Checked: $*" >&2
  exit 1
}

ensure_buildx() {
  docker buildx inspect >/dev/null 2>&1 || docker buildx create --use >/dev/null
  docker buildx inspect --bootstrap >/dev/null
}

build_image() {
  local spec="$1"
  local parts name env_var context ref

  IFS="|" read -r -a parts <<< "${spec}"
  name="${parts[0]}"
  env_var="${parts[1]}"
  context="$(resolve_context "${env_var}" "${parts[@]:2}")"
  ref="${NAMESPACE}/${name}:${TAG}"

  if [[ "${DRY_RUN}" == "1" ]]; then
    if [[ "${PUSH}" == "1" ]]; then
      echo "Would build and push ${ref} for ${PLATFORMS} from ${context}"
    else
      echo "Would build local ${ref} from ${context}"
    fi
    return
  fi

  if [[ "${PUSH}" == "1" ]]; then
    docker buildx build \
      --platform "${PLATFORMS}" \
      -t "${ref}" \
      --push \
      "${context}"
  else
    docker build -t "${ref}" "${context}"
  fi
}

if [[ "${PUSH}" == "1" && "${DRY_RUN}" != "1" ]]; then
  ensure_buildx
fi

for spec in "${image_specs[@]}"; do
  build_image "${spec}"
done

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "Dry run complete for tag ${NAMESPACE}/*:${TAG}"
elif [[ "${PUSH}" == "1" ]]; then
  echo "Built and pushed multi-platform images for ${PLATFORMS} with tag ${NAMESPACE}/*:${TAG}"
else
  echo "Built local current-platform images with tag ${NAMESPACE}/*:${TAG}"
  echo "Use ./scripts/push-images.sh to publish multi-platform Docker Hub images."
fi
