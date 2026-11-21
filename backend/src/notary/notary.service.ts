//reads the real prices, builds the daily fingerprint and sends it to Cardano
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FieldValue } from 'firebase-admin/firestore';
import { KoiosProvider, MeshTxBuilder, MeshWallet } from '@meshsdk/core';
import { COLLECTIONS } from '../firebase/firestore-paths.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { canonicalText, fingerprint, type PriceRow } from './fingerprint.js';

//blocks that must sit on top of our transaction before it is confirmed
const CONFIRMATIONS_NEEDED = 5;
//after sending we wait up to 18 times 10 seconds, so 3 minutes
const WAIT_TRIES = 18;
const WAIT_MS = 10000;

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

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

  //preview or preprod, from .env
  network(): string {
    return this.config.get<string>('NOTARY_NETWORK') ?? 'preview';
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

  //the date, the fingerprint, the exact text that was hashed and the route count
  async todaysFingerprint() {
    const date = this.today();
    const rows = await this.readPrices();
    return {
      date,
      hash: fingerprint(date, rows),
      text: canonicalText(date, rows),
      routes: rows.length,
    };
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

  //asks Koios how many blocks sit on top of the transaction, 0 if not found yet
  async confirmationsOf(txHash: string): Promise<number> {
    const response = await fetch(
      'https://' + this.network() + '.koios.rest/api/v1/tx_status',
      {
        method: 'POST',
        headers: {
          accept: 'application/json',
          'content-type': 'application/json',
        },
        body: JSON.stringify({ _tx_hashes: [txHash] }),
      },
    );
    if (!response.ok) {
      throw new Error('koios tx_status failed with ' + response.status);
    }
    const rows = (await response.json()) as {
      num_confirmations: number | null;
    }[];
    return Number(rows[0]?.num_confirmations ?? 0);
  }

  //turns every pending receipt into a confirmed one when the chain has enough blocks
  async confirmPending(): Promise<number> {
    const pending = await this.firebase.firestore
      .collection(COLLECTIONS.notarizations)
      .where('status', '==', 'pending')
      .get();

    let confirmed = 0;
    for (const doc of pending.docs) {
      const txHash = String(doc.data().txHash ?? '');
      if (!txHash) continue;

      const count = await this.confirmationsOf(txHash);
      if (count >= CONFIRMATIONS_NEEDED) {
        await doc.ref.update({
          status: 'confirmed',
          confirmations: count,
          confirmedAt: FieldValue.serverTimestamp(),
        });
        confirmed++;
      }
    }
    return confirmed;
  }

  //sends today's fingerprint to Cardano, saves the receipt, then waits for confirmation
  async notarize() {
    const { date, hash, text, routes } = await this.todaysFingerprint();

    //one receipt per date and fingerprint, so the same one is never sent twice
    const id = date + '-' + hash.slice(0, 8);
    const receipt = this.firebase.firestore
      .collection(COLLECTIONS.notarizations)
      .doc(id);
    const old = await receipt.get();

    if (old.exists) {
      const data = old.data() ?? {};
      //receipts made before the snapshot and status fields get them now
      const repairs: Record<string, unknown> = {};
      if (!data.text && data.hash === hash) repairs.text = text;
      if (!data.status) repairs.status = 'pending';
      if (Object.keys(repairs).length > 0) await receipt.update(repairs);

      await this.confirmPending();
      const now = (await receipt.get()).data();
      return {
        sent: false,
        id,
        date,
        hash,
        txHash: data.txHash,
        status: String(now?.status ?? 'pending'),
      };
    }

    //the server wallet, made earlier with npm run notary:wallet
    const words = this.config
      .getOrThrow<string>('NOTARY_MNEMONIC')
      .trim()
      .split(/\s+/);

    const provider = new KoiosProvider(this.network());
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

    //saved as pending, the app ignores it until it is confirmed
    await receipt.set({
      date,
      hash,
      text,
      routes,
      txHash,
      network: this.network(),
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
    });

    //wait a little for the network, the timer keeps trying later if this runs out
    let status = 'pending';
    for (let i = 0; i < WAIT_TRIES && status !== 'confirmed'; i++) {
      await sleep(WAIT_MS);
      await this.confirmPending();
      status = String((await receipt.get()).data()?.status);
    }

    return { sent: true, id, date, hash, txHash, status };
  }
}