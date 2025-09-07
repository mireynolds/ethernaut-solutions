// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level18 {
    function setSolver(address) external;
}

contract Level18Test is EthernautTest {
    function testLevel18() public {
        _createLevel("18");

        // We need to deploy a contract which returns the number 42
        // Minimal bytecode
        // We need MSTORE(0, 42) followed by RETURN(0, 32)
        // We first need to put 42 followed by zero on the stack
        // PUSH1 (60) 0x2a (42) followed by PUSH0 (5f)
        // MSTORE (52) puts 42 at memory position 0
        // We then need to put 32 followed by zero on the stack
        // PUSH1 (60) 32 (20) followed by PUSH0 (5f)
        // Then we can do the return of that 32 in memory position 0
        // RETURN (f3)
        // This gives 602A5F5260205FF3
        // Append this with a basic runtime to create the creation code
        // We need to copy the code to memory and return it
        // The runtime will start at position 10 in the creation code
        // The size of the runtime is 8 bytes
        // We can put this at position 0 in memory
        // So we need to put 8, followed by 10, followed by 0 on the stack
        // PUSH1 (08), PUSH1 (0A), PUSH0 (5f)
        // We can then do CODECOPY (39)
        // Then we need to return that bit of memory
        // We need to put 8 followed by 0 on the stack
        // PUSH1 (08), PUSH0 (5f)
        // Then we can do RETURN (f3)
        // This gives 5F600A60083960085FF3
        // Concatenate the two parts to get the full creation code
        address solver; // Define solver so we can set it after create in assembly block

        assembly ("memory-safe") {
            // Store the creation code in memory starting at position 0
            mstore(0, 0x6008600A5F3960085FF3602A5F5260205FF30000000000000000000000000000)
            // Create the solver, and set solver to the created address
            solver := create(0, 0, 0x12)
        }

        Level18(levelInstance["18"]).setSolver(solver);

        require(_submitLevel("18"));
    }
}
