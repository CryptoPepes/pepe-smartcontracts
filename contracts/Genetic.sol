// solhint-disable-next-line
pragma solidity ^0.4.23;


contract Genetic {

    // TODO mutations
    // maximum number of random mutations per chromatid
    uint8 public constant R = 5;

    // solhint-disable-next-line function-max-lines
    function breed(uint256[2] mother, uint256[2] father, uint256 seed) internal view returns (uint256[2] memOffset) {
        // Meiosis I: recombining alleles (Chromosomal crossovers)

        // Note about optimization I: no cell duplication,
        //  producing 2 seeds/eggs per cell is enough, instead of 4 (like humans do)

        // Note about optimization II: crossovers happen,
        //  but only 1 side of the result is computed,
        //  as the other side will not affect anything.

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // allocate output
            // 1) get the pointer to our memory
            memOffset := mload(0x40)
            // 2) Change the free-memory pointer to keep our memory
            //     (we will only use 64 bytes: 2 values of 256 bits)
            mstore(0x40, add(memOffset, 64))


            // Put seed in scratchpad 0
            mstore(0x0, seed)
            // Also use the timestamp, best we could do to increase randomness
            //  without increasing costs dramatically. (Trade-off)
            mstore(0x20, timestamp)

            // Hash it for a universally random bitstring.
            let hash := keccak256(0, 64)

            // Byzantium VM does not support shift opcodes, will be introduced in Constantinople.
            // Soldity itself, in non-assembly, also just uses other opcodes to simulate it.
            // Optmizer should take care of inlining, just declare shiftR ourselves here.
            // Where possible, better optimization is applied to make it cheaper.
            function shiftR(value, offset) -> result {
                result := div(value, exp(2, offset))
            }

            // solhint-disable max-line-length
            // m_context << Instruction::SWAP1 << u256(2) << Instruction::EXP << Instruction::SWAP1 << (c_leftSigned ? Instruction::SDIV : Instruction::DIV);

            // optimization: although one side consists of multiple chromatids,
            //  we handle them just as one long chromatid:
            //  only difference is that a crossover in chromatid i affects chromatid i+1.
            //  No big deal, order and location is random anyway
            function processSide(fatherSrc, motherSrc, rngSrc) -> result {

                {
                    // initial rngSrc bit length: 254 bits

                    // Run the crossovers
                    // =====================================================

                    // Pick some crossovers
                    // Each crossover is spaced ~64 bits on average.
                    // To achieve this, we get a random 7 bit number, [0, 128), for each crossover.

                    // 256 / 64 = 4, we need 4 crossovers,
                    //  and will have 256 / 127 = 2 at least (rounded down).

                    // Get one bit determining if we should pick DNA from the father,
                    //  or from the mother.
                    // This changes every crossover. (by swapping father and mother)
                    {
                        if eq(and(rngSrc, 0x1), 0) {
                            // Swap mother and father,
                            // create a temporary variable (code golf XOR swap costs more in gas)
                            let temp := fatherSrc
                            fatherSrc := motherSrc
                            motherSrc := temp
                        }

                        // remove the bit from rng source, 253 rng bits left
                        rngSrc := shiftR(rngSrc, 1)
                    }

                    // Don't push/pop this all the time, we have just enough space on stack.
                    let mask := 0

                    // Cap at 4 crossovers, no more than that.
                    let cap := 0
                    let crossoverLen := and(rngSrc, 0x7f) // bin: 1111111 (7 bits ON)
                    // remove bits from hash, e.g. 254 - 7 = 247 left.
                    rngSrc := shiftR(rngSrc, 7)
                    let crossoverPos := crossoverLen

                    // optimization: instead of shifting with an opcode we don't have until Constantinople,
                    //  keep track of the a shifted number, updated using multiplications.
                    let crossoverPosLeading1 := 1

                    // solhint-disable-next-line no-empty-blocks
                    for { } and(lt(crossoverPos, 256), lt(cap, 4)) {

                        crossoverLen := and(rngSrc, 0x7f) // bin: 1111111 (7 bits ON)
                        // remove bits from hash, e.g. 254 - 7 = 247 left.
                        rngSrc := shiftR(rngSrc, 7)

                        crossoverPos := add(crossoverPos, crossoverLen)

                        cap := add(cap, 1)
                    } {

                        // Note: we go from right to left in the bit-string.

                        // Create a mask for this crossover.
                        // Example:
                        // 00000000000001111111111111111110000000000000000000000000000000000000000000000000000000000.....
                        // |Prev. data ||Crossover here  ||remaining data .......
                        //
                        // The crossover part is copied from the mother/father to the child.

                        // Create the bit-mask
                        // Create a bitstring that ignores the previous data:
                        // 00000000000001111111111111111111111111111111111111111111111111111111111111111111111111111.....
                        // First create a leading 1, just before the crossover, like:
                        // 00000000000010000000000000000000000000000000000000000000000000000000000.....
                        // Then substract 1, to get a long string of 1s
                        // 00000000000001111111111111111111111111111111111111111111111111111111111111111111111111111.....
                        // Now do the same for the remain part, and xor it.
                        // leading 1
                        // 00000000000000000000000000000010000000000000000000000000000000000000000000000000000000000.....
                        // sub 1
                        // 00000000000000000000000000000001111111111111111111111111111111111111111111111111111111111.....
                        // xor with other
                        // 00000000000001111111111111111111111111111111111111111111111111111111111111111111111111111.....
                        // 00000000000000000000000000000001111111111111111111111111111111111111111111111111111111111.....
                        // 00000000000001111111111111111110000000000000000000000000000000000000000000000000000000000.....

                        // Use the final shifted 1 of the previous crossover as the start marker
                        mask := sub(crossoverPosLeading1, 1)

                        // update for this crossover, (and will be used as start for next crossover)
                        crossoverPosLeading1 := mul(1, exp(2, crossoverPos))
                        mask := xor(mask,
                                    sub(crossoverPosLeading1, 1)
                        )

                        // Now add the parent data to the child genotype
                        // E.g.
                        // Mask:         00000000000001111111111111111110000000000000000000000000000000000000000000000000000000000....
                        // Parent:       10010111001000110101011111001010001011100000000000010011000001000100000001011101111000111....
                        // Child (pre):  00000000000000000000000000000001111110100101111111000011001010000000101010100000110110110....
                        // Child (post): 00000000000000110101011111001011111110100101111111000011001010000000101010100000110110110....

                        // To do this, we run: child_post = child_pre | (mask & father)
                        result := or(result, and(mask, fatherSrc))

                        // Swap father and mother, next crossover will take a string from the other.
                        let temp := fatherSrc
                        fatherSrc := motherSrc
                        motherSrc := temp
                    }

                    // We still have a left-over part that was not copied yet
                    // E.g., we have something like:
                    // Father: |            xxxxxxxxxxxxxxxxxxx          xxxxxxxxxxxxxxxxxxxxxxxx            ....
                    // Mother: |############                   xxxxxxxxxx                        xxxxxxxxxxxx....
                    // Child:  |            xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx....
                    // The ############ still needs to be applied to the child, also,
                    //  this can be done cheaper than in the loop above,
                    //  as we don't have to swap anything for the next crossover or something.

                    // At this point we have to assume 4 crossovers ran,
                    //  and that we only have 127 - 1 - (4 * 7) = 98 bits of randomness left.
                    // We stopped at the bit after the crossoverPos index, see "x":
                    // 000000000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.....
                    // now create a leading 1 at crossoverPos like:
                    // 000000001000000000000000000000000000000000000000000000000000000000000000000.....
                    // Sub 1, get the mask for what we had.
                    // 000000000111111111111111111111111111111111111111111111111111111111111111111.....
                    // Invert, and we have the final mask:
                    // 111111111000000000000000000000000000000000000000000000000000000000000000000.....
                    mask := not(sub(crossoverPosLeading1, 1))
                    // Apply it to the result
                    result := or(result, and(mask, fatherSrc))

                    // Random mutations
                    // =====================================================

                    // random mutations
                    // Put rng source in scratchpad 0
                    mstore(0x0, rngSrc)
                    // And some arbitrary padding in scratchpad 1,
                    //  used to create different hashes based on input size changes
                    mstore(0x20, 0x434f4c4c454354205045504553204f4e2043525950544f50455045532e494f21)
                    // Hash it for a universally random bitstring.
                    // Then reduce the number of 1s by AND-ing it with other *different* hashes.
                    // Each bit in mutations has a probability of 0.5^5 = 0.03125 = 3.125% to be a 1
                    let mutations := and(
                            and(
                                and(keccak256(0, 32), keccak256(1, 33)),
                                and(keccak256(2, 34), keccak256(3, 35))
                            ),
                            keccak256(0, 36)
                    )

                    result := xor(result, mutations)

                }
            }


            {

                // Get 1 bit of pseudo randomness that will
                //  determine if side #1 will come from the left, or right side.
                // Either 0 or 1, shift it by 5 bits to get either 0x0 or 0x20, cheaper later on.
                let relativeFatherSideLoc := mul(and(hash, 0x1), 0x20) // shift by 5 bits = mul by 2^5=32 (0x20)
                // Either 0 or 1, shift it by 5 bits to get either 0x0 or 0x20, cheaper later on.
                let relativeMotherSideLoc := mul(and(hash, 0x2), 0x10) // already shifted by 1, mul by 2^4=16 (0x10)

                // Now remove the used 2 bits from the hash, 254 bits remaining now.
                hash := div(hash, 4)

                // Process the side, load the relevant parent data that will be used.
                mstore(memOffset, processSide(
                    mload(add(father, relativeFatherSideLoc)),
                    mload(add(mother, relativeMotherSideLoc)),
                    hash
                ))

                // The other side will be the opposite index: 1 -> 0, 0 -> 1
                // Apply it to the location,
                //  which is either 0x20 (For index 1) or 0x0 for index 0.
                relativeFatherSideLoc := xor(relativeFatherSideLoc, 0x20)
                relativeMotherSideLoc := xor(relativeMotherSideLoc, 0x20)

                mstore(0x0, seed)
                // Second argument will be inverse,
                //  resulting in a different second hash.
                mstore(0x20, not(timestamp))

                // Now create another hash, for the other side
                hash := keccak256(0, 64)

                // Process the other side
                mstore(add(memOffset, 0x20), processSide(
                    mload(add(father, relativeFatherSideLoc)),
                    mload(add(mother, relativeMotherSideLoc)),
                    hash
                ))

            }

        }

        // Sample input:
        // ["0xAAABBBBBBBBCCCCCCCCAAAAAAAAABBBBBBBBBBCCCCCCCCCAABBBBBBBCCCCCCCC","0x4444444455555555555555556666666666666644444444455555555555666666"]
        //
        // ["0x1111111111112222222223333311111111122222223333333331111112222222","0x7777788888888888999999999999977777777777788888888888999999997777"]

        // Expected results (or similar, depends on the seed):
        // 0xAAABBBBBBBBCCCCCCCCAAAAAAAAABBBBBBBBBBCCCCCCCCCAABBBBBBBCCCCCCCC < Father side A
        // 0x4444444455555555555555556666666666666644444444455555555555666666 < Father side B

        // 0x1111111111112222222223333311111111122222223333333331111112222222 < Mother side A
        // 0x7777788888888888999999999999977777777777788888888888999999997777 < Mother side B

        //   xxxxxxxxxxxxxxxxx           xxxxxxxxx                         xx
        // 0xAAABBBBBBBBCCCCCD99999999998BBBBBBBBF77778888888888899999999774C < Child side A
        //   xxx                       xxxxxxxxxxx
        // 0x4441111111112222222223333366666666666222223333333331111112222222 < Child side B

        // And then random mutations, for gene pool expansion.
        // Each bit is flipped with a 3.125% chance

        // Example:
        //a2c37edc61dca0ca0b199e098c80fd5a221c2ad03605b4b54332361358745042 < random hash 1
        //c217d04b19a83fe497c1cf6e1e10030e455a0812a6949282feec27d67fe2baa7 < random hash 2
        //2636a55f38bed26d804c63a13628e21b2d701c902ca37b2b0ca94fada3821364 < random hash 3
        //86bb023a85e2da50ac233b946346a53aa070943b0a8e91c56e42ba181729a5f9 < random hash 4
        //5d71456a1288ab30ddd4c955384d42e66a09d424bd7743791e3eab8e09aa13f1 < random hash 5
        //0000000800800000000000000000000200000000000000000000020000000000 < resulting mutation
        //aaabbbbbbbbcccccd99999999998bbbbbbbbf77778888888888899999999774c < original
        //aaabbbb3bb3cccccd99999999998bbb9bbbbf7777888888888889b999999774c < mutated (= original XOR mutation)
    }

    // Generates (psuedo) random Pepe DNA
    function randomDNA(uint256 seed) internal pure returns (uint256[2] memOffset) {

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // allocate output
            // 1) get the pointer to our memory
            memOffset := mload(0x40)
            // 2) Change the free-memory pointer to keep our memory
            //     (we will only use 64 bytes: 2 values of 256 bits)
            mstore(0x40, add(memOffset, 64))

            // Load the seed into 1st scratchpad memory slot.
            // adjacent to the additional value (used to create two distinct hashes)
            mstore(0x0, seed)

            // In second scratchpad slot:
            // The additional value can be any word, as long as the caller uses
            //  it (second hash needs to be different)
            mstore(0x20, 0x434f4c4c454354205045504553204f4e2043525950544f50455045532e494f21)


            // // Create first element pointer of array
            // mstore(memOffset, add(memOffset, 64)) // pointer 1
            // mstore(add(memOffset, 32), add(memOffset, 96)) // pointer 2

            // control block to auto-pop the hash.
            {
                // L * N * 2 * 4 = 4 * 2 * 2 * 4 = 64 bytes, 2x 256 bit hash

                // Sha3 is cheaper than sha256, make use of it
                let hash := keccak256(0, 64)

                // Store first array value
                mstore(memOffset, hash)

                // Now hash again, but only 32 bytes of input,
                //  to ignore make the input different than the previous call,
                hash := keccak256(0, 32)
                mstore(add(memOffset, 32), hash)

            }

        }
    }

}
