use dep::ecrecover;
use dep::plume::plume_v2;
use dep::std::hash::pedersen_hash;
use dep::trees::merkle::MerkleTree;

global DEPTH = 4;

fn main(
    pub_key: [u8; 64],
    signature: [u8; 64],
    hashed_message: pub [u8; 32],
    nullifier: pub Field,
    merkle_path: [Field; DEPTH],
    index: Field,
    merkle_root: pub Field,
    claimer_priv: Field,
    claimer_pub: pub Field,
) {
    let key = ecrecover::secp256k1::PubKey::from_unified(pub_key);
    let address = ecrecover::ecrecover(key.pub_x, key.pub_y, signature, hashed_message);

    let signature_as_fields = signature.map(|x: u8| x as Field);
    let calculatedNullifier = std::hash::pedersen_hash(signature_as_fields);
    assert(calculatedNullifier == nullifier);

    let mt = MerkleTree::default(merkle_root, pedersen_hash);
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
    let hashed_message = [
        234, 156, 34, 19, 249, 17, 115, 78, 115, 153, 126, 124, 5, 80, 106, 125, 172, 34, 205, 99,
        102, 22, 63, 24, 178, 96, 117, 62, 232, 246, 89, 47,
    ];

    let nullifier = 0x02c78c1686648471e731d3fee7c067be1dac7e76f9269abf1c4a5370517f6561;
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
        hashed_message,
        nullifier,
        merkle_path,
        index,
        merkle_root,
        claimer,
        claimer,
    );
}
