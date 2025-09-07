// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EthernautTest.t.sol";

interface Level33 {
    function currentCrateId() external view returns (uint256);
    function carousel(uint256) external view returns (uint256);

    error AnimalNameTooLong();

    function setAnimalAndSpin(string calldata) external;

    function changeAnimal(string calldata, uint256) external;

    function encodeAnimalName(string calldata) external pure returns (uint256);
}

contract Level33Test is EthernautTest {
    function testLevel33() public {
        _createLevel("33");

        Level33 level33Instance = Level33(levelInstance["33"]);

        // We have the following masks
        // ANIMAL_MASK  = 0xffffffffffffffffffff00000000000000000000000000000000000000000000
        // NEXT_ID_MASK = 0x00000000000000000000ffff0000000000000000000000000000000000000000
        // OWNER_MASK   = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff

        // encodeAnimaName stores the string in the lower 96 bits
        // For example "Hippopotamus"
        // Gives        = 0x0000000000000000000000000000000000000000486970706f706f74616d7573

        // In setAnimalAndSpin
        // encodedAnimal is shift left by a further 16 bits
        // For example, for "Hippopotamus" this
        // gives        = 0x00000000000000000000000000000000000000000000486970706f706f74616d
        // nextCrateId is set to the contents of (carousel[currentCrateId] & NEXT_ID_MASK)
        // then shifts right by 160 bits
        // This clears all the bits of carousel[currentCrateId] except XXXX at ffff in the NEXT_ID_MASK
        // It then shifts that right by 160
        // So nextCrateId
        // gives        = 0x000000000000000000000000000000000000000000000000000000000000xxxx
        // Where xxxx was the bits of createId between the lower 160 bits and the upper 80 bits

        // carousel[nextCrateId] is loaded, but cleared of the bits between the lower 160 bits and upper 80 bits
        // This is then XORed with encodedAnimal shifted left to the upper 80 bits

        // So if this slot previous set with an animal, and that animal was
        // the same: the upper 80 bits are set to zero
        // different: the upper 80 bits are set to a new word
        // zero: the encoded animal is set correctly

        // previous msg.sender is preserved for now

        // nextCrateID is then incremented by 1 and placed in the cleared bits above the lower 160 bits

        // The lower 160 bits are then ORed with msg.sender
        // If this slot was previously set with an owner, and that owner was
        // The same: the lower 160 bits are unchanged
        // different: the lower 160 bits are set to a completely new address, not msg.sender
        // zero: the lower 160 bits are set to msg.sender

        // We can see that the next crateId is 1 from the constructor
        // So to break the carousel, we can just set this to an animal name
        // So when Ethernaut uses setAnimalAndSpin, the animal they set will not be as expected!
        level33Instance.changeAnimal("Hippopotamus", 1);

        require(_submitLevel("33"));
    }
}
