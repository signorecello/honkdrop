import {serializeBufferable} from './serialize';
import {Fr} from './types/fields';
import * as WebAssembly from 'react-native-webassembly';
import BB from './barretenberg.wasm';

export class Poseidon2 {
  wasm: WebAssembly.WebassemblyInstantiateResult<{
    poseidon2_hash: (
      inputsBuffer: Uint8Array[],
      outputArgs: any[],
    ) => Uint8Array;
  }>;

  constructor(
    _wasm: WebAssembly.WebassemblyInstantiateResult<{
      poseidon2_hash: (
        inputsBuffer: Uint8Array[],
        outputArgs: any[],
      ) => Uint8Array;
    }>,
  ) {
    this.wasm = _wasm;
  }

  static async new() {
    const module = await WebAssembly.instantiate<{
      poseidon2_hash: (
        inputsBuffer: Uint8Array[],
        outputArgs: any[],
      ) => Uint8Array;
    }>(BB);
    return new Poseidon2(module);
  }

  poseidon2Hash(inputsBuffer: Fr[]): Uint8Array {
    const inArgs = [inputsBuffer].map(serializeBufferable);
    const outTypes = [Fr];

    const result = this.wasm.instance.exports.poseidon2_hash(
      inArgs,
      outTypes.map(t => t.SIZE_IN_BYTES),
    );
    return result;
  }
}
