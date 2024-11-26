import {toBigIntBE, toBufferBE} from './bigint-array';
import {uint8ArrayToHexString} from '../serialize';
import {BufferReader} from './buffer_reader';

// TODO(#4189): Replace with implementation in yarn-project/foundation/src/fields/fields.ts
/**
 * Fr field class.
 * @dev This class is used to represent elements of BN254 scalar field or elements in the base field of Grumpkin.
 * (Grumpkin's scalar field corresponds to BN254's base field and vice versa.)
 */
export class Fr {
  static ZERO = new Fr(0n);
  static MODULUS =
    0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001n;
  static MAX_VALUE = this.MODULUS - 1n;
  static SIZE_IN_BYTES = 32;
  value: Uint8Array;

  constructor(value: Uint8Array | bigint) {
    // We convert buffer value to bigint to be able to check it fits within modulus
    const valueBigInt = typeof value === 'bigint' ? value : toBigIntBE(value);

    if (valueBigInt > Fr.MAX_VALUE) {
      throw new Error(
        `Value 0x${valueBigInt.toString(
          16,
        )} is greater or equal to field modulus.`,
      );
    }

    this.value = typeof value === 'bigint' ? toBufferBE(value) : value;
  }

  static fromBuffer(buffer: Uint8Array | BufferReader) {
    const reader = BufferReader.asReader(buffer);
    return new this(reader.readBytes(this.SIZE_IN_BYTES));
  }

  static fromBufferReduce(buffer: Uint8Array | BufferReader) {
    const reader = BufferReader.asReader(buffer);
    return new this(
      toBigIntBE(reader.readBytes(this.SIZE_IN_BYTES)) % Fr.MODULUS,
    );
  }

  static fromString(str: string) {
    return this.fromBuffer(Buffer.from(str.replace(/^0x/i, ''), 'hex'));
  }

  toBuffer() {
    return this.value;
  }

  toString() {
    return '0x' + uint8ArrayToHexString(this.toBuffer());
  }

  equals(rhs: Fr) {
    return this.value.every((v, i) => v === rhs.value[i]);
  }

  isZero() {
    return this.value.every(v => v === 0);
  }
}
