use bignum::BigNum;
use ecrecover;
use nodash::{pack_bytes, field_from_bytes};
use noir_bigcurve::BigCurve;
use noir_bigcurve::curves::secp256k1::{Secp256k1, Secp256k1Fr, Secp256k1Scalar};
use noir_bigcurve::scalar_field::ScalarField;
use plume::plume_v2;
use std::hash::poseidon2::Poseidon2::hash;
use trees::merkle::MerkleTree;

global DEPTH = 4;

fn poseidon2_hasher(leaves: [Field; 2]) -> Field {
    hash([leaves[0], leaves[1]], 2)
}

// shamelessly stolen from https://github.com/AztecProtocol/aztec-packages/blob/a2ed567ad42b237088c110ce12ce8212d5099da2/noir-projects/noir-protocol-circuits/crates/types/src/utils/field.nr#L18
pub fn to_field<let N: u32>(bytes: [u8; N]) -> Field {
    let mut as_field = 0;
    let mut offset = 1;
    for i in 0..N {
        let mut index = i;
        index = N - i - 1;
        as_field += (bytes[index] as Field) * offset;
        offset *= 256;
    }
    std::as_witness(as_field);

    as_field
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
    merkle_path: [[u8; 32]; DEPTH],
    index: Field,
    merkle_root: pub [u8; 32],
    claimer_priv: [u8; 32],
    claimer_pub: pub [u8; 32],
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

    let mt = MerkleTree::default(to_field(merkle_root), poseidon2_hasher);
    mt.membership(address, index, merkle_path.map(|m| to_field(m)));
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
        17, 144, 18, 16, 110, 231, 201, 207, 233, 50, 106, 60, 163, 129, 152, 152, 60,
        199, 155, 44, 114, 74, 156, 123, 120, 198, 132, 148, 24, 125, 82, 89
    ];
    let s = [
        96,
        110,
        125,
        26,
        217,
        205,
        90,
        189,
        183,
        46,
        221,
        98,
        116,
        175,
        48,
        114,
        213,
        180,
        9,
        29,
        108,
        10,
        179,
        160,
        151,
        242,
        101,
        18,
        227,
        180,
        204,
        53
    ];
    let pk_x = [
        4,
        157,
        206,
        149,
        41,
        27,
        219,
        135,
        154,
        35,
        47,
        118,
        17,
        75,
        254,
        143,
        81,
        51,
        183,
        113,
        195,
        85,
        214,
        51,
        148,
        165,
        112,
        204,
        163,
        203,
        124,
        120
    ];
    let pk_y = [
        48, 196, 19, 228, 254, 20, 86, 178, 54, 112, 63, 172, 224, 9, 247, 8, 6, 136, 157, 222, 31,
        18, 206, 137, 176, 204, 168, 116, 191, 34, 191, 52,
    ];
    let nullifier_x = [
        126,
        69,
        224,
        200,
        206,
        77,
        104,
        158,
        99,
        0,
        180,
        150,
        134,
        10,
        0,
        69,
        145,
        87,
        67,
        132,
        88,
        21,
        243,
        45,
        84,
        193,
        57,
        21,
        112,
        16,
        10,
        3
    ];
    let nullifier_y = [
        115,
        86,
        136,
        135,
        65,
        107,
        203,
        44,
        240,
        251,
        151,
        62,
        176,
        130,
        11,
        26,
        143,
        140,
        188,
        128,
        237,
        71,
        46,
        44,
        141,
        204,
        27,
        31,
        204,
        225,
        38,
        105
    ];
    let merkle_path = [
        [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            136,
            222,
            70,
            11,
            179,
            93,
            180,
            13,
            17,
            236,
            163,
            20,
            99,
            51,
            25,
            148,
            158,
            251,
            178,
            237
        ],
        [
            27,
            18,
            175,
            155,
            63,
            236,
            136,
            151,
            240,
            156,
            26,
            102,
            157,
            180,
            21,
            2,
            189,
            107,
            20,
            222,
            65,
            72,
            219,
            194,
            195,
            118,
            130,
            51,
            90,
            148,
            70,
            224
        ],
        [
            36,
            242,
            247,
            173,
            89,
            40,
            153,
            6,
            227,
            34,
            126,
            99,
            15,
            65,
            12,
            157,
            32,
            182,
            200,
            155,
            105,
            13,
            241,
            218,
            81,
            35,
            253,
            218,
            73,
            30,
            221,
            222
        ],
        [
            6,
            203,
            120,
            194,
            124,
            212,
            192,
            207,
            150,
            26,
            129,
            191,
            84,
            117,
            210,
            236,
            135,
            42,
            111,
            23,
            237,
            21,
            37,
            138,
            42,
            11,
            247,
            249,
            180,
            70,
            17,
            167
        ]
    ];
    let index = 0;
    let merkle_root = [
        13,
        220,
        251,
        168,
        163,
        207,
        202,
        2,
        187,
        189,
        52,
        52,
        205,
        108,
        209,
        176,
        191,
        23,
        5,
        187,
        97,
        106,
        73,
        228,
        237,
        54,
        174,
        111,
        168,
        202,
        25,
        142
    ];
    let claimer = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 138, 236, 31, 129, 203, 144, 32, 78, 60,
        154, 161, 174, 237, 41, 21, 193, 129, 203, 190, 40
    ];

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
