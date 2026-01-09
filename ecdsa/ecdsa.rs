use ethers_core::{
    rand::rngs::OsRng,
    types::{Address, H256, Signature, U256},
};

use k256::{
    AffinePoint, ProjectivePoint, PublicKey, Scalar, Secp256k1,
    ecdsa::{RecoveryId, Signature as K256Signature, VerifyingKey},
    elliptic_curve::{
        Field, FieldBytes, bigint::U256 as BigUint256, ff::PrimeField, group::Group, ops::Reduce,
        point::AffineCoordinates, sec1::ToEncodedPoint
    },
};

// The signature from Alice's redeem transaction uses v == 28.
// So this assumes v == 28 (recovery id == 1).
// Returns uncompressed pubkey: 65 bytes (0x04 || X || Y).
pub fn recover_uncompressed_pubkey_v28(
    hash: H256,
    r: U256,
    s: U256,
    v: u64,
) -> Result<[u8; 65], String> {
    // check that v == 28
    if v != 28 {
        return Err("v must be 28".to_string());
    }

    // Convert r and s to big endian
    let mut rb = [0u8; 32];
    let mut sb = [0u8; 32];
    r.to_big_endian(&mut rb);
    s.to_big_endian(&mut sb);

    // Build k256 signature from big endian r and s
    let signature = K256Signature::from_scalars(rb, sb).map_err(|_| "bad r/s".to_string())?;

    // Recover public key
    let public_key = VerifyingKey::recover_from_prehash(
        hash.as_bytes(),
        &signature,
        RecoveryId::from_byte(1).unwrap(),
    )
    .map_err(|_| "recover failed".to_string())?;

    // Encode pubkey (uncompressed)
    public_key
        .to_encoded_point(false)
        .as_bytes()
        .try_into()
        .map_err(|_| "unexpected pubkey length".to_string())
}


// Given u1, u2, and a public key we can compute x mod n of the point:
// p = u1 * G + u2 * Q_A
// where G is the generator point and Q_A is the public key point.
// Returns x mod n as a Scalar.
pub fn compute_x_mod_n_from_pubkey_bytes(
    u1: Scalar,
    u2: Scalar,
    pubkey_sec1: &[u8],
) -> Result<Scalar, String> {
    // Parse public key from SEC1 bytes
    let qa =
        PublicKey::from_sec1_bytes(pubkey_sec1).map_err(|_| "invalid public key".to_string())?;

    // Define generator point
    let g = ProjectivePoint::GENERATOR;

    // Convert public key to ProjectivePoint
    let qa_point = ProjectivePoint::from(*qa.as_affine());

    // Compute point: p = u1 * G + u2 * Q_A
    let p = g * u1 + qa_point * u2;

    // Ensure p is not identity
    if bool::from(p.is_identity()) {
        return Err("computed point is identity".to_string());
    }

    // Get affine coordinates
    let affine = AffinePoint::from(p);

    // Get x coordinate as bytes
    let x_bytes: [u8; 32] = affine.x().into();

    // Set FieldBytes to Secp256k1 field
    let fb: FieldBytes<Secp256k1> = x_bytes.into();

    // Then reduce to mod n on that field
    let x_mod_n: Scalar = <Scalar as Reduce<BigUint256>>::reduce_bytes(&fb);

    // Return x mod n
    Ok(x_mod_n)
}

// Reduce any bytes32 value to secp256k1 curve order n into a Scalar.
fn bytes32_to_scalar_mod_n(bytes: [u8; 32]) -> Scalar {
    // Set FieldBytes to Secp256k1 "field bytes" container
    let fb: FieldBytes<Secp256k1> = bytes.into();

    // Reduce the bytes mod curve order n (Scalar field)
    <Scalar as Reduce<BigUint256>>::reduce_bytes(&fb)
}

// Convert an U256 into a Scalar by reducing mod n.
pub fn u256_to_scalar_mod_n(x: U256) -> Scalar {
    let mut be = [0u8; 32];
    x.to_big_endian(&mut be);
    bytes32_to_scalar_mod_n(be)
}

// Convert an H256 into a Scalar by reducing mod n.
pub fn h256_to_scalar_mod_n(x: H256) -> Scalar {
    let mut be = [0u8; 32];
    be.copy_from_slice(x.as_bytes());
    bytes32_to_scalar_mod_n(be)
}

