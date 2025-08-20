// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

interface Ethernaut {
    event LevelInstanceCreatedLog(address indexed player, address indexed instance, address indexed level);
    event LevelCompletedLog(address indexed player, address indexed instance, address indexed level);

    function createLevelInstance(address level) external payable;
    function submitLevelInstance(address payable _instance) external;
}

interface Level0 {
    function info() external view returns (string memory);
    function info1() external view returns (string memory);
    function info2(string memory) external view returns (string memory);
    function infoNum() external view returns (uint256);
    function info42() external view returns (string memory);
    function theMethodName() external view returns (string memory);
    function method7123949() external view returns (string memory);
    function password() external view returns (string memory);
    function authenticate(string memory) external;
}

contract EthernautTest is Test {
    Ethernaut ethernaut;

    mapping(string => address) public levelInstance;

    function _getAddress(string memory _addressCode) internal view returns (address _address) {
        // Read addresses.log and parse ethernaut address
        string memory addressesJson = vm.readFile("addresses.log");
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
            delete entries[i];
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

    function testLevel0() public {
        _createLevel("0");
        Level0 levelInstance0 = Level0(levelInstance["0"]);
        // Using the clue to look at the info() function
        console2.logString(levelInstance0.info());
        // That tells us to look at info1()
        console2.logString(levelInstance0.info1());
        // That tells ut to look at info2("hello")
        console2.logString(levelInstance0.info2("hello"));
        // That tells us to look at infoNum() which returns next infoN() number
        console2.logUint(levelInstance0.infoNum());
        // That returns 42, so look at info42()
        console2.logString(levelInstance0.info42());
        // That says theMethodName() is the next place to look
        console2.logString(levelInstance0.theMethodName());
        // That says to look at method7123949()
        console2.logString(levelInstance0.method7123949());
        // That says if you know the password, submit it to authenticate
        // Assume it stores it at levelInstance0.password()
        levelInstance0.authenticate(levelInstance0.password());
        require(_submitLevel("0"));
    }
}
