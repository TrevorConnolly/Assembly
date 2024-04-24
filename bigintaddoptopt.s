   .section .rodata

    .section .data

    .section .bss

    .section .text

        .global BigInt_add

        .equ TRUE, 1
        .equ FALSE, 0
        .equ OADDEND1, 8
        .equ OADDEND2, 16
        .equ OSUM, 24
        .equ ULCARRY, 32
        .equ ULSUM, 40
        .equ LINDEX, 48
        .equ LSUMLENGTH, 56
        .equ LLENGTHONE, 64
        .equ LLENGTHTWO, 72
        .equ LLARGER, 80


        .equ LLENGTH, 0
        .equ MAX_DIGITS, 32768
        .equ DIGITS_OFFSET, 8
        .equ ULSize, 3
        .equ BIGINTADD_STACK_BYTECOUNT, 96


        // Local variable registers:
        LLENGTHONE_VAR  .req x22
        LLENGTHTWO_VAR  .req x23
        ULCARRY_VAR     .req x24
        ULSUM_VAR       .req x25
        LINDEX_VAR      .req x26
        LSUMLENGTH_VAR  .req x27
        LLARGER_VAR     .req x28


        // Parameter variable registers:
        OADDEND1_VAR    .req x19
        OADDEND2_VAR    .req x20
        OSUM_VAR        .req x21



    /* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
    // distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
    // overflow occurred, and 1 (TRUE) otherwise. */
    BigInt_add:

        // Prologue
        sub     sp, sp, BIGINTADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, OADDEND1]
        str     x20, [sp, OADDEND2]
        str     x21, [sp, OSUM]
        str     x22, [sp, LLENGTHONE]
        str     x23, [sp, LLENGTHTWO]
        str     x24, [sp, ULCARRY]
        str     x25, [sp, ULSUM]
        str     x26, [sp, LINDEX]
        str     x27, [sp, LSUMLENGTH]
        str     x28, [sp, LLARGER]



        // Store parameters in registers
        mov     OADDEND1_VAR, x0      // Store oAddend1
        mov     OADDEND2_VAR, x1      // Store oAddend2
        mov     OSUM_VAR, x2          // Store oSum


        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        mov     LLENGTHONE_VAR, OADDEND1_VAR
        ldr     LLENGTHONE_VAR, [LLENGTHONE_VAR, LLENGTH]
        mov     LLENGTHTWO_VAR, OADDEND2_VAR
        ldr     LLENGTHTWO_VAR, [LLENGTHTWO_VAR, LLENGTH]

        // if (lLength1 > lLength2) goto else1;
        cmp     LLENGTHONE_VAR, LLENGTHTWO_VAR
        bgt     else1
        
        // lLarger = lLength2;
        mov     LLARGER_VAR, LLENGTHTWO_VAR
        b endif1

    else1:
        // lLarger = lLength2;
        mov     LLARGER_VAR, LLENGTHONE_VAR
        

    endif1:
        // lSumLength = lLarger;
        mov     LSUMLENGTH_VAR, LLARGER_VAR

        // if (!(oSum->lLength > lSumLength)) goto initialize;
        mov     x0, OSUM_VAR
        ldr     x1, [x0, LLENGTH]
        mov     x2, LSUMLENGTH_VAR
        cmp     x1, x2
        ble     initialize

        // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        add     x0, x0, DIGITS_OFFSET  // Pointer to the digits array
        mov     x1, 0
        mov     x2, MAX_DIGITS
        lsl     x2, x2, ULSize         // MAX_DIGITS * sizeof(unsigned long)
        bl      memset

    initialize:
        // ulCarry = 0;
        mov     x0, 0
        mov     ULCARRY_VAR, x0 

        // lIndex = 0;
        mov     LINDEX_VAR, x0 

        // if (lIndex >= lSumLength) goto check_carry;
        mov     x0, LINDEX_VAR
        mov     x1, LSUMLENGTH_VAR
        cmp     x0, x1
        bge     check_carry

        // clear carry bit to ensure it's 0
        mov     x1, #0
        mov     x2, #0
        adds    x2, x1, x2

    loop1:

        // ulSum = ulCarry;
        // mov     x0, ULCARRY_VAR
        // mov     ULSUM_VAR, x0 

        // ulCarry = 0;
        // mov     x0, 0
        // mov     ULCARRY_VAR, x0 

        // ulSum += oAddend1->aulDigits[lIndex];
        mov     x1, OADDEND1_VAR
        add     x1, x1, DIGITS_OFFSET  // Pointer to the digits array
        mov     x2, LINDEX_VAR
        lsl     x2, x2, ULSize         // Multiply current index by size of (ul)
        add     x1, x1, x2
        ldr     x2, [x1]
        adcs    ULSUM_VAR, ULSUM_VAR, x2


        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto add_second; 
        // mov     x3, ULSUM_VAR
        // cmp     x3, x2
        // bhs     add_second

        // ulCarry = 1;
        // mov     x0, 1
        // mov     ULCARRY_VAR, x0 

    add_second:

        // ulSum += oAddend2->aulDigits[lIndex];

        mov     x1, OADDEND2_VAR
        add     x1, x1, DIGITS_OFFSET  // Pointer to the digits array
        mov     x2, LINDEX_VAR
        lsl     x2, x2, ULSize         // Multiply current index by size of (ul)
        add     x1, x1, x2
        ldr     x2, [x1]
        adcs    ULSUM_VAR, ULSUM_VAR, x2

        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto store_sum;
        // mov     x3, ULSUM_VAR
        // cmp     x3, x2
        // bhs     store_sum

        // ulCarry = 1;
        // mov     x0, 1
        // mov     ULCARRY_VAR, x0 

    store_sum:
        
        // oSum->aulDigits[lIndex] = ulSum;
        mov     x1, OSUM_VAR
        add     x1, x1, DIGITS_OFFSET  // pointer to the digits array
        mov     x2, LINDEX_VAR
        lsl     x2, x2, ULSize
        add     x1, x1, x2
        mov     x2, ULSUM_VAR
        str     x2, [x1]

        // lIndex++;
        add     LINDEX_VAR, LINDEX_VAR, 1
                                                                      
    check_end:

        // if ((lIndex - lSumLength) < 0 ) goto loop1;
        mov     x0, LINDEX_VAR
        mov     x1, LSUMLENGTH_VAR
        sub     x0, x0, x1
        cbnz    x0, loop1 


    check_carry:
        
        // if (ulCarry != 1) goto set_length;
        bcc     set_length

        // if (lSumLength == MAX_DIGITS) return FALSE;
        cmp     LSUMLENGTH_VAR, MAX_DIGITS
        beq     return_false

        // oSum->aulDigits[lSumLength] = 1;
        mov     x1, OSUM_VAR
        add     x1, x1, DIGITS_OFFSET
        mov     x0, LSUMLENGTH_VAR
        lsl     x0, x0, ULSize
        add     x1, x1, x0
        mov     x0, 1
        str     x0, [x1]

        // lSumLength++;
        add     LSUMLENGTH_VAR, LSUMLENGTH_VAR, 1
        

    set_length:

        // oSum->lLength = lSumLength;
        mov     x1, OSUM_VAR
        mov     x0, LSUMLENGTH_VAR
        str     x0, [x1, LLENGTH]
        mov     x0, TRUE
        b       return

    return_false:

        // return FALSE
        mov    x0, FALSE

    return:

        // Epilogue
        ldr     x30, [sp]
        ldr     x19, [sp, OADDEND1]
        ldr     x20, [sp, OADDEND2]
        ldr     x21, [sp, OSUM]
        ldr     x22, [sp, LLENGTHONE]
        ldr     x23, [sp, LLENGTHTWO]
        ldr     x24, [sp, ULCARRY]
        ldr     x25, [sp, ULSUM]
        ldr     x26, [sp, LINDEX]
        ldr     x27, [sp, LSUMLENGTH]
        ldr     x28, [sp, LLARGER]
        add     sp, sp, BIGINTADD_STACK_BYTECOUNT
        ret

    .size   BigInt_add, (. - BigInt_add)
