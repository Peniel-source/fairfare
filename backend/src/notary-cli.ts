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

  if (process.argv[2] === 'send') {
    //npm run notary -- send
    const result = await notary.notarize();
    console.log('date:        ' + result.date);
    console.log('fingerprint: ' + result.hash);
    console.log('sent:        ' + result.sent);
    console.log('tx id:       ' + result.txHash);
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