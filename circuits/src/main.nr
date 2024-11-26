use bignum::BigNum;
use ecrecover;
use noir_bigcurve::BigCurve;
use noir_bigcurve::curves::secp256k1::{Secp256k1, Secp256k1Fr, Secp256k1Scalar};
use noir_bigcurve::scalar_field::ScalarField;
use plume::{plume_v2, utils::to_field};
use std::hash::poseidon2::Poseidon2::hash;
use trees::merkle::MerkleTree;

global DEPTH: u32 = 4;

fn poseidon2_hasher(leaves: [Field; 2]) -> Field {
    hash([leaves[0], leaves[1]], 2)
}

fn main(
    pub_key: [u8; 64],
    signature: [u8; 64],
    message: [u8; 10], // hello noir
    message_hash: pub [u8; 32],
    c: [u8; 32],
    s: [u8; 32],
    pk_x: [u8; 32],
    pk_y: [u8; 32],
    nullifier_x: [u8; 32],
    nullifier_y: [u8; 32],
    eligible_root: pub Field,
    eligible_path: [Field; DEPTH],
    eligible_index: Field,
    nullifier_root: pub Field,
    nullifier_path: [Field; DEPTH],
    nullifier_index: Field,
    claimer_priv: Field,
    claimer_pub: pub Field,
) -> pub Field {
    let key = ecrecover::secp256k1::PubKey::from_unified(pub_key);
    let address = ecrecover::ecrecover(key.pub_x, key.pub_y, signature, message_hash);

    let c: Secp256k1Fr = BigNum::from_be_bytes(c);
    let c: Secp256k1Scalar = ScalarField::from_bignum(c);

    let s: Secp256k1Fr = BigNum::from_be_bytes(s);
    let s: Secp256k1Scalar = ScalarField::from_bignum(s);

    let pk: Secp256k1 = BigCurve {
        x: BigNum::from_be_bytes(pk_x),
        y: BigNum::from_be_bytes(pk_y),
        is_infinity: false,
    };

    let nullifier: Secp256k1 = BigCurve {
        x: BigNum::from_be_bytes(nullifier_x),
        y: BigNum::from_be_bytes(nullifier_y),
        is_infinity: false,
    };
    let _: (Secp256k1, Secp256k1) = plume_v2(message, c, s, pk, nullifier);

    let eligible_mt = MerkleTree::default(eligible_root, poseidon2_hasher);
    eligible_mt.membership(address, eligible_index, eligible_path);

    let mut nullifier_mt: MerkleTree = MerkleTree::from(nullifier_root, poseidon2_hasher);
    nullifier_mt.add(to_field(nullifier_x), nullifier_index, nullifier_path);
    assert(claimer_priv == claimer_pub);
    nullifier_mt.root
}

