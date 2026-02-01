// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/StdJson.sol";

interface Ethernaut {
    event LevelInstanceCreatedLog(address indexed player, address indexed instance, address indexed level);
    event LevelCompletedLog(address indexed player, address indexed instance, address indexed level);

    function createLevelInstance(address level) external payable;
    function submitLevelInstance(address payable _instance) external;
}

contract EthernautTest is Test {
    Ethernaut ethernaut;

    mapping(string => address) public levelInstance;

    function _getAddress(string memory _addressCode) internal view returns (address _address) {
        // Read addresses.log and parse ethernaut address
        string memory addressesJson = vm.readFile("./addresses.log");
        _address = vm.parseJsonAddress(addressesJson, string.concat(".", _addressCode));
    }

    function setUp() public {
        ethernaut = Ethernaut(_getAddress("ethernaut"));
    }

    function _createLevel(string memory _level) internal {
        _createLevel(_level, 0);
    }

    function _createLevel(string memory _level, uint256 amount) internal {
        vm.recordLogs();
        ethernaut.createLevelInstance{value: amount}(_getAddress(_level));
        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == Ethernaut.LevelInstanceCreatedLog.selector) {
                levelInstance[_level] = address(uint160(uint256(entries[i].topics[2])));
            }
        }
    }

    function _submitLevel(string memory _level) internal returns (bool) {
        vm.recordLogs();
        ethernaut.submitLevelInstance(payable(levelInstance[_level]));
        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == Ethernaut.LevelCompletedLog.selector) {
                return true;
            }
        }
    }
}
