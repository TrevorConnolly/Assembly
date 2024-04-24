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

        
        .equ LLENGTH, 0
        .equ MAX_DIGITS, 32768
        .equ DIGITS_OFFSET, 8
        .equ ULSHIFT, 3
        .equ BIGINTADD_STACK_BYTECOUNT, 64
        .equ LARGER_BYTECOUNT, 32
        .equ LLENGTHONE, 8
        .equ LLENGTHTWO, 16
        .equ LLARGER, 24



BigInt_larger:

        // store variable lLarger in stack register x2
        // Prologue
        sub sp, sp, LARGER_BYTECOUNT

        // long lLarger;
        str     x0, [sp, LLENGTHONE]
        str     x1, [sp, LLENGTHTWO]
        str     x30, [sp]

        // if (lLength1 > lLength2) goto else1;
        cmp     x0, x1
        bgt    else1
        // lLarger = lLength2;
        str     x1, [sp, LLARGER]

        b endif1

    else1:
        str     x0, [sp, LLARGER]
        
    endif1:
        // return lLarger;
        ldr     x0, [sp, LLARGER]
        // Epilogue
        ldr     x30, [sp]
        add     sp, sp, LARGER_BYTECOUNT
        ret

    .size   BigInt_larger, (. - BigInt_larger)

    BigInt_add:

        // Prologue
        sub     sp, sp, BIGINTADD_STACK_BYTECOUNT
        str     x30, [sp]

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
        lsl     x2, x2, ULSHIFT        // MAX_DIGITS * sizeof(unsigned long)
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
        bge     check_carry


        // ulSum = ulCarry;
        ldr     x0, [sp, ULCARRY]
        str     x0, [sp, ULSUM]

        // ulCarry = 0;
        mov     x0, 0
        str     x0, [sp, ULCARRY]

        // ulSum += oAddend1->aulDigits[lIndex];
        ldr     x1, [sp, OADDEND1]
        add     x1, x1, DIGITS_OFFSET  // Pointer to the digits array
        ldr     x2, [sp, LINDEX]
        lsl     x2, x2, ULSHIFT         // Multiply current index by size of (ul)
        add     x1, x1, x2
        ldr     x2, [x1]
        ldr     x1, [sp, ULSUM]
        add     x1, x1, x2
        str     x1, [sp, ULSUM]


        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto add_second; 
        ldr     x3, [sp, ULSUM]
        cmp     x3, x2
        bhs     add_second

        // ulCarry = 1;
        mov     x0, 1
        str     x0, [sp, ULCARRY]

    add_second:

        // ulSum += oAddend2->aulDigits[lIndex];

        ldr     x1, [sp, OADDEND2]
        add     x1, x1, DIGITS_OFFSET  // Pointer to the digits array
        ldr     x2, [sp, LINDEX]
        lsl     x2, x2, ULSHIFT        // Multiply current index by size of (ul)
        add     x1, x1, x2
        ldr     x2, [x1]
        ldr     x1, [sp, ULSUM]
        add     x1, x1, x2
        str     x1, [sp, ULSUM]

        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto store_sum;
        ldr     x3, [sp, ULSUM]
        cmp     x3, x2
        bhs     store_sum

        // ulCarry = 1;
        mov     x0, 1
        str     x0, [sp, ULCARRY]

    store_sum:
        
        // oSum->aulDigits[lIndex] = ulSum;
        ldr     x1, [sp, OSUM]
        add     x1, x1, DIGITS_OFFSET  // pointer to the digits array
        ldr     x2, [sp, LINDEX]
        lsl     x2, x2, ULSHIFT
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
        lsl     x0, x0, ULSHIFT
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
        ldr     x30, [sp]
        add     sp, sp, BIGINTADD_STACK_BYTECOUNT
        ret

    .size   BigInt_add, (. - BigInt_add)
    