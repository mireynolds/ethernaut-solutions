// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level26 {
    function cryptoVault() external view returns (address);
    function delegatedFrom() external view returns (address);
    function forta() external view returns (address);
    function delegateTransfer(address, uint256, address) external returns (bool);
}

interface CryptoVault {
    function underlying() external view returns (address);
    function sweptTokensRecipient() external view returns (address);
    function sweepToken(address) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function raiseAlert(address user) external;
}

contract Level26Test is EthernautTest {
    Level26 level26Instance;
    IForta forta;
    CryptoVault cryptoVault;

    function testLevel26() public {
        _createLevel("26");

        level26Instance = Level26(levelInstance["26"]);

        cryptoVault = CryptoVault(level26Instance.cryptoVault());

        // Lets log these addresses
        console2.log("Level 26", address(level26Instance));
        console2.log("Crypto Vault", address(cryptoVault));

        // Lets see which is the underlying in the vault
        console2.log("Underlying", cryptoVault.underlying());
        console2.log("Delegated From", level26Instance.delegatedFrom());
        console2.log("Swept Tokens Recipient", cryptoVault.sweptTokensRecipient());
        // This tells us that
        // Swept Token Recipient is the Level 26 Contract
        // Underlying is the level Level 26 Contract
        // Delegated From is not the underlying

        // So we can sweep ourselves the token,
        // which ends up draining the vault of the underlying anyway
        // cryptoVault.sweepToken(level26Instance.delegatedFrom());

        // To prevent this, we can set ourselves a detection bot
        // Then raise an alert on the Forta contract when the condition
        // for this is met
        forta = IForta(level26Instance.forta());
        forta.setDetectionBot(address(this));

        require(_submitLevel("26"));
    }

    function handleTransaction(address user, bytes calldata msgData) external {
        if (
            user == address(this) // User should be our contract
                && msg.sender == address(forta) // Sender should be the forta contract
                && bytes4(msgData[0:4]) == Level26.delegateTransfer.selector // Function selector should be delegateTransfer
                && address(bytes20(msgData[80:100])) == address(cryptoVault) // Original sender should be CryptoVault
        ) {
            forta.raiseAlert(user); // Raise the alert, which will prevent draining
        }
    }
}
