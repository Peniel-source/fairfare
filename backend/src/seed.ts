import { NestFactory } from '@nestjs/core';
import { Timestamp } from 'firebase-admin/firestore';
import { AppModule } from './app.module.js';
import { FirebaseService } from './firebase/firebase.service.js';
import { COLLECTIONS } from './firebase/firestore-paths.js';
import { CorridorsService } from './corridors/corridors.service.js';


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

//making reverse direction for the same route
const allRoutes: typeof startingRoutes = [];
for (const route of startingRoutes) {
  allRoutes.push(route);
  allRoutes.push({ from: route.to, to: route.from, prices: route.prices });
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

  for (const route of allRoutes) {
    const corridorId = makeId(route.from, route.to);

    //the corridor itself
    await db.collection(COLLECTIONS.corridors).doc(corridorId).set({
      fromArea: route.from,
      toArea: route.to,
      isSeeded: true,
      createdAt: now,
    });

    //one seed report per price. all of them are saved as verified for now
    for (let i = 0; i < route.prices.length; i++) {
      await db
        .collection(COLLECTIONS.reports)
        .doc('seed-' + corridorId + '-' + (i + 1))
        .set({
          corridorId: corridorId,
          price: route.prices[i],
          timeSegment: 'midday',
          weather: 'clear',
          status: 'verified',
          isSeeded: true,
          createdAt: now,
          verifiedAt: now,
        });
    }

    //calls the corridor service to work out and save the stats fir this corridor
    await corridorsService.updateCorridorStats(corridorId);
    console.log('done: ' + corridorId + ' (' + route.prices.length + ' prices)');
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