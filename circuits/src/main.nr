use ecrecover;
use plume::plume_v2;
use std::hash::pedersen_hash;
use trees::merkle::MerkleTree;
use noir_bigcurve::curves::secp256k1::{Secp256k1, Secp256k1Fr, Secp256k1Scalar};
use noir_bigcurve::scalar_field::ScalarField;
use bignum::BigNum;
use noir_bigcurve::BigCurve;
use nodash::pack_bytes;

global DEPTH = 4;
comptime global G: Secp256k1 = BigCurve::one();

fn main(
    pub_key: [u8; 64],
    signature: [u8; 64],
    message: pub [u8; 10], // hello noir
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

    let pk : Secp256k1 =  BigCurve {
        x: BigNum::from_be_bytes(pk_x),
        y: BigNum::from_be_bytes(pk_y),
        is_infinity: false,
    };
    
    let nullifier : Secp256k1 =  BigCurve {
        x: BigNum::from_be_bytes(nullifier_x),
        y: BigNum::from_be_bytes(nullifier_y),
        is_infinity: false,
    };
    let _ : (Secp256k1, Secp256k1) = plume_v2(message, c, s, pk, nullifier); 

    let mt = MerkleTree::default(merkle_root, pedersen_hash);
    mt.membership(address, index, merkle_path);
    assert(claimer_priv == claimer_pub);
}

#[test]
fn test_main() {
    let pub_key = [
        157, 206, 149, 41, 27, 219, 135, 154, 35, 47, 118, 17, 75, 254, 143, 81, 51, 183,
        113, 195, 85, 214, 51, 148, 165, 112, 204, 163, 203, 124, 120, 48, 196, 19, 228,
        254, 20, 86, 178, 54, 112, 63, 172, 224, 9, 247, 8, 6, 136, 157, 222, 31, 18, 206,
        137, 176, 204, 168, 116, 191, 34, 191, 52, 125
    ];
    let signature = [
        177, 145, 6, 71, 182, 27, 50, 138, 7, 83, 30, 89, 179, 104, 215, 176, 5, 193, 158,
        38, 248, 216, 114, 18, 19, 227, 82, 160, 95, 224, 39, 198, 14, 58, 97, 205, 253,
        73, 72, 42, 213, 8, 193, 74, 105, 214, 220, 39, 241, 0, 207, 145, 88, 244, 87, 206,
        122, 30, 242, 45, 52, 8, 242, 167
    ];
    let message = [104, 101, 108, 108, 111, 32, 110, 111, 105, 114]; 
    let message_hash = [ 234, 156, 34, 19, 249, 17, 115, 78, 115, 153, 126, 124, 5, 80, 106, 125, 172, 34, 205, 99, 102, 22, 63, 24, 178, 96, 117, 62, 232, 246, 89, 47 ];

    let c = [ 124, 31, 250, 11, 232, 198, 211, 146, 23, 131, 232, 197, 165, 126, 252, 174, 190, 85, 72, 122, 226, 157, 198, 171, 187, 26, 187, 136, 84, 193, 190, 61 ];
    let s =  [ 255, 162, 206, 144, 197, 39, 225, 36, 253, 185, 234, 84, 114, 43, 192, 245, 76, 113, 73, 197, 188, 138, 63, 105, 188, 130, 115, 99, 27, 67, 123, 75 ];
    let pk_x = [ 4, 157, 206, 149, 41, 27, 219, 135, 154, 35, 47, 118, 17, 75, 254, 143, 81, 51, 183, 113, 195, 85, 214, 51, 148, 165, 112, 204, 163, 203, 124, 120 ];
    let pk_y = [ 48, 196, 19, 228, 254, 20, 86, 178, 54, 112, 63, 172, 224, 9, 247, 8, 6, 136, 157, 222, 31, 18, 206, 137, 176, 204, 168, 116, 191, 34, 191, 52 ];

    let nullifier_x = [ 4, 37, 192, 28, 66, 40, 130, 240, 219, 83, 60, 217, 151, 93, 137, 113, 194, 243, 78, 236, 29, 2, 121, 3, 74, 222, 139, 102, 70, 251, 25, 215 ];
    let nullifier_y = [ 111, 178, 173, 109, 152, 166, 38, 55, 10, 119, 79, 191, 98, 3, 157, 184, 53, 4, 232, 252, 89, 254, 44, 7, 105, 219, 112, 0, 223, 28, 160, 38 ];

    let merkle_path = [
        0x00000000000000000000000088DE460bb35DB40d11eca314633319949EfBB2Ed,
        0x0e837596707cc78ae40c6ce2e9bc85720d7a0602be2ed2050ab9845c8b139bc1,
        0x079c89d42ba128219a1bf927739f5c6aab9d8b193fe74f62910eb3c11f610237,
        0x14c0c095a9ba74fcfa89f3730a98295e22e709f0abbacc0c707c0d08615b00f1,
    ];
    let index = 0;
    let merkle_root = 0x0ee8fd0dccf422926a7d06ba3664707457cf2f81d5871e732d31521b89489a69;
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
