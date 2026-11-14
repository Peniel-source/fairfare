import { describe, it, expect } from 'vitest';
import { AppController } from './app.controller.js';
import { FirebaseService } from './firebase/firebase.service.js';

describe('AppController', () => {
  it('returns ok when Firestore is reachable', async () => {
    const fake = {
      firestore: { doc: () => ({ get: async () => ({}) }) },
    } as unknown as FirebaseService;

    const controller = new AppController(fake);
    expect(await controller.health()).toEqual({ status: 'ok' });
  });
});