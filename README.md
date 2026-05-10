# Event Ticketing Infra

This folder contains the Docker Compose setup for the currently active microservices.

It starts only the services that are being worked on right now:

- Frontend
- API Gateway
- Booking Service
- Payment Service
- Booking PostgreSQL database
- Payment PostgreSQL database

## Run Everything

From this folder:

```bash
docker compose up --build
```

Open the frontend:

```text
http://localhost:8088
```

## Service URLs

- Frontend: http://localhost:8088
- API Gateway: http://localhost:8080
- Booking service: http://localhost:8081
- Payment service: http://localhost:8082

## Test The API Buttons

The frontend has three buttons:

- `Test Gateway`
- `Test Booking`
- `Test Payment`
- `Test Booking + Payment`

They call the gateway endpoints:

```text
/api/demo/gateway
/api/demo/booking
/api/demo/payment
/api/demo/booking-payment
```

The booking and payment checks go through the API Gateway and then check each service health endpoint.

The booking-payment check is the main integration demo. It calls Booking Service through the gateway, then Booking Service creates a real payment by calling Payment Service.

## Stop Everything

```bash
docker compose down
```

To also delete database volumes:

```bash
docker compose down -v
```

## Rebuild After Code Changes

```bash
docker compose up --build
```
