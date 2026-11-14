import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  App,
  cert,
  getApp,
  getApps,
  initializeApp,
} from 'firebase-admin/app';
import { Firestore, getFirestore } from 'firebase-admin/firestore';

@Injectable()
export class FirebaseService {
  private readonly app: App;

  constructor(config: ConfigService) {
    if (getApps().length > 0) {
      this.app = getApp();
      return;
    }

    const projectId = config.getOrThrow<string>('FIREBASE_PROJECT_ID');

    if (process.env.FIRESTORE_EMULATOR_HOST) {
      this.app = initializeApp({ projectId });
    } else {
      this.app = initializeApp({
        credential: cert({
          projectId,
          clientEmail: config.getOrThrow<string>('FIREBASE_CLIENT_EMAIL'),
          privateKey: config
            .getOrThrow<string>('FIREBASE_PRIVATE_KEY')
            .replace(/\\n/g, '\n'),
        }),
      });
    }
  }

  get firestore(): Firestore {
    return getFirestore(this.app);
  }
}