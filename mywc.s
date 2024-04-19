    .section .data
lLineCount: .word 0
lWordCount: .word 0
lCharCount: .word 0
iInWord: .word FALSE

    .section .bss
iChar:  .skip 4



    .section .text
    .equ    MAIN_STACK_BYTECOUNT, 16


    .global main

main:

    // prologue 
    sub sp, sp, MAIN_STACK_BYTECOUNT
    str x30, [sp]
    adr x0, lLineCount
    ldr w1, [x0]
    adr x0, lWordCount
    ldr w2, [x0]
    adr x0, lCharCount
    ldr w3, [x0]
    adr x0, iInWord
    ldr w4, [x0]
    adr x0, iChar
    ldr w5, [x0]

    // loop1: if ((iChar = getchar()) == EOF) goto endloop1;
    cmp w5, 