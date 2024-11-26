import {describe, test, beforeAll} from 'bun:test';
import {UltraHonkBackend, BarretenbergSync, Fr} from '@aztec/bb.js';
import {CompiledCircuit, Noir} from '@noir-lang/noir_js';
import circuit from '../circuits/target/honkdrop.json';
import {prepareInputs} from '../lib/prep';
import {fromHex, hashMessage, pad, PrivateKeyAccount} from 'viem';
import {privateKeyToAccount} from 'viem/accounts';
import {computeAllInputs, computeNullifer} from '../lib/plume-js/src/index';
import {hexToUint8Array} from '../lib/plume-js/src/utils/encoding';
import {getPublicKey, Point} from '@noble/secp256k1';
import {writeFileSync} from 'fs';
import {cpus} from 'os';
import {LeanIMT} from '@zk-kit/lean-imt';

const PRIV_KEY = process.env.PRIV_KEY;
const ADDRESS = pad('0x6DD27C84aAc0030E31c2E0cB9BD74777a88FcEa4');
const messageString = 'hello noir';
const message = Uint8Array.from([
  104, 101, 108, 108, 111, 32, 110, 111, 105, 114,
]);

// export async function compileCircuit(path = './circuits') {
//   const basePath = resolve(join(path));
//   const fm = createFileManager(basePath);
//   const result = await compile(fm);
//   if (!('program' in result)) {
//     throw new Error('Compilation failed');
//   }
//   return result.program as CompiledCircuit;
// }

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

describe('Test', () => {
  let bb: BarretenbergSync;
  const backend = new UltraHonkBackend(circuit.bytecode, {
    threads: cpus().length,
  });
  const noir = new Noir(circuit as CompiledCircuit);
  const hasher = (a: string, b: string) =>
    bb.poseidon2Hash([Fr.fromString(a), Fr.fromString(b)]).toString();
  const eligibleTree = new LeanIMT(hasher);
  const nullifierTree = new LeanIMT(hasher);

  beforeAll(async () => {
    bb = await BarretenbergSync.new();

    eligibleTree.insert(ADDRESS);
    for (let leaf of siblings) {
      eligibleTree.insert(leaf);
      // adding some stuff to the nullifier tree
      nullifierTree.insert(bb.poseidon2Hash([Fr.fromString(leaf)]).toString());
    }
  });

  let account: PrivateKeyAccount;
  let nullifier: Point;
  let signature: `0x${string}`;
  let messageHash: Uint8Array;
  let pk: Uint8Array;
  let plume: any;

  beforeAll(async () => {
    account = privateKeyToAccount(`0x${PRIV_KEY}`);
    const sk = hexToUint8Array(PRIV_KEY as unknown as string);
    plume = await computeAllInputs(message, sk);
    nullifier = computeNullifer(plume.hashedToCurveR, hexToUint8Array(plume.s));
    signature = await account.signMessage({message: messageString});
    messageHash = hashMessage(messageString, 'bytes');
    pk = getPublicKey(sk);
  });

  test('Generates a proof', async () => {
    const eligibleMtProof = eligibleTree.generateProof(0);
    const oldNullifierRoot = nullifierTree.root;

    nullifierTree.insert(`0x${(nullifier.x % Fr.MODULUS).toString(16)}`);
    const nullifierMtProof = nullifierTree.generateProof(
      nullifierTree.size - 1,
    );
    const nullifierPath = new Array(nullifierTree.depth)
      .fill(pad('0x00'))
      .map(
        (value, index) =>
          (nullifierMtProof.siblings[index] as `0x${string}`) || pad('0x00'),
      );

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
      eligible_root: eligibleMtProof.root as `0x${string}`,
      eligible_path: eligibleMtProof.siblings.map(s => s as `0x${string}`),
      eligible_index: eligibleMtProof.index,
      nullifier_root: oldNullifierRoot as `0x${string}`,
      nullifier_path: nullifierPath,
      nullifier_index: nullifierTree.size - 1,

      claimer_priv: pad('0x8aEC1f81CB90204e3C9Aa1Aeed2915C181CbBe28'),

      claimer_pub: pad('0x8aEC1f81CB90204e3C9Aa1Aeed2915C181CbBe28'),

      return: nullifierMtProof.root as `0x${string}`,
    };

    const start = performance.now();
    console.log('Start time: ', start);

    const {witness} = await noir.execute(inputs);

    const witgenTime = performance.now();
    console.log('Witgen time: ', witgenTime - start);

    const proof = await backend.generateProof(witness);
    const end = performance.now();
    console.log('Proof time: ', end - witgenTime);
    console.log('Total time: ', end - start);
  });

  // test('Poseidon function', () => {
  //   const inputs = [Fr.fromString('0x00'), Fr.fromString('0x01')];
  //   const serialized = serializeBufferArrayToVector(
  //     inputs.map(serializeBufferable),
  //   );
  //   console.log(serialized);
  //   const hash = Hash.hash_internal(serialized, 1, false);
  //   const fromBB = bb.poseidon2Hash(inputs);

  //   console.log('JS: ', hash);
  //   console.log('BB: ', BigInt(fromBB.toString()));
  // });
});

// const inputs = {
//   pub_key: [...fromHex(account.publicKey, 'bytes').slice(1)],
//   signature: [...fromHex(signature as `0x${string}`, 'bytes').slice(0, 64)],
//   message: Array.from(message),
//   message_hash: Array.from(messageHash),

//   c: [...fromHex(`0x${plume.c}`, 'bytes')],
//   s: [...fromHex(`0x${plume.s}`, 'bytes')],
//   pk_x: Array.from(pk.slice(0, 32)),
//   pk_y: Array.from(pk.slice(32, 64)),
//   nullifier_x: [
//     ...fromHex(nullifier.toHex() as `0x${string}`, 'bytes'),
//   ].slice(0, 32),
//   nullifier_y: [
//     ...fromHex(nullifier.toHex() as `0x${string}`, 'bytes'),
//   ].slice(32, 64),

//   eligible_root: [
//     ...fromHex(eligibleMtProof.root as `0x${string}`, 'bytes'),
//   ],
//   eligible_path: eligibleMtProof.siblings.map(s => [
//     ...fromHex(s as `0x${string}`, 'bytes'),
//   ]),
//   eligible_index: eligibleMtProof.index,

//   nullifier_root: [
//     ...fromHex(nullifierMtProof.root as `0x${string}`, 'bytes'),
//   ],
//   nullifier_path: nullifierMtProof.siblings.map(s => [
//     ...fromHex(s as `0x${string}`, 'bytes'),
//   ]),
//   nullifier_index: nullifierMtProof.index,

//   claimer_priv: [
//     ...fromHex(pad('0x8aEC1f81CB90204e3C9Aa1Aeed2915C181CbBe28'), 'bytes'),
//   ],
//   claimer_pub: [
//     ...fromHex(pad('0x8aEC1f81CB90204e3C9Aa1Aeed2915C181CbBe28'), 'bytes'),
//   ],
//   return: [...fromHex(nullifierMtProof.root as `0x${string}`, 'bytes')],
// };
