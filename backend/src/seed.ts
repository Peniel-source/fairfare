import { NestFactory } from '@nestjs/core';
import { Timestamp } from 'firebase-admin/firestore';
import { AppModule } from './app.module.js';
import { FirebaseService } from './firebase/firebase.service.js';
import { COLLECTIONS } from './firebase/firestore-paths.js';
import { CorridorsService } from './corridors/corridors.service.js';


//current zones. the app finds the one nearest to the phone's location
const zones = [
  { name: 'ALU', latitude: -1.9306, longitude: 30.1529 },
  { name: 'Downtown', latitude: -1.9433, longitude: 30.0596 },
  { name: 'Nyabugogo', latitude: -1.9409, longitude: 30.0447 },
  { name: 'Kacyiru', latitude: -1.9376, longitude: 30.0805 },
  { name: 'Kimihurura', latitude: -1.9528, longitude: 30.0818 },
  { name: 'Remera', latitude: -1.9476, longitude: 30.1061 },
  { name: 'Kimironko', latitude: -1.9384, longitude: 30.1242 },
  { name: 'Nyarutarama', latitude: -1.9396, longitude: 30.1017 },
  { name: 'Gisozi', latitude: -1.9178, longitude: 30.0613 },
  { name: 'Kanombe', latitude: -1.9684, longitude: 30.1384 },
  { name: 'Kicukiro', latitude: -1.9718, longitude: 30.0972 },
  { name: 'Gikondo', latitude: -1.9789, longitude: 30.084 },
  { name: 'Nyamirambo', latitude: -1.9639, longitude: 30.0599 },
  { name: 'Gahanga', latitude: -2.0316, longitude: 30.1097 },
  { name: 'Masaka', latitude: -2.0223, longitude: 30.2032 },
];


//starter routes and placeholder prices
const startingRoutes = [
  { from: 'ALU', to: 'Downtown', prices: [1500, 2000, 2500] },
  { from: 'Kacyiru', to: 'Kimironko', prices: [1000, 1200, 1500] },
  { from: 'Kimironko', to: 'Downtown', prices: [1200, 1500, 1800] },
  { from: 'Remera', to: 'Downtown', prices: [1000, 1200, 1500] },
  { from: 'Nyabugogo', to: 'Remera', prices: [1500, 1800, 2000] },
  { from: 'Kicukiro', to: 'Downtown', prices: [1200, 1500, 1800] },
  { from: 'Gikondo', to: 'Downtown', prices: [1000, 1300, 1500] },
  { from: 'Nyarutarama', to: 'Kimironko', prices: [1000, 1200, 1500] },
  { from: 'Gisozi', to: 'Kacyiru', prices: [800, 1000, 1200] },
  { from: 'Kanombe', to: 'Remera', prices: [1500, 2000, 2500] },
];


//creating an id for the corridors. like: alu to downtown will be alu-downtown
function makeId(from: string, to: string) {
  return (from + '-' + to).toLowerCase().replace(/\s+/g, '-');
}

//zone id is in lowercase
function makeZoneId(name: string) {
  return name.toLowerCase().replace(/\s+/g, '-');
}

//making reverse direction for the same route
const allRoutes: typeof startingRoutes = [];
for (const route of startingRoutes) {
  allRoutes.push(route);
  allRoutes.push({ from: route.to, to: route.from, prices: route.prices });
}

//find the prices of a route by the id of its corridor
const pricesById = new Map<string, number[]>();
for (const route of allRoutes) {
  pricesById.set(makeId(route.from, route.to), route.prices);
}

//seeding
async function seed() {
  // Start the server to use the Firebase connection and stats service
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn'],
  });
  const db = app.get(FirebaseService).firestore;
  const corridorsService = app.get(CorridorsService);

  //show where the data is going
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.log('Seeding the EMULATOR at ' + process.env.FIRESTORE_EMULATOR_HOST);
  } else {
    console.log('Seeding the REAL project: ' + process.env.FIREBASE_PROJECT_ID);
  }

  const now = Timestamp.now();

  //the zones
  for (const zone of zones) {
    await db.collection(COLLECTIONS.zones).doc(makeZoneId(zone.name)).set({
      name: zone.name,
      latitude: zone.latitude,
      longitude: zone.longitude,
    });
  }

  //every zone to every other zone is a corridor
  let corridorCount = 0;
  let pricedCount = 0;

  for (const from of zones) {
    for (const to of zones) {
      if (from.name === to.name) continue;

      const corridorId = makeId(from.name, to.name);

      //the corridor itself
      await db.collection(COLLECTIONS.corridors).doc(corridorId).set({
        fromArea: from.name,
        toArea: to.name,
        isSeeded: true,
        createdAt: now,
      });
      corridorCount++;

      const prices = pricesById.get(corridorId) ?? [];
      if (prices.length === 0) continue;

      //one seed report per price. all of them are saved as verified for now
      for (let i = 0; i < prices.length; i++) {
        await db
          .collection(COLLECTIONS.reports)
          .doc('seed-' + corridorId + '-' + (i + 1))
          .set({
            corridorId: corridorId,
            price: prices[i],
            timeSegment: 'midday',
            weather: 'clear',
            status: 'verified',
            isSeeded: true,
            createdAt: now,
            verifiedAt: now,
          });
      }

      //call the corridor service to find the stats for this corridor
      await corridorsService.updateCorridorStats(corridorId);
      pricedCount++;
      console.log('done: ' + corridorId + ' (' + prices.length + ' prices)');
    }
  }

  console.log(
    'zones: ' + zones.length + ', corridors: ' + corridorCount + ', with prices: ' + pricedCount,
  );

  //every starter route needs both of its areas in the zones list
  if (pricedCount !== allRoutes.length) {
    console.warn('some starter routes use an area that is not in the zones list');
  }

  //shut down server
  await app.close();
}

try {
  await seed();
} catch (err) {
  console.error('seeding failed', err);
  process.exit(1);
}