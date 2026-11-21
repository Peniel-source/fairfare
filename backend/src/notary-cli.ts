//reads the real corridor prices and prints today's fingerprint.
//the command is npm run notary
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { NotaryService } from './notary/notary.service.js';

async function main() {
  //starts the app's parts without opening a web server
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error'],
  });

  const notary = app.get(NotaryService);
  const command = process.argv[2];

  if (command === 'send') {
    //npm run notary -- send
    const result = await notary.notarize();
    console.log('date:        ' + result.date);
    console.log('fingerprint: ' + result.hash);
    console.log('sent:        ' + result.sent);
    console.log('tx id:       ' + result.txHash);
    console.log('status:      ' + result.status);
  } else if (command === 'confirm') {
    //npm run notary -- confirm
    const count = await notary.confirmPending();
    console.log('newly confirmed: ' + count);
  } else {
    //npm run notary
    const result = await notary.todaysFingerprint();
    console.log('date:        ' + result.date);
    console.log('routes:      ' + result.routes);
    console.log('fingerprint: ' + result.hash);
  }

  await app.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});