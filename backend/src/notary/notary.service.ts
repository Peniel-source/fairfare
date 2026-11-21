//reads the real prices, builds the daily fingerprint and sends it to Cardano
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FieldValue } from 'firebase-admin/firestore';
import { KoiosProvider, MeshTxBuilder, MeshWallet } from '@meshsdk/core';
import { COLLECTIONS } from '../firebase/firestore-paths.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { fingerprint, type PriceRow } from './fingerprint.js';

@Injectable()
export class NotaryService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly config: ConfigService,
  ) {}

  //today in Kigali, like 2026-11-21
  today(): string {
    return new Date().toLocaleDateString('en-CA', {
      timeZone: 'Africa/Kigali',
    });
  }

  //reads every corridorStats doc and keeps the five facts we lock in
  async readPrices(): Promise<PriceRow[]> {
    const snapshot = await this.firebase.firestore
      .collection(COLLECTIONS.corridorStats)
      .get();

    const rows: PriceRow[] = [];
    for (const doc of snapshot.docs) {
      const data = doc.data();
      rows.push({
        corridorId: doc.id,
        median: Number(data.median),
        low: Number(data.low),
        high: Number(data.high),
        sampleSize: Number(data.sampleSize),
      });
    }
    return rows;
  }

  //the date, the fingerprint and how many routes went into it
  async todaysFingerprint() {
    const date = this.today();
    const rows = await this.readPrices();
    return { date, hash: fingerprint(date, rows), routes: rows.length };
  }

   //true if a receipt for today already exists, whatever the fingerprint was
   async alreadyDoneToday(): Promise<boolean> {
     const found = await this.firebase.firestore
       .collection(COLLECTIONS.notarizations)
       .where('date', '==', this.today())
       .limit(1)
       .get();
     return !found.empty;
   }

  //sends today's fingerprint to Cardano and saves the receipt
  async notarize() {
    const { date, hash, routes } = await this.todaysFingerprint();

    //one receipt per date and fingerprint, so the same one is never sent twice
    const id = date + '-' + hash.slice(0, 8);
    const receipt = this.firebase.firestore
      .collection(COLLECTIONS.notarizations)
      .doc(id);
    const old = await receipt.get();
    if (old.exists) {
      return { sent: false, id, date, hash, txHash: old.data()?.txHash };
    }

    //the server wallet, made earlier with npm run notary:wallet
    const network = this.config.get<string>('NOTARY_NETWORK') ?? 'preview';
    const words = this.config
      .getOrThrow<string>('NOTARY_MNEMONIC')
      .trim()
      .split(/\s+/);

    const provider = new KoiosProvider(network);
    const wallet = new MeshWallet({
      networkId: 0,
      fetcher: provider,
      submitter: provider,
      key: { type: 'mnemonic', words },
    });

    const utxos = await wallet.getUtxos();
    const changeAddress = await wallet.getChangeAddress();

    //a transaction with only a note on it, the change comes back to us
    const txBuilder = new MeshTxBuilder({ fetcher: provider });
    const unsignedTx = await txBuilder
      .changeAddress(changeAddress)
      .metadataValue(674, { msg: ['FairFare daily prices', date, hash] })
      .selectUtxosFrom(utxos)
      .complete();

    const signedTx = await wallet.signTx(unsignedTx);
    const txHash = await wallet.submitTx(signedTx);

    await receipt.set({
      date,
      hash,
      routes,
      txHash,
      network,
      createdAt: FieldValue.serverTimestamp(),
    });

    return { sent: true, id, date, hash, txHash };
  }
}