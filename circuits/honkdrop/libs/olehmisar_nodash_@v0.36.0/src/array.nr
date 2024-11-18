impl<T, let N: u32> crate::ArrayExtensions<T, N> for [T; N] {
    fn slice<let M: u32>(self, start: u32, end: u32) -> [T; M] {
        assert(start + M == end, "slice: invalid slice length");
        assert(end <= N, "slice: slice end out of bounds");
        let mut result = [self[0]; M];
        for i in 0..M {
            result[i] = self[start + i];
        }
        result
    }

    fn concat<let M: u32>(self, other: [T; M]) -> [T; N + M] {
        let mut result = [self[0]; N + M];
        for i in 0..N {
            result[i] = self[i];
        }
        for i in 0..M {
            result[i + N] = other[i];
        }
        result
    }

    fn pad_start<let M: u32>(self, pad_value: T) -> [T; M] {
        assert(M >= N, "pad_start: array too long");
        let mut res = [pad_value; M];
        for i in 0..N {
            res[i + M - N] = self[i];
        }
        res
    }

    fn pad_end<let M: u32>(self, pad_value: T) -> [T; M] {
        assert(M >= N, "pad_end: array too long");
        let mut res = [pad_value; M];
        for i in 0..N {
            res[i] = self[i];
        }
        res
    }
}

// TODO: write tests
pub fn pack_bytes<let N: u32>(bytes: [u8; N]) -> [Field; N / 31 + 1] {
    let bytes_padded = bytes.pad_end::<(N / 31 + 1) * 31>(0);
    let mut res = [0 as Field; N / 31 + 1];
    for i in 0..N / 31 + 1 {
        let chunk = bytes_padded.slice::<31>(i * 31, i * 31 + 31);
        res[i] = field_from_bytes(chunk);
    }
    res
}

// copied from https://github.com/AztecProtocol/aztec-packages/blob/a2ed567ad42b237088c110ce12ce8212d5099da2/noir-projects/noir-protocol-circuits/crates/types/src/utils/field.nr#L4
fn field_from_bytes<let N: u32>(bytes: [u8; N]) -> Field {
    assert(bytes.len() < 32, "field_from_bytes: N must be less than 32");
    let mut as_field = 0;
    let mut offset = 1;
    for i in 0..N {
        as_field += (bytes[i] as Field) * offset;
        offset *= 256;
    }
    as_field
}

mod tests {
    #[test]
    fn test_slice() {
        assert([1, 2, 3, 4, 5].slice::<3>(1, 4) == [2, 3, 4]);
    }

    #[test]
    fn test_simple() {
        assert([1, 2, 3].concat([4, 5]) == [1, 2, 3, 4, 5]);
    }

    #[test]
    fn test_pad_start() {
        assert([1, 2, 3].pad_start::<5>(0) == [0, 0, 1, 2, 3]);
    }

    #[test]
    fn test_pad_end() {
        assert([1, 2, 3].pad_end::<5>(0) == [1, 2, 3, 0, 0]);
    }
}
