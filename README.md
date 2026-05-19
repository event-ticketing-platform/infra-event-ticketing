# Event Ticketing Infra

Common Docker Compose runtime for Assignment 3.

## Files

| File | Use |
| --- | --- |
| `docker-compose.yml` | Local source build for this repo |
| `docker-compose.hub.yml` | Pull-only runtime from Docker Hub |
| `docker-compose.team.yml` | Overlay for teammate services |
| `.env.example` | Shared ports, tags, and JWT settings |
| `scripts/build-images.sh` | Build local common images with Docker Hub tags |
| `scripts/push-images.sh` | Build and push multi-platform common images |
| `scripts/pull-images.sh` | Pull common images |
| `scripts/verify-images.sh` | Verify Docker Hub images include required platforms |
| `scripts/seed-real-demo.mjs` | Seed demo venues, events, and Ticketing inventory through service APIs |

## Local Source Run

```bash
docker compose up --build
```

This builds this repo's API Gateway, Booking, Payment, and Frontend images. It also pulls the teammate images currently available:

- `deb0tush/user-service:latest`
- `mohoshena/event-service:latest`

Open:

```text
http://localhost:8088
```

For real Stripe test payments, copy `.env.example` to `.env` and set `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, and optionally `STRIPE_WEBHOOK_SECRET` before starting Compose. Blank Stripe keys are allowed for development, but checkout will stop with a configuration error until keys are set.

## Docker Hub Run

```bash
cp .env.example .env
docker compose -f docker-compose.hub.yml pull
docker compose -f docker-compose.hub.yml up
```

The Docker Hub compose file uses `pull_policy: always` for the common app images, so `up` also checks the registry for updated tags.

## Full Team Run

Use this after the remaining teammates publish their images:

```bash
docker compose -f docker-compose.hub.yml -f docker-compose.team.yml up
```

The base Compose file already runs:

- `api-gateway` on `8080`
- `event-service` on `8083`
- `user-service` on `8090`

The team overlay adds the remaining placeholders:

- `venue-service` on `8084` using `mohoshena/venue-service:latest`
- `ticketing-service` on `8091` using `deb0tush/ticketing-service:latest`
- `checkin-service` on `8086` using `muhammadafaq1/attendee-checkin-service:latest`
- `reporting-service` on `8087` using `muhammadafaq1/analytics-service:latest`

It also changes gateway routing so `/api/events/**` goes to Event, numeric `/api/events/{eventId}/tickettypes` and `/api/events/{eventId}/ticket-types` go to Ticketing through the gateway's Event ID bridge, `/api/ticket-types/**` and `/api/tickets/**` go to Ticketing, `/api/venues/**` goes to Venue, `/api/users/**` goes to User, `/api/checkins/**` goes to Check-in, and `/api/reports/**` goes to Reporting.

`rabbitmq-setup` is a one-shot setup container. It exits with code `0` after exchanges, queues, and bindings are created. The broker that must stay running is `event-ticketing-rabbitmq`; it exposes AMQP on `5672` and the management UI on `15672`.

Seed real class-demo data after the stack is started:

```bash
node scripts/seed-real-demo.mjs
```

The seeder creates Venue Service venues, Event Service events, publishes those events, and creates Ticketing Service ticket types. The frontend then reads events from Event Service and tickets from Ticketing Service rather than the old Booking catalog.

## Docker Hub Publishing

```bash
docker login
DOCKERHUB_NAMESPACE=parvesshikder IMAGE_TAG=latest ./scripts/push-images.sh
DOCKERHUB_NAMESPACE=parvesshikder IMAGE_TAG=latest ./scripts/verify-images.sh
```

`push-images.sh` uses Docker Buildx and publishes `linux/amd64,linux/arm64` by default, so the same image tag works on Windows, Linux, Intel Mac, and Apple Silicon Mac. Override `PLATFORMS` only when you intentionally need a different platform list.

For local testing without publishing, run:

```bash
DOCKERHUB_NAMESPACE=parvesshikder IMAGE_TAG=latest ./scripts/build-images.sh
```

The service repos also include a GitHub Actions workflow that publishes the same multi-platform images on pushes to `main` or `master`, and from manual `workflow_dispatch` runs. Add these repository secrets in each service repo:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

The common image names are:

- `parvesshikder/event-ticketing-api-gateway:latest`
- `parvesshikder/event-ticketing-booking-service:latest`
- `parvesshikder/event-ticketing-payment-service:latest`
- `parvesshikder/event-ticketing-frontend:latest`

Current teammate image names:

- `mohoshena/event-service:latest`
- `deb0tush/user-service:latest`
- `deb0tush/ticketing-service:latest`

Expected remaining teammate image names:

- `mohoshena/venue-service:latest`
- `muhammadafaq1/attendee-checkin-service:latest`
- `muhammadafaq1/analytics-service:latest`

## Stop

```bash
docker compose down
```

Delete local volumes:

```bash
docker compose down -v
```
