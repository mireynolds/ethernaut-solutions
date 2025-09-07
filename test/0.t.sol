// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

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

contract Level0Test is EthernautTest {
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
