// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level37 {
    function setAdmin(bytes memory, address) external;
    function switchLock(bytes memory signature) external;
    function withdraw() external;
    function hash_message(string memory message) external pure returns (bytes32);
}

contract Level37Test is EthernautTest {
    function testLevel37() public {
        _createLevel("37", 0.001 ether);

        Level37 level37Instance = Level37(levelInstance["37"]);

        // We can see that the signature used for switchLock is
        // message 0x937fa99fb61f6cd81c00ddda80cc218c11c9a731d54ce8859cb2309c77b79bf3,
        // v 27,
        // r 103757219997015733207792601658906671456879056669062135265261565095369865575488,
        // s 50663344087995949762213388216373125606572599093254664098885226352774073366499

        // The signature used for setAdmin is
        // message 0x6a0d6cd0c2ca5d901d94d52e8d9484e4452a3668ae20d63088909611a7dccc51,
        // v 27,
        // r 103757219997015733207792601658906671456879056669062135265261565095369865575488,
        // s 34479580352079828831740340677067427602009569782867523588952791137270191524473

        // This is a catastrophic failure. A nonce has been reused across different signatures.
        // The private key is recoverable from these two signatures.

        // Using the ecdsa crate, we can find the private key. Run ./ethernaut ecdsa .
        uint256 privateKey = 0x10a6891de55baf453d66c5faede86eabccf93f3d284540d205f24207670855cc;

        // Now we need to sign a message to set ourselves as admin.
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(privateKey, level37Instance.hash_message(string(abi.encodePacked("admin", "2", address(this)))));

        // We can now set ourselves as admin.
        level37Instance.setAdmin(abi.encodePacked(r, s, v), address(this));

        // Now we need to sign a message to set unlock, so we can withdraw.
        (v, r, s) = vm.sign(privateKey, level37Instance.hash_message(string(abi.encodePacked("lock", "3"))));

        // Now we can unlock.
        level37Instance.switchLock(abi.encodePacked(r, s, v));

        // Then withdraw.
        level37Instance.withdraw();

        require(_submitLevel("37"));
    }

    receive() external payable {}
}
