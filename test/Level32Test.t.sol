// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level32 {
    function lockCounter() external view returns (uint256);
    function lockers(uint256) external view returns (address);
    function deployNewLock(bytes memory) external;
}

interface Locker {
    function open(uint8, bytes32, bytes32) external;
    function changeController(uint8, bytes32, bytes32, address) external;
}

contract Level32Test is EthernautTest {
    function testLevel32() public {
        _createLevel("32");

        Level32 level32Instance = Level32(levelInstance["32"]);

        Locker locker = Locker(level32Instance.lockers(0));

        // Inspecting the logs we can see that the locker was created with this signature
        // v 27
        // r 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91
        // s 0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2

        // There are no checks on v, so we can just flip the parity to obtain the other
        // solution and reuse that!

        // We can use the order of the secp256k1 elliptic curve group to flip the parity
        uint256 n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;

        uint256 v2 = 28; // flip the parity bit from 27 to 28
        // r is the same
        uint256 r2 = 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91;
        // s2 is just n - s1
        uint256 s2 = n - 0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2;

        // We can then set the controller to zero
        locker.changeController(uint8(v2), bytes32(r2), bytes32(s2), address(0));

        // Since there is no check on the zero address, anyone can open
        locker.open(0, 0, 0);

        require(_submitLevel("32"));
    }
}