#[tokio::test]
async fn level_35_find_signature_that_recovers_to_a11ce() {
    // This test generates a signature that can be used in level 35.

    let expected: Address = "0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e"
        .parse()
        .unwrap();

    // These is the hash and signature used by Alice to redeem her voucher.
    // We can use this to generate the full public key.
    let redeemed_hash: H256 = "0x87f1c8cd4c0e19511304b612a9b4996f8c2bd795796636bd25812cd5b0b6a973"
        .parse()
        .unwrap();
    let redeemed_v = 28;
    let redeemed_r = U256::from_dec_str(
        "77398151667370781901280882129684639004764596625711782998382991865558458779983",
    )
    .unwrap();
    let redeemed_s = U256::from_dec_str(
        "19592434626891232575443071861393355596737812609873232080424902841704861785618",
    )
    .unwrap();

    // We should recover the full public key from this signature and hash.
    // Function defined above as it is quite long.
    let pubkey_bytes =
        recover_uncompressed_pubkey_v28(redeemed_hash, redeemed_r, redeemed_s, redeemed_v).unwrap();

    // Our only constraints on e (the hash) are:
    // 1. It needs to greater than 10000000000000000000.
    // 2. It with the accompanying signature recovers to Alice's address.
    let threshold = U256::from(10000000000000000000u64);
    let mut e = U256::from(0u64);

    // We want recovered to equal expected.
    let mut recovered = Address::default();
    let mut hash = H256::default();
    let mut sig = Signature {
        r: U256::zero(),
        s: U256::zero(),
        v: 27u64,
    };

    // Loop until we get a valid e and the recovered address matches expected.
    // This should not take long at all given the approach taken.
    while e < threshold || recovered != expected {
        // The approach here is to randomly generate u1 and u2 values,
        // then compute r, s, and z (from which we get e).
        // We can do this by setting the calculated point to r.
        // Since u1 and u2 are random, we will quickly find an e
        // that meets the threshold and recovers to the expected address.

        // Calculate a random u1 and u2 in [1, n-1].
        // Calculate a random u1 and u2 in [1, n-1].
        // We need to use the k256 Scalar type for these calculations.
        // We can convert back to U256 later.
        let u1 = Scalar::random(&mut OsRng);
        let u2 = Scalar::random(&mut OsRng);

        // We can then computer r using u1, u2, and the public key.
        // Function defined above as it is quite long.
        let r_scalar = compute_x_mod_n_from_pubkey_bytes(u1, u2, &pubkey_bytes).unwrap();

        // We can then find s.
        let u2_inv = u2.invert(); // inverts u2 mod n
        let s_scalar = (u2_inv).map(|u2_inv| r_scalar * u2_inv).unwrap(); // s = r * u2^-1 mod n

        // We can then calculate z from u1 and s
        let z_scalar = Some(u1 * s_scalar).unwrap();

        // Finally we can get e from z.
        let e_bytes: [u8; 32] = z_scalar.to_repr().into();

        // Convert back from scalars.
        e = U256::from_big_endian(&e_bytes);
        hash = H256::from({
            let mut b = [0u8; 32];
            e.to_big_endian(&mut b);
            b
        });
        let r_bytes: [u8; 32] = r_scalar.to_repr().into();
        let s_bytes: [u8; 32] = s_scalar.to_repr().into();
        let r = U256::from_big_endian(&r_bytes);
        let s = U256::from_big_endian(&s_bytes);

        // This is a bit of a cheat to find the right v value.
        // But we also need to ensure the signature recovers correctly.
        for v in [27u64, 28u64] {
            sig = Signature { r, s, v };
            match sig.recover(hash) {
                Ok(addr) => {
                    recovered = addr;
                    break;
                }
                Err(_) => {}
            }
        }
    }

    // Prints out a successful hash and signature that recovers to Alice's address.
    println!("Level 35");
    println!("hash: 0x{}", hex::encode(hash.as_bytes()));
    println!("signature: 0x{}", hex::encode(sig.to_vec()));
    println!("recovered: {:?}", recovered);
}

#[tokio::test]
async fn level_37_find_d_for_reused_r() {
    // Using the reused r values from level 37.
    let r = U256::from_dec_str(
        "103757219997015733207792601658906671456879056669062135265261565095369865575488",
    ).unwrap();

    let s_1 = U256::from_dec_str(
        "50663344087995949762213388216373125606572599093254664098885226352774073366499",
    ).unwrap();

    let s_2 = U256::from_dec_str(
        "34479580352079828831740340677067427602009569782867523588952791137270191524473",
    ).unwrap();

    let e_1: H256 = "0x937fa99fb61f6cd81c00ddda80cc218c11c9a731d54ce8859cb2309c77b79bf3"
        .parse()
        .unwrap();

    let e_2: H256 = "0x6a0d6cd0c2ca5d901d94d52e8d9484e4452a3668ae20d63088909611a7dccc51"
        .parse()
        .unwrap();

    let expected: Address = "0x03E2cf81BBE61D1fD1421aFF98e8605a5A9e953a"
        .parse()
        .unwrap();

    // Convert to scalars.
    let r_scalar = u256_to_scalar_mod_n(r);
    let s1_scalar = u256_to_scalar_mod_n(s_1);
    let s2_scalar = u256_to_scalar_mod_n(s_2);
    let e1_scalar = h256_to_scalar_mod_n(e_1);
    let e2_scalar = h256_to_scalar_mod_n(e_2);

    // Calculate k.
    let k_scalar = Some((e1_scalar - e2_scalar) * (s1_scalar - s2_scalar).invert().unwrap()).unwrap();

    // Calculate d.
    let d_scalar = Some((s1_scalar * k_scalar - e1_scalar) * r_scalar.invert().unwrap()).unwrap();

    // Derive public key from d.
    let pubkey_point = ProjectivePoint::GENERATOR * d_scalar;
    let pubkey_affine = AffinePoint::from(pubkey_point);
    let pubkey = PublicKey::from_affine(pubkey_affine).unwrap();
    let pubkey_bytes = pubkey.to_encoded_point(false).as_bytes().to_owned();

    // Check that the derived public key matches the expected address.
    let derived_address = {
        let hash = ethers_core::utils::keccak256(&pubkey_bytes[1..]);
        Address::from_slice(&hash[12..])
    }; 

    assert_eq!(derived_address, expected);

    // Get d_bytes value.
    let d_bytes: [u8; 32] = d_scalar.to_repr().into();

    // Prints out a successful key.
    println!("Level 37");
    println!("key: 0x{}", hex::encode(d_bytes));
}