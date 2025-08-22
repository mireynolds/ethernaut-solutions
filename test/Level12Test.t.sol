// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level12 {
    function unlock(bytes16 _key) external;
}

contract Level12Test is EthernautTest {
    function testLevel12() public {
        _createLevel("12");

        // By the solidity storage rules, the slot we need is five
        // We can view this as if we were looking at the data before calling
        bytes32 keySlot = vm.load(levelInstance["12"], bytes32(uint256(5)));
        // We then submit this as the key formatted to uint16 as per the contract
        Level12(levelInstance["12"]).unlock(bytes16(keySlot));

        require(_submitLevel("12"));
    }
}
