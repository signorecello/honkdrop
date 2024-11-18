import {describe, test} from 'bun:test';
import {Barretenberg, UltraHonkBackend} from '@aztec/bb.js';
import {CompiledCircuit, Noir} from '@noir-lang/noir_js';
import circuit from '../circuits/honkdrop/target/honkdrop.json';
import {prepareInputs} from '../circuits/honkdrop/prep';
import {cpus} from 'os';
import {createFileManager, compile} from '@noir-lang/noir_wasm';
import {resolve, join} from 'path';

// export async function compileCircuit(path = './circuits') {
//   const basePath = resolve(join(path));
//   const fm = createFileManager(basePath);
//   const result = await compile(fm);
//   if (!('program' in result)) {
//     throw new Error('Compilation failed');
//   }
//   return result.program as CompiledCircuit;
// }

describe('Test', () => {
  test(async () => {
    // const circuit = await compileCircuit();
    const backend = new UltraHonkBackend(circuit.bytecode);
    const noir = new Noir(circuit as CompiledCircuit);

    const inputs = await prepareInputs();

    const {witness} = await noir.execute(inputs);

    const proof = await backend.generateProof(witness);
  });
});