#[test]
fn test_main() {
    let pub_key = [
        157, 206, 149, 41, 27, 219, 135, 154, 35, 47, 118, 17, 75, 254, 143, 81, 51, 183, 113, 195,
        85, 214, 51, 148, 165, 112, 204, 163, 203, 124, 120, 48, 196, 19, 228, 254, 20, 86, 178, 54,
        112, 63, 172, 224, 9, 247, 8, 6, 136, 157, 222, 31, 18, 206, 137, 176, 204, 168, 116, 191,
        34, 191, 52, 125,
    ];
    let signature = [
        177, 145, 6, 71, 182, 27, 50, 138, 7, 83, 30, 89, 179, 104, 215, 176, 5, 193, 158, 38, 248,
        216, 114, 18, 19, 227, 82, 160, 95, 224, 39, 198, 14, 58, 97, 205, 253, 73, 72, 42, 213, 8,
        193, 74, 105, 214, 220, 39, 241, 0, 207, 145, 88, 244, 87, 206, 122, 30, 242, 45, 52, 8,
        242, 167,
    ];
    let message = [104, 101, 108, 108, 111, 32, 110, 111, 105, 114];
    let message_hash = [
        234, 156, 34, 19, 249, 17, 115, 78, 115, 153, 126, 124, 5, 80, 106, 125, 172, 34, 205, 99,
        102, 22, 63, 24, 178, 96, 117, 62, 232, 246, 89, 47,
    ];
    let c = [
        17, 144, 18, 16, 110, 231, 201, 207, 233, 50, 106, 60, 163, 129, 152, 152, 60, 199, 155, 44,
        114, 74, 156, 123, 120, 198, 132, 148, 24, 125, 82, 89,
    ];
    let s = [
        112, 8, 92, 192, 15, 98, 120, 44, 2, 146, 136, 38, 107, 229, 62, 204, 229, 142, 129, 239,
        170, 72, 212, 244, 247, 154, 0, 41, 209, 59, 70, 143,
    ];
    let pk_x = [
        4, 157, 206, 149, 41, 27, 219, 135, 154, 35, 47, 118, 17, 75, 254, 143, 81, 51, 183, 113,
        195, 85, 214, 51, 148, 165, 112, 204, 163, 203, 124, 120,
    ];
    let pk_y = [
        48, 196, 19, 228, 254, 20, 86, 178, 54, 112, 63, 172, 224, 9, 247, 8, 6, 136, 157, 222, 31,
        18, 206, 137, 176, 204, 168, 116, 191, 34, 191, 52,
    ];
    let nullifier_x = [
        118, 192, 108, 234, 170, 117, 178, 209, 2, 5, 194, 197, 34, 43, 209, 253, 50, 186, 183, 188,
        4, 199, 5, 253, 167, 10, 47, 79, 154, 64, 33, 145,
    ];
    let nullifier_y = [
        105, 118, 165, 209, 147, 31, 135, 89, 230, 141, 167, 4, 48, 229, 29, 3, 154, 237, 125, 48,
        99, 130, 82, 61, 228, 18, 123, 166, 31, 176, 87, 139,
    ];
    let eligible_root = 0x0ddcfba8a3cfca02bbbd3434cd6cd1b0bf1705bb616a49e4ed36ae6fa8ca198e;
    let eligible_path = [
        0x00000000000000000000000088DE460bb35DB40d11eca314633319949EfBB2Ed,
        0x1b12af9b3fec8897f09c1a669db41502bd6b14de4148dbc2c37682335a9446e0,
        0x24f2f7ad59289906e3227e630f410c9d20b6c89b690df1da5123fdda491eddde,
        0x06cb78c27cd4c0cf961a81bf5475d2ec872a6f17ed15258a2a0bf7f9b44611a7,
    ];
    let eligible_index = 0;
    let nullifier_root = 0x1ba9972866b1f0859576dfbdd81ca0172b8f8689b6c44acb9a82982c5e23908a;
    let nullifier_path = [
        0x13464a6ff8c172a7aa9626f42439fcdd71c342f212dc341d9259889419218d2f,
        0x1eeb8f45fe1b32fc01aa1d6f72e408368ef1cbf0c58179fcc848d7a433e4618f,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000000,
    ];
    let nullifier_index = 12;
    let claimer_priv = 0x0000000000000000000000008aEC1f81CB90204e3C9Aa1Aeed2915C181CbBe28;
    let claimer_pub = 0x0000000000000000000000008aEC1f81CB90204e3C9Aa1Aeed2915C181CbBe28;
    let return_value = 0x2a2edff3bb5827f8fa4c8a9746551d04553627d964e5414cf9992f75d8e1fd1b;

    main(
        pub_key,
        signature,
        message,
        message_hash,
        c,
        s,
        pk_x,
        pk_y,
        nullifier_x,
        nullifier_y,
        eligible_root,
        eligible_path,
        eligible_index,
        nullifier_root,
        nullifier_path,
        nullifier_index,
        claimer_priv,
        claimer_pub,
    );
}
