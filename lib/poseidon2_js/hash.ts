// import {poseidonBn254} from './poseidonBn254';
import Permutation from './permutation';

const SPONGE_RATE = 4;
// const SPONGE_WIDTH = 4;
// const ZERO = BigInt(0);
// const F = poseidonBn254.primeField;

export class Hash {
  state: Uint8Array = new Uint8Array(SPONGE_RATE);
  cache: Uint8Array = new Uint8Array(SPONGE_RATE);
  cache_size = 0;
  mode = 'ABSORB';

  constructor(iv: number) {
    for (let i = 0; i < SPONGE_RATE; ++i) {
      this.state[i] = 0;
    }
    this.state[SPONGE_RATE] = iv;
  }

  perform_duplex() {
    // zero-pad the cache
    for (let i = this.cache_size; i < SPONGE_RATE; ++i) {
      this.cache[i] = 0;
    }
    // add the cache into sponge state
    for (let i = 0; i < SPONGE_RATE; ++i) {
      this.state[i] += this.cache[i];
    }

    this.state = new Uint8Array(
      new Permutation()
        .permutation(Array.from(this.state).map(i => BigInt(i)))
        .map(i => Number(i)),
    );

    // return `rate` number of field elements from the sponge state.
    let output: Uint8Array = new Uint8Array(SPONGE_RATE);
    for (let i = 0; i < SPONGE_RATE; ++i) {
      output[i] = this.state[i];
    }
    return output;
  }

  absorb(input: number) {
    if (this.mode == 'ABSORB' && this.cache_size == SPONGE_RATE) {
      // If we're absorbing, and the cache is full, apply the sponge permutation to compress the cache
      this.perform_duplex();
      this.cache[0] = input;
      this.cache_size = 1;
    } else if (this.mode == 'ABSORB' && this.cache_size < SPONGE_RATE) {
      // If we're absorbing, and the cache is not full, add the input into the cache
      this.cache[this.cache_size] = input;
      this.cache_size += 1;
    } else if (this.mode == 'SQUEEZE') {
      // If we're in squeeze mode, switch to absorb mode and add the input into the cache.
      // N.B. I don't think this code path can be reached?!
      this.cache[0] = input;
      this.cache_size = 1;
      this.mode = 'ABSORB';
    }
  }

  squeeze() {
    if (this.mode == 'SQUEEZE' && this.cache_size == 0) {
      // If we're in squeze mode and the cache is empty, there is nothing left to squeeze out of the sponge!
      // Switch to absorb mode.
      this.mode = 'ABSORB';
      this.cache_size = 0;
    }
    if (this.mode == 'ABSORB') {
      // If we're in absorb mode, apply sponge permutation to compress the cache, populate cache with compressed
      // state and switch to squeeze mode. Note: this code block will execute if the previous `if` condition was
      // matched
      let new_output_elements = this.perform_duplex();
      this.mode = 'SQUEEZE';
      for (let i = 0; i < SPONGE_RATE; ++i) {
        this.cache[i] = new_output_elements[i];
      }
      this.cache_size = SPONGE_RATE;
    }
    // By this point, we should have a non-empty cache. Pop one item off the top of the cache and return it.
    let result = this.cache[0];
    for (let i = 1; i < this.cache_size; ++i) {
      this.cache[i - 1] = this.cache[i];
    }
    this.cache_size -= 1;
    this.cache[this.cache_size] = 0;
    return result;
  }

  static hash_internal(
    input: Uint8Array,
    out_len: number,
    is_variable_length: boolean,
  ) {
    let in_len = input.length;
    const iv = (in_len << 64) + out_len - 1;
    const sponge = new Hash(iv);

    for (let i = 0; i < in_len; ++i) {
      sponge.absorb(input[i]);
    }

    if (is_variable_length) {
      sponge.absorb(1);
    }

    let output: Uint8Array = new Uint8Array(out_len);
    for (let i = 0; i < out_len; ++i) {
      output[i] = sponge.squeeze();
    }
    return output;
  }
}

// function hashNToMNoPad(
//   inputs: bigint[] | BigUint64Array,
//   numOutputs: number,
// ): bigint[] {
//   const inputsLength = inputs.length;

//   let state: bigint[] = [ZERO, ZERO, ZERO, ZERO];
//   const nChunks = Math.floor(inputsLength / SPONGE_RATE);
//   for (let i = 0; i < nChunks; i++) {
//     state[0] = F.e(inputs[i]);
//     state[1] = F.e(inputs[i + 1]);
//     const n_state = poseidonBn254.permute(state);
//     state[0] = n_state[0];
//     state[1] = n_state[1];
//     state[2] = n_state[2];
//     state[3] = n_state[3];
//   }
//   const start = nChunks * SPONGE_RATE;
//   const remaining = inputsLength - start;
//   if (remaining > 0 && remaining < state.length) {
//     for (let i = 0; i < remaining; i++) {
//       state[i] = F.e(inputs[start + i]);
//     }
//     const n_state = poseidonBn254.permute(state);
//     state[0] = n_state[0];
//     state[1] = n_state[1];
//     state[2] = n_state[2];
//     state[3] = n_state[3];
//   }
//   if (numOutputs === 4) {
//     return [state[0], state[1], state[2], state[3]];
//   }
//   const outputs: bigint[] = [];
//   const nOutputRounds = Math.ceil(numOutputs / SPONGE_RATE);
//   let outputsPushed = 0;
//   for (let i = 0; i < nOutputRounds; i++) {
//     for (let x = 0; x < SPONGE_RATE && outputsPushed < numOutputs; x++) {
//       outputs.push(state[x]);
//       outputsPushed++;
//     }
//     state = poseidonBn254.permute(state);
//   }
//   return outputs;
// }
// function hashNoPad(input: bigint[] | BigUint64Array): IHashOut {
//   const output = hashNToMNoPad(input, 4);
//   return [output[0], output[1], output[2], output[3]];
// }
// const permute = poseidonBn254.permute.bind(poseidonBn254);

// export {F, permute, hashNToMNoPad, hashNoPad};
// export type {IHashOut};
