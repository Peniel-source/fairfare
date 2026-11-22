import { Controller, Get } from '@nestjs/common';
import { FirebaseService } from './firebase/firebase.service.js';

@Controller()
export class AppController {
  constructor(private readonly firebase: FirebaseService) {}

  @Get('health')
  async health() {
    await this.firebase.firestore.doc('health/ping').get();
    return { status: 'ok' };
  }
}