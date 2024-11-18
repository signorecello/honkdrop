use bignum::BigNum;
use ecrecover;
use nodash::pack_bytes;
use noir_bigcurve::BigCurve;
use noir_bigcurve::curves::secp256k1::{Secp256k1, Secp256k1Fr, Secp256k1Scalar};
use noir_bigcurve::scalar_field::ScalarField;
use plume::plume_v2;
use std::hash::poseidon2::Poseidon2::hash;
use trees::merkle::MerkleTree;

global DEPTH = 4;
comptime global G: Secp256k1 = BigCurve::one();

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
    merkle_path: [Field; DEPTH],
    index: Field,
    merkle_root: pub Field,
    claimer_priv: Field,
    claimer_pub: pub Field,
) {
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

    let mt = MerkleTree::default(merkle_root, poseidon2_hasher);
    mt.membership(address, index, merkle_path);
    assert(claimer_priv == claimer_pub);
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
        139, 248, 17, 181, 254, 139, 230, 148, 63, 5, 144, 179, 84, 227, 78, 189, 47, 47, 140, 221,
        95, 22, 195, 102, 172, 38, 233, 217, 52, 30, 220, 3,
    ];
    let s = [
        110, 27, 141, 225, 81, 199, 143, 3, 209, 85, 179, 15, 114, 211, 113, 145, 8, 32, 70, 165,
        71, 144, 119, 59, 191, 138, 72, 29, 186, 232, 127, 160,
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
        4, 24, 109, 78, 174, 175, 44, 18, 251, 4, 3, 40, 238, 249, 80, 1, 74, 179, 208, 37, 58, 17,
        108, 165, 163, 153, 155, 170, 51, 56, 70, 47,
    ];
    let nullifier_y = [
        163, 107, 231, 8, 201, 149, 185, 160, 5, 254, 191, 80, 205, 160, 215, 57, 13, 255, 118, 4,
        192, 174, 248, 226, 114, 149, 101, 219, 183, 245, 167, 137,
    ];
    let merkle_path = [
        0x00000000000000000000000088DE460bb35DB40d11eca314633319949EfBB2Ed,
        0x1b12af9b3fec8897f09c1a669db41502bd6b14de4148dbc2c37682335a9446e0,
        0x24f2f7ad59289906e3227e630f410c9d20b6c89b690df1da5123fdda491eddde,
        0x06cb78c27cd4c0cf961a81bf5475d2ec872a6f17ed15258a2a0bf7f9b44611a7,
    ];
    let index = 0;
    let merkle_root = 0x0ddcfba8a3cfca02bbbd3434cd6cd1b0bf1705bb616a49e4ed36ae6fa8ca198e;
    let claimer = 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc;

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
        merkle_path,
        index,
        merkle_root,
        claimer,
        claimer,
    );
}
