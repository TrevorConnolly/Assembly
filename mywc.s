        .section .rodata
    printfFormatStr:
            .string "%7ld %7ld %7ld\n"

        .section .data
    lLineCount: .quad 0
    lWordCount: .quad 0
    lCharCount: .quad 0
    iInWord: .word 0

        .section .bss
    iChar:  .skip 4

        .section .text
        .equ    MAIN_STACK_BYTECOUNT, 16

        .global main

    main:

        // prologue 
        sub sp, sp, MAIN_STACK_BYTECOUNT
        str x30, [sp]

        adr x19, lLineCount
        ldr w20, [x19]

        adr x21, lWordCount
        ldr w22, [x21]

        adr x23, lCharCount
        ldr w24, [x23]

        adr x25, iInWord
        ldr w26, [x25]

    // Initialize x28 to point to iChar
        adr x28, iChar

        // loop1: if ((iChar = getchar()) == EOF) goto endloop1;
    loop1:

        bl getchar // Call getChar
        mov w5, w0 // Store return value of function
        cmp w0, -1 // Compare with end of file
        beq endloop1
        str w0, [x28] // Character read is stored iChar

        // lCharCount++;
        add w24, w24, #1 // Increment lCharCount
        str w24, [x23] // Store updated iCharCount

        // if (!(isspace(iChar))) goto else1;
        bl isspace // Compare to whitespace
        cmp w0, 0
        beq else1

        // if (!(iInWord)) goto endif2;
        ldr w26, [x25] // Load up most recent iInWord
        cmp w26, 0
        beq endif2 // IF not in word, skip word count increase
        
        // lWordCount++;
        add w22, w22, 1 // Increment lWordCount

        // iInWord = FALSE;
        mov w26, 0 // No longer in word
        str w22, [x21] // store updated word count
        str w26, [x25] // store status of iInWord


    endif2:

        // goto endif1;
        b endif1


    else1:
        
        //  if (iInWord) goto endif1;
        ldr w26, [x25]
        cmp w26, 1
        beq endif1

        // iInWord = TRUE;
        mov w26, 1
        str w26, [x25]

    endif1:
    
        // if (iChar != '\n') goto endif3;
        ldr w5, [x28] 
        cmp w5, 0x0A // compare to newline char
        bne loop1

        // lLineCount++;
        add w20, w20, 1
        str w20, [x19]

        b loop1 // restart loop

    endloop1:
        
        // if (! iInWord) goto endif4/ print_results;
        ldr w26, [x25]
        cmp w26, 0
        beq print_results
        
        // lWordCount++;
        ldr w22, [x21]
        add w22, w22, 1
        str w22, [x21]

    print_results:

        // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        adr x0, printfFormatStr

        adr x19, lLineCount
        ldr x1, [x19]  // Load the 64-bit value of lLineCount into x1

        adr x21, lWordCount
        ldr x2, [x21]  // Load the 64-bit value of lWordCount into x2

        adr x23, lCharCount
        ldr x3, [x23]  // Load the 64-bit value of lCharCount into x3

        bl printf


        // Epilog and return 0
        mov     w0, 0
        ldr     x30, [sp]
        add     sp, sp, MAIN_STACK_BYTECOUNT
        ret


