#!/usr/bin/env node

const gatewayBase = process.env.API_GATEWAY_URL ?? 'http://localhost:8080';
const eventBase = process.env.EVENT_SERVICE_URL ?? 'http://localhost:8083';
const venueBase = process.env.VENUE_SERVICE_URL ?? 'http://localhost:8084';
const ticketingBase = process.env.TICKETING_SERVICE_URL ?? 'http://localhost:8091';

const demoEvents = [
  {
    title: 'Enterprise Systems Live Demo',
    description: 'A complete microservice demo with event discovery, ticket inventory, booking and payments.',
    category: 'Conference',
    organizerId: 10,
    startDateTime: '2026-05-22T19:30:00',
    endDateTime: '2026-05-22T22:30:00',
    venue: {
      name: 'Tallinn Creative Hub',
      location: 'Tallinn',
      capacity: 500
    },
    ticketTypes: [
      { typeName: 'General admission', price: 25, currency: 'EUR', totalQuantity: 120 },
      { typeName: 'Student ticket', price: 12, currency: 'EUR', totalQuantity: 50 }
    ]
  },
  {
    title: 'Startup Pitch Night',
    description: 'Founders pitch to investors with reserved seating and limited premium tickets.',
    category: 'Business',
    organizerId: 10,
    startDateTime: '2026-05-26T18:00:00',
    endDateTime: '2026-05-26T21:00:00',
    venue: {
      name: 'Delta Centre Auditorium',
      location: 'Tartu',
      capacity: 320
    },
    ticketTypes: [
      { typeName: 'General admission', price: 18, currency: 'EUR', totalQuantity: 180 },
      { typeName: 'Founder table', price: 79, currency: 'EUR', totalQuantity: 18 }
    ]
  }
];

async function main() {
  await waitFor(`${gatewayBase}/actuator/health`, 'API Gateway');
  await waitFor(`${eventBase}/events`, 'Event Service');
  await waitFor(`${venueBase}/venues`, 'Venue Service');
  await waitFor(`${ticketingBase}/events/00000000-0000-0000-0000-000000000001/tickettypes`, 'Ticketing Service');

  const seeded = [];
  for (const demoEvent of demoEvents) {
    const venue = await ensureVenue(demoEvent.venue);
    const event = await ensureEvent(demoEvent, venue);
    const ticketTypes = await ensureTicketTypes(event, demoEvent.ticketTypes);
    seeded.push({
      eventId: event.eventId ?? event.id,
      title: event.title,
      ticketingEventId: eventToTicketingUuid(event.eventId ?? event.id),
      ticketTypes: ticketTypes.length
    });
  }

  console.log('Seeded real demo data:');
  for (const item of seeded) {
    console.log(`- ${item.title}: event ${item.eventId}, ticketing event ${item.ticketingEventId}, ${item.ticketTypes} ticket types`);
  }
  console.log(`Frontend: http://localhost:8088`);
  console.log(`Gateway events: ${gatewayBase}/api/events`);
}

async function ensureVenue(venueRequest) {
  const venues = await getCollection(`${venueBase}/venues`);
  const existing = venues.find((venue) => sameText(venue.name, venueRequest.name));
  if (existing) {
    return existing;
  }
  return requestJson(`${venueBase}/venues`, {
    method: 'POST',
    body: JSON.stringify(venueRequest)
  });
}

async function ensureEvent(demoEvent, venue) {
  const events = await getCollection(`${eventBase}/events`);
  const existing = events.find((event) => sameText(event.title, demoEvent.title));
  if (existing) {
    return ensurePublished(existing);
  }

  const venueId = venue.id ?? venue.venueId;
  const created = await requestJson(`${eventBase}/events`, {
    method: 'POST',
    body: JSON.stringify({
      title: demoEvent.title,
      description: demoEvent.description,
      category: demoEvent.category,
      organizerId: demoEvent.organizerId,
      venueId,
      startDateTime: demoEvent.startDateTime,
      endDateTime: demoEvent.endDateTime,
      status: 'PUBLISHED'
    })
  });
  return ensurePublished(created);
}

async function ensurePublished(event) {
  const eventId = event.eventId ?? event.id;
  if (sameText(event.status, 'PUBLISHED')) {
    return event;
  }
  return requestJson(`${eventBase}/events/${eventId}/status?status=PUBLISHED`, {
    method: 'PATCH'
  });
}

async function ensureTicketTypes(event, ticketTypeRequests) {
  const eventId = event.eventId ?? event.id;
  const ticketingEventId = eventToTicketingUuid(eventId);
  const existing = await getTicketTypes(ticketingEventId);
  const created = [...existing];

  for (const ticketType of ticketTypeRequests) {
    if (existing.some((item) => sameText(item.typeName ?? item.name, ticketType.typeName))) {
      continue;
    }
    created.push(await requestJson(`${ticketingBase}/events/${ticketingEventId}/tickettypes`, {
      method: 'POST',
      body: JSON.stringify(ticketType)
    }));
  }

  return created;
}

async function getTicketTypes(ticketingEventId) {
  const response = await fetch(`${ticketingBase}/events/${ticketingEventId}/tickettypes`);
  if (response.status === 404) {
    return [];
  }
  if (!response.ok) {
    throw new Error(`Ticketing Service returned HTTP ${response.status}: ${await response.text()}`);
  }
  return unwrapCollection(await readJson(response));
}

async function getCollection(url) {
  return unwrapCollection(await requestJson(url));
}

async function waitFor(url, label) {
  const deadline = Date.now() + 60_000;
  let lastError = '';
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url);
      if (response.ok || response.status === 404) {
        return;
      }
      lastError = `HTTP ${response.status}`;
    } catch (error) {
      lastError = error.message;
    }
    await sleep(1500);
  }
  throw new Error(`${label} did not become ready at ${url}: ${lastError}`);
}

async function requestJson(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      Accept: 'application/json',
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...(options.headers ?? {})
    }
  });
  if (!response.ok) {
    throw new Error(`${url} returned HTTP ${response.status}: ${await response.text()}`);
  }
  return readJson(response);
}

async function readJson(response) {
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

function unwrapCollection(payload) {
  if (Array.isArray(payload)) {
    return payload;
  }
  if (Array.isArray(payload?.content)) {
    return payload.content;
  }
  if (Array.isArray(payload?.items)) {
    return payload.items;
  }
  if (Array.isArray(payload?.data)) {
    return payload.data;
  }
  return [];
}

function eventToTicketingUuid(eventId) {
  const numericId = BigInt(eventId);
  if (numericId <= 0n || numericId > 0xffffffffffffn) {
    throw new Error(`Event id ${eventId} is outside the bridgeable range`);
  }
  return `00000000-0000-0000-0000-${numericId.toString(16).padStart(12, '0')}`;
}

function sameText(left, right) {
  return String(left ?? '').trim().toLowerCase() === String(right ?? '').trim().toLowerCase();
}

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
