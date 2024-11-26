import {MAT_DIAG3_M_1, RC3} from './poseidonBn254';

export default class Permutation {
  internalMatrixDiagonal = MAT_DIAG3_M_1;
  roundsF = 8;
  roundsP = 56;
  roundConstants = RC3;
  rounds = this.roundsF + this.roundsP;

  addRoundConstants(input: bigint[], rc: bigint[]): void {
    for (let i = 0; i < input.length; ++i) {
      input[i] += rc[i];
    }
  }
  matrixMultiplicationInternal(input: bigint[]): void {
    const sum = input.reduce((acc: bigint, val: bigint) => acc + val, 0n);
    for (let i = 0; i < input.length; ++i) {
      input[i] *= this.internalMatrixDiagonal[i];
      input[i] += sum;
    }
  }

  matrixMultiplicationExternal(input: bigint[]): void {
    if (input.length === 4) {
      this.matrixMultiplication4x4(input);
    } else {
      throw new Error('not supported');
    }
  }

  applySingleSbox(input: bigint): bigint {
    const xx = input * input;
    const xxxx = xx * xx;
    return input * xxxx;
  }

  applySbox(input: bigint[]): void {
    for (let i = 0; i < input.length; ++i) {
      input[i] = this.applySingleSbox(input[i]);
    }
  }

  matrixMultiplication4x4(input: bigint[]): void {
    const t0 = input[0] + input[1];
    const t1 = input[2] + input[3];
    const t2 = input[1] * BigInt(2) + t1;
    const t3 = input[3] * BigInt(2) + t0;
    const t4 = t1 * BigInt(4) + t3;
    const t5 = t0 * BigInt(4) + t2;
    const t6 = t3 + t5;
    const t7 = t2 + t4;
    input[0] = t6;
    input[1] = t5;
    input[2] = t7;
    input[3] = t4;
  }

  permutation(input: bigint[]): bigint[] {
    const currentState = [...input];

    this.matrixMultiplicationExternal(currentState);

    const roundsFBeginning = Math.floor(this.roundsF / 2);
    for (let i = 0; i < roundsFBeginning; ++i) {
      this.addRoundConstants(currentState, this.roundConstants[i]);
      this.applySbox(currentState);
      this.matrixMultiplicationExternal(currentState);
    }

    const pEnd = roundsFBeginning + this.roundsP;
    for (let i = roundsFBeginning; i < pEnd; ++i) {
      currentState[0] += this.roundConstants[i][0];
      currentState[0] = this.applySingleSbox(currentState[0]);
      this.matrixMultiplicationInternal(currentState);
    }

    for (let i = pEnd; i < this.rounds; ++i) {
      this.addRoundConstants(currentState, this.roundConstants[i]);
      this.applySbox(currentState);
      this.matrixMultiplicationExternal(currentState);
    }
    return currentState;
  }
}
