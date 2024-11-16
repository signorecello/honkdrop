import {hashMessage, fromHex, pad} from 'viem';
import {privateKeyToAccount} from 'viem/accounts';
import {LeanIMT} from '@zk-kit/lean-imt';
import {BarretenbergSync, Fr} from '@aztec/bb.js';
import {computeAllInputs} from '../lib/plume/src/index';
import {
  hexToUint8Array,
  messageToUint8Array,
} from '../lib/plume/src/utils/encoding';

const PRIV_KEY =
  '1973b806f3b34ba5279aef4e5a5bd8efce422602b3a692f1a1377898b405db74';
const ADDRESS = pad('0x6DD27C84aAc0030E31c2E0cB9BD74777a88FcEa4');
const message = 'hello noir';

const siblings = [
  '0x00000000000000000000000088DE460bb35DB40d11eca314633319949EfBB2Ed',
  '0x000000000000000000000000ef9d3a0601D9884ae54d3A44f7041dFfEdD55F59',
  '0x00000000000000000000000047Ea592d6A120d2F0100dF28d0b2f4D78d02c4C7',
  '0x000000000000000000000000B1Ac6D84f6F0A11AA89a72687aC0199ef51c7c2C',
  '0x0000000000000000000000004C9F8c73cC8ec94Bb0e5a7b2C8211eEEbd0b0FF8',
  '0x0000000000000000000000008753767b6BaeA84DE452948dC1b9E56963E66c42',
  '0x000000000000000000000000bD7417Ef54783eAe27b769Bb9F054371FB334e3b',
  '0x000000000000000000000000a67f00309a6a56FDdE1dc635a2Cf1a28d47a5177',
  '0x000000000000000000000000B0EE0129737b1CaCb13E18a5f7d2B8834fE01b42',
  '0x0000000000000000000000006d9151fD32179f1640082706e76b152065b863E4',
  '0x000000000000000000000000f37B002cEdF9f46C1CBFE335D6824bBDE6aF03a1',
  '0x000000000000000000000000C25143c2a215474386Bde0E0E958786c3cb15f95',
];

const main = async () => {
  const bb = await BarretenbergSync.new();

  const account = privateKeyToAccount(`0x${PRIV_KEY}`);
  console.log('ADDRESS: ', account.address, ADDRESS);
  const msgHash = hashMessage(message);

  const signature = computeAllInputs(
    messageToUint8Array(message),
    hexToUint8Array(PRIV_KEY),
  );

  console.log(signature.plume.toHex());

  const signatureBuffer = fromHex(
    `0x${signature.plume.toHex()}` as `0x${string}`,
    'bytes',
  );

  const frArray: Fr[] = Array.from(signatureBuffer).map(
    byte => new Fr(BigInt(byte)),
  );

  const nullifier = bb.pedersenHash(frArray, 0);

  console.log('PUB KEY: ', [...fromHex(account.publicKey, 'bytes').slice(1)]);
  console.log('SIGNATURE: ', [
    ...fromHex(`0x${signature.plume.toHex()}` as `0x${string}`, 'bytes').slice(
      0,
      64,
    ),
  ]);
  console.log('HASHED MESSAGE: ', [...fromHex(msgHash, 'bytes')]);
  console.log('NULLIFIER: ', nullifier.toString());

  const hasher = (a: string, b: string) =>
    bb.pedersenHash([Fr.fromString(a), Fr.fromString(b)], 0).toString();

  // To create an instance of a LeanIMT, you must provide the hash function.
  const tree = new LeanIMT(hasher);
  tree.insert(ADDRESS);
  for (let leaf of siblings) {
    tree.insert(leaf);
  }
  const mtProof = tree.generateProof(0);
  console.log('MT PATH: ', mtProof.siblings);
  console.log('ROOT: ', mtProof.root);
};

main();
