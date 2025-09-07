// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level8 {
    function unlock(bytes32) external;
}

contract Level8Test is EthernautTest {
    function testLevel8() public {
        _createLevel("8");

        // Variables marked as private are still accessible in the contract state
        // It will be in position uint256 1 of the contract
        // We can use the foundry test load function, as if we viewed the state prior to calling the function
        Level8(levelInstance["8"]).unlock(vm.load(levelInstance["8"], bytes32(uint256(1))));

        require(_submitLevel("8"));
    }
}
