    .section .rodata

    .section .data

    .section .bss

    .section .text

        .global BigInt_add
        .global BigInt_larger

        .equ TRUE, 1
        .equ FALSE, 0
        .equ OADDEND1, 48
        .equ OADDEND2, 56
        .equ OSUM, 64
        .equ ULCARRY, 80
        .equ ULSUM, 88
        .equ LINDEX, 96
        .equ LSUMLENGTH, 104
        .equ LLENGTH, 0
        .equ MAX_DIGITS, 32768
        .equ DIGITS_OFFSET, 8
        .equ ULSize, 3
        .equ MAIN_STACK_BYTECOUNT, 32



    BigInt_larger:

        // store variable lLarger in stack register x2
        sub sp, sp, #8
        str x2, [sp]
        ldr x3, [sp]

        cmp     x0, x1
        ble    else1
        mov     x3, x0
        b endif1

    else1:
        mov x3, x1
        
    endif1:
        mov x0, x3
        ret

    BigInt_add:

        // Prologue
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        stp     x29, x30, [sp]

        // Store parameters on the stack
        str     x0, [sp, OADDEND1]     // Store oAddend1
        str     x1, [sp, OADDEND2]     // Store oAddend2
        str     x2, [sp, OSUM]         // Store oSum


        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        ldr     x0, [sp, OADDEND1]
        ldr     x0, [x0, LLENGTH]
        ldr     x1, [sp, OADDEND2]
        ldr     x1, [x1, LLENGTH]
        bl      BigInt_larger
        str     x0, [sp, LSUMLENGTH]

        // if (!(oSum->lLength > lSumLength)) goto initialize;
        ldr     x0, [sp, OSUM]
        ldr     x1, [x0, LLENGTH]
        ldr     x2, [sp, LSUMLENGTH]
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
        str     x0, [sp, ULCARRY]

        // lIndex = 0;
        str     x0, [sp, LINDEX]

    loop1:

        // if (lIndex >= lSumLength) goto check_carry;
        ldr     x0, [sp, LINDEX]
        ldr     x1, [sp, LSUMLENGTH]
        cmp     x0, x1
        bge    check_carry


        // ulSum = ulCarry;
        ldr     x0, [sp, ULCARRY]
        str     x0, [sp, ULSUM]

        // ulCarry = 0;
        mov     x0, 0
        str     x0, [sp, ULCARRY]

        // ulSum += oAddend1->aulDigits[lIndex];
        ldr     x2, [sp, OADDEND1]
        add     x2, x2, DIGITS_OFFSET  // Pointer to the digits array
        ldr     x1, [sp, LINDEX]
        lsl     x1, x1, ULSize         // Multiply current index by size of (ul)
        add     x2, x2, x1
        ldr     x3, [x2]
        ldr     x2, [sp, ULSUM]
        add     x2, x2, x3
        str     x2, [sp, ULSUM]

        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto add_second; 
        cmp     x3, x2
        blt    add_second

        // ulCarry = 1;
        mov     x2, 1
        str     x2, [sp, ULCARRY]

    add_second:

        // ulSum += oAddend2->aulDigits[lIndex];
        ldr     x2, [sp, OADDEND2]
        add     x2, x2, DIGITS_OFFSET
        ldr     x1, [sp, LINDEX]
        lsl     x1, x1, ULSize
        add     x2, x2, x1
        ldr     x3, [x2]
        ldr     x2, [sp, ULSUM]
        add     x2, x2, x3
        str     x2, [sp, ULSUM]

        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto store_sum;
        cmp     x3, x2
        blo     store_sum

        // ulCarry = 1;
        mov     x2, 1
        str     x2, [sp, ULCARRY]

    store_sum:
        
        // oSum->aulDigits[lIndex] = ulSum;
        ldr     x1, [sp, OSUM]
        add     x1, x1, DIGITS_OFFSET  // pointer to the digits array
        ldr     x2, [sp, LINDEX]
        lsl     x2, x2, ULSize
        add     x1, x1, x2
        ldr     x2, [sp, ULSUM]
        str     x2, [x1]

        // lIndex++;
        ldr     x0, [sp, LINDEX]
        add     x0, x0, 1
        str     x0, [sp, LINDEX]
        b       loop1                  // restart loop


    check_carry:
        
        // if (ulCarry != 1) goto set_length;
        ldr     x0, [sp, ULCARRY]
        cmp     x0, 1
        bne     set_length

        // if (lSumLength == MAX_DIGITS) return FALSE;
        ldr     x0, [sp, LSUMLENGTH]
        cmp     x0, MAX_DIGITS
        beq     return_false

        // oSum->aulDigits[lSumLength] = 1;
        ldr     x1, [sp, OSUM]
        add     x1, x1, DIGITS_OFFSET
        ldr     x0, [sp, LSUMLENGTH]
        lsl     x0, x0, ULSize
        add     x1, x1, x0
        mov     x0, 1
        str     x0, [x1]

        // lSumLength++;
        ldr     x0, [sp, LSUMLENGTH]
        add     x0, x0, 1
        str     x0, [sp, LSUMLENGTH]

    set_length:

        // oSum->lLength = lSumLength;
        ldr     x1, [sp, OSUM]
        ldr     x0, [sp, LSUMLENGTH]
        str     x0, [x1, LLENGTH]
        mov     x0, TRUE
        b       return

    return_false:

        // return FALSE
        mov    x0, FALSE

    return:

        // Epilogue
        ldp     x29, x30, [sp]
        add     sp, sp, MAIN_STACK_BYTECOUNT
        ret

