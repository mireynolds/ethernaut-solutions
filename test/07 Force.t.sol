// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

contract Destruct {
    constructor(address _level7) payable {
        selfdestruct(payable(_level7));
    }
}

contract Level7Test is EthernautTest {
    function testLevel7() public {
        _createLevel("7");

        // Self destruct to send all ether to the level contract
        Destruct destruct = new Destruct{value: 1 wei}(levelInstance["7"]);

        require(_submitLevel("7"));
    }
}
