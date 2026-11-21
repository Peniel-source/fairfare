// A8 one time script. Makes a new Cardano preprod wallet for the notary.
//
//   npm run notary:wallet
//
// Prints the secret words and the address. Run it once, keep the words in backend/.env.

import { MeshWallet } from '@meshsdk/core';

async function main() {
  //makes new secret words
  const words = MeshWallet.brew() as string[];

  //networkId 0 means a test network (preprod)
  const wallet = new MeshWallet({
    networkId: 0,
    key: { type: 'mnemonic', words },
  });

  const address = await wallet.getChangeAddress();

  console.log('');
  console.log('put this line in backend/.env, no tell anybody:');
  console.log('NOTARY_MNEMONIC="' + words.join(' ') + '"');
  console.log('');
  console.log('this is the wallet address, it is safe to share:');
  console.log(address);
  console.log('');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});