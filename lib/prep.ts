import {fromHex, hashMessage, pad} from 'viem';
import {privateKeyToAccount} from 'viem/accounts';
import {LeanIMT} from '@zk-kit/lean-imt';
import {BarretenbergSync, Fr} from '@aztec/bb.js';
import {computeAllInputs, computeNullifer} from './plume-js/src/index';
import {hexToUint8Array} from './plume-js/src/utils/encoding';
import {getPublicKey} from '@noble/secp256k1';
import {writeFileSync} from 'fs';

const PRIV_KEY = process.env.PRIV_KEY;
const ADDRESS = pad('0x6DD27C84aAc0030E31c2E0cB9BD74777a88FcEa4');
const messageString = 'hello noir';
const message = Uint8Array.from([
  104, 101, 108, 108, 111, 32, 110, 111, 105, 114,
]);

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

export const prepareInputs = async () => {
  const bb = await BarretenbergSync.new();

  const account = privateKeyToAccount(`0x${PRIV_KEY}`);

  const sk = hexToUint8Array(PRIV_KEY as unknown as string);
  const plume = await computeAllInputs(message, sk);
  const nullifier = computeNullifer(
    plume.hashedToCurveR,
    hexToUint8Array(plume.s),
  );
  const signature = await account.signMessage({message: messageString});

  const messageHash = hashMessage(messageString, 'bytes');

  const pk = getPublicKey(sk);

  const hasher = (a: string, b: string) =>
    bb.poseidon2Hash([Fr.fromString(a), Fr.fromString(b)]).toString();

  // To create an instance of a LeanIMT, you must provide the hash function.
  const tree = new LeanIMT(hasher);
  tree.insert(ADDRESS);
  for (let leaf of siblings) {
    tree.insert(leaf);
  }
  const mtProof = tree.generateProof(0);

  const inputs = {
    pub_key: [...fromHex(account.publicKey, 'bytes').slice(1)],
    signature: [...fromHex(signature as `0x${string}`, 'bytes').slice(0, 64)],
    message: Array.from(message),
    message_hash: Array.from(messageHash),

    c: [...fromHex(`0x${plume.c}`, 'bytes')],
    s: [...fromHex(`0x${plume.s}`, 'bytes')],
    pk_x: Array.from(pk.slice(0, 32)),
    pk_y: Array.from(pk.slice(32, 64)),
    nullifier_x: [
      ...fromHex(nullifier.toHex() as `0x${string}`, 'bytes'),
    ].slice(0, 32),
    nullifier_y: [
      ...fromHex(nullifier.toHex() as `0x${string}`, 'bytes'),
    ].slice(32, 64),

    merkle_path: mtProof.siblings.map(s => [
      ...fromHex(s as `0x${string}`, 'bytes'),
    ]),
    index: mtProof.index,
    merkle_root: [...fromHex(mtProof.root as `0x${string}`, 'bytes')],
    claimer_priv: [
      ...fromHex(pad('0x8aEC1f81CB90204e3C9Aa1Aeed2915C181CbBe28'), 'bytes'),
    ],
    claimer_pub: [
      ...fromHex(pad('0x8aEC1f81CB90204e3C9Aa1Aeed2915C181CbBe28'), 'bytes'),
    ],
  };

  console.log(mtProof.siblings);
  console.log(mtProof.root);
  writeFileSync('./lib/inputs.json', JSON.stringify(inputs));
  return inputs;
};

// if (process.argv[1]) {
//   prepareInputs();
// }
