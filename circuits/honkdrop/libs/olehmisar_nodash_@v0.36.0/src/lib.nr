mod math;
mod solidity;
mod string;
mod tables;
mod array;

pub use string::{to_hex_string_bytes, str_to_u64};
pub use math::{clamp, div_ceil, sqrt::sqrt};
pub use array::pack_bytes;

trait ArrayExtensions<T, let N: u32> {
    fn slice<let M: u32>(self, start: u32, end: u32) -> [T; M];
    fn concat<let M: u32>(self, other: [T; M]) -> [T; N + M];
    fn pad_start<let M: u32>(self, pad_value: T) -> [T; M];
    fn pad_end<let M: u32>(self, pad_value: T) -> [T; M];
}

#[deprecated]
pub fn array_concat<T, let L1: u32, let L2: u32>(a: [T; L1], b: [T; L2]) -> [T; L1 + L2] {
    a.concat(b)
}
