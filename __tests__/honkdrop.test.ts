import {describe, test} from 'bun:test';
import {UltraPlonkBackend} from '@aztec/bb.js';
import {CompiledCircuit, Noir} from '@noir-lang/noir_js';
import circuit from '../circuits/target/honkdrop.json';
import {prepareInputs} from '../circuits/prep';
import {cpus} from 'os';

describe('Test', () => {
  test(async () => {
    const backend = new UltraPlonkBackend(circuit.bytecode, {
      threads: cpus.length,
    });
    const noir = new Noir(circuit as CompiledCircuit);

    const inputs = await prepareInputs();
    console.log(inputs);

    const {witness} = await noir.execute(inputs);
    console.log(witness);

    const proof = await backend.generateProof(witness);
    console.log(proof);
  });
});
