use alloy_primitives::{keccak256, Address, B256, U256, Bloom, B64, Bytes};
use alloy_rlp::{Encodable, Header as RlpHeader, encode as rlp_encode};
use alloy_trie::{HashBuilder, Nibbles};
use alloy_trie::proof::ProofRetainer;
use alloy_consensus::Header as BlockHeader;

/// Returns a trie root and proof nodes for a trie with a single entry.
pub fn build_single_entry_trie_with_proof(key_hash: B256, leaf_value_bytes: Vec<u8>) -> (B256, Vec<Vec<u8>>) {
    // Secure trie uses the hashed key as the path, expanded to nibbles.
    let key_nibbles = Nibbles::unpack(key_hash.as_slice());

    // Tell the builder which key we want a proof for.
    let retainer = ProofRetainer::new(vec![key_nibbles.clone()]);
    let mut hb = HashBuilder::default().with_proof_retainer(retainer);

    // add_leaf expects keys in sorted order, with one leaf that's trivially satisfied.
    // value must be the raw leaf bytes, the trie will RLP-wrap it as the node’s value item.
    hb.add_leaf(key_nibbles.clone(), &leaf_value_bytes);

    // We now know the root hash after adding the leaf.
    let root = hb.root();

    // All that is left is to extract the proof nodes for our key.
    let proof_nodes = hb
        .take_proof_nodes()
        .matching_nodes_sorted(&key_nibbles)
        .into_iter()
        .map(|(_path, node_rlp)| node_rlp.to_vec())
        .collect::<Vec<_>>();

    (root, proof_nodes)
}

#[tokio::test]
async fn level_40_state_root_and_proofs() {

    // We want to build just one account, the target contract on L2.
    let account: Address = "0x4242424242424242424242424242424242424242".parse().unwrap();
    let nonce: U256 = "1".parse().unwrap();
    let balance: U256 = "0".parse().unwrap();

    // We want just one storage slot, which is our message hash, and set to "0x01".
    let slot: U256 = "0x0a5b2db89de7fac119725f01fcaf65b48b1835cf77619e00f4cfda12f32113bb".parse().unwrap();
    let slot_value: U256 = "0x01".parse().unwrap();

    // We can simplify with empty code, even though there is storage.
    let code: Vec<u8> = vec![];
    let code_hash: B256 = keccak256(&code);

    // Lets construct the storage trie and proof.
    let slot_bytes: [u8; 32] = slot.to_be_bytes();
    let storage_key_hash: B256 = keccak256(slot_bytes);

    // Storage leaf value bytes are RLP(minimal(slot_value)).
    // (i.e. you store the RLP encoding as the trie value bytes)
    let storage_leaf_value_bytes: Vec<u8> = rlp_encode(slot_value).to_vec();

    let (storage_root, storage_proof_nodes) =
        build_single_entry_trie_with_proof(storage_key_hash, storage_leaf_value_bytes);

    // We can now build the account rlp.
    let payload_len =
        nonce.length() +
        balance.length() +
        storage_root.length() +
        code_hash.length();

    let header = RlpHeader { list: true, payload_length: payload_len };

    let mut account_state_rlp = Vec::with_capacity(header.length() + payload_len);
    header.encode(&mut account_state_rlp);
    nonce.encode(&mut account_state_rlp);
    balance.encode(&mut account_state_rlp);
    storage_root.encode(&mut account_state_rlp);
    code_hash.encode(&mut account_state_rlp);

    // Now the state trie and proof.
    let state_key_hash: B256 = keccak256(account.as_slice());

    let (state_root, state_proof_nodes) =
        build_single_entry_trie_with_proof(state_key_hash, account_state_rlp.clone());

    // We will also need an rlp block header.
    // Build a legacy-style header, with most fields zeroed out.
    let header = BlockHeader {
        parent_hash: "0xed20f024a9b5b75b1dd37fe6c96b829ed766d78103b3ab8f442f3b2ebbc557b9".parse().unwrap(),
        ommers_hash: B256::ZERO,
        beneficiary: Address::ZERO,
        state_root,
        transactions_root: B256::ZERO,
        receipts_root: B256::ZERO,
        logs_bloom: Bloom::ZERO,
        difficulty: U256::ZERO,
        number: "60806041".parse().unwrap(),
        gas_limit: 0u64,
        gas_used: 0u64,
        timestamp: "1606824024".parse().unwrap(),
        extra_data: Vec::new().into(),
        mix_hash: B256::ZERO,
        nonce: B64::ZERO,

        base_fee_per_gas: None,
        withdrawals_root: None,
        blob_gas_used: None,
        excess_blob_gas: None,
        parent_beacon_block_root: None,

        requests_hash: None,
    };

    let rlp_block_header = alloy_rlp::encode(&header).to_vec();

    // Lets convert those proof nodes to rlp bytes.
    let storage_nodes: Vec<Bytes> = storage_proof_nodes
    .iter()
    .cloned()
    .map(Bytes::from)
    .collect();

    let state_nodes: Vec<Bytes> = state_proof_nodes
        .iter()
        .cloned()
        .map(Bytes::from)
        .collect();

    let storage_proof_rlp = alloy_rlp::encode(&storage_nodes).to_vec();
    let state_proof_rlp   = alloy_rlp::encode(&state_nodes).to_vec();

    // And we're done. Lets log the results.
    println!("storage_root:  0x{}", hex::encode(storage_root));
    println!("state_root:    0x{}", hex::encode(state_root));
    println!("account_rlp:   0x{}", hex::encode(&account_state_rlp));

    println!("storage_proof_rlp: 0x{}", hex::encode(&storage_proof_rlp));
    println!("state_proof_rlp:   0x{}", hex::encode(&state_proof_rlp));

    println!("rlp_block_header: 0x{}", hex::encode(&rlp_block_header));
}