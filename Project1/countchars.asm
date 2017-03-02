; --------------------------------------------------------------
; Name:             countchars.asm
; Executable:       countchars.out
; Created:          2/14/2017
; Last modified:    2/15/2017
; Author:           Kevin Rapa
; Class:            CMSC 313, Spring 2017, Ramsey Kraya
; Assembler:        NASM
; Description: 	    Counts the number of each type of character
;                   in a string supplied through standard input.
;                   ***Uses one system call per output string
;                   as the extra credit requested.
; --------------------------------------------------------------

%define STDIN 0
%define STDOUT 1
%define SYSCALL_READ 3
%define SYSCALL_WRITE 4
%define SYSCALL_EXIT 1
%define BUFFER_SIZE 256
%define MARKER '%'      ; Specifies where to insert the character count
%define ZERO 48         ; 48 is the ASCII code for zero

SECTION .data
    ;;; Unformatted messages to print out.
    promptMsg:      db "Text to be analyzed: "
    promptMsgLen:   equ $-promptMsg

    verifyMsg:      db "You entered: "
    verifyMsgLen:   equ $-verifyMsg

    alphaMsg:       db "There were ", MARKER," alphabetic characters. "
    alphaMsgLen:    equ $-alphaMsg

    digitMsg:       db "There were ", MARKER," numeric characters. ", 10
    digitMsgLen:    equ $-digitMsg

    otherMsg:       db "There were ", MARKER," other characters. ", 10
    otherMsgLen:    equ $-otherMsg

    ;;; Character counts of the three types. 48 is the ASCII code for zero
    alphaCt:        db ZERO
    digitCt:        db ZERO
    otherCt:        db ZERO

SECTION .bss
    buffer: resB BUFFER_SIZE    ; For holding the string
    strLen: resB 4              ; For holding the length of the string

SECTION .text
    global _start

;;; --------------------------------------------------------------
;;; Program start
;;; --------------------------------------------------------------
_start:	
    NOP	                    ; For debugger

    ;;; Prompts the user for input
    MOV eax, SYSCALL_WRITE  ; System call code: write
    MOV ebx, STDOUT         ; File descriptor: standard output 
    MOV ecx, promptMsg      ; Message to display
    MOV edx, promptMsgLen   ; Length of the message
    INT 80H                 ; Kernel call

    ;;; Recieves player input
    MOV eax, SYSCALL_READ	; System call code: read
    MOV ebx, STDIN          ; File descriptor: standard input
    MOV ecx, buffer         ; Buffer to hold the string
    MOV edx, BUFFER_SIZE    ; Size of the buffer
    INT 80H                 ; Interrupt service vector call
    MOV [strLen], eax       ; Save the size of the input

    ;;; Verifies what the player typed
    MOV eax, SYSCALL_WRITE
    MOV ebx, STDOUT
    MOV ecx, verifyMsg
    MOV edx, verifyMsgLen
    INT 80H

    MOV eax, SYSCALL_WRITE
    MOV ecx, buffer
    MOV edx, strLen
    INT 80H

    ;;; Moves needed information into the registers
    MOV esi, buffer         ; The input string address
    MOV ecx, [alphaCt]      ; The letter count address
    MOV edx, [otherCt]      ; The symbol count address
    MOV edi, [digitCt]      ; The digit count address
    MOV eax, [strLen]       ; The input tring length

;;; --------------------------------------------------------------
;;; This section begins counting the characters in the input string
;;; --------------------------------------------------------------
.loop:
    ;;; Steps up the string and makes a comparison at each
    CMP eax, 0              ; Check if at end of string
    JE  .processAlpha

    MOV bh, [esi]           ; Move a letter into bh register
    CMP bh, 32              ; Anything below this is ignored (Including newline)
    JL .nextChar            ; Continue loop if character is below 32

    ;;; Compares the value with ASCII values and jumps to respective routine
    ;;; Starts from the bottom and goes up the table
    CMP bh, 48
    JL  .isSymbol
    CMP bh, 58
    JL  .isDigit
    CMP bh, 65
    JL  .isSymbol
    CMP bh, 91
    JL  .isLetter
    CMP bh, 97
    JL  .isSymbol         
    CMP bh, 123
    JL  .isLetter
    CMP bh, 127
    JL  .isSymbol

    ;;; Next three labels increment the respective character type count
    .isLetter:
        INC ecx             ; Increments the value
        JMP .nextChar

    .isDigit:
        INC edi             ; Increments the value
        JMP .nextChar

    .isSymbol:
        INC edx             ; Increments the value
        JMP .nextChar

    .nextChar:
        ;;; Increments the address of buffer to point to next character
        INC esi             ; Increments the address of the character to look at
        DEC eax             ; Decrements the length of the input string
        JMP .loop

;;; --------------------------------------------------------------
;;; This section formats each final message, replacing '%' with the count
;;; --------------------------------------------------------------
.processAlpha:
    ;;; Moves all the character counts back to memory
    MOV [alphaCt], ecx
    MOV [digitCt], edi
    MOV [otherCt], edx

    ;;; Prints the final string and then goes to exit
    MOV ah,  [alphaCt]      ; How many alphabetic characters were spotted 
    MOV ebx, alphaMsg       ; The address of the final message
    MOV ch,  [ebx]          ; Move the first character of the string into ch
    MOV edx, 'a'            ; Marker that we're currently in the letter count
    JMP .formatLoop         ; Step up the string and switch '%' with the count

.processDigit:
    MOV ah,  [digitCt]
    MOV ebx, digitMsg
    MOV ch,  [ebx]
    MOV edx, 'd'            ; Marker that we're currently in the digit count
    JMP .formatLoop

.processOther:
    MOV ah,  [otherCt]
    MOV ebx, otherMsg
    MOV ch,  [ebx]
    MOV edx, 's'            ; Marker that we're currently in the symbol count
    JMP .formatLoop

.formatLoop:
    ;;; Moves up the output string until a percent is spotted
    CMP ch, MARKER          ; Checks if the current character = MARKER
    JE  .replacePercent

    ADD ebx, 1              ; Moves up the string array
    MOV ch, [ebx]           ; Moves next character into ch
    JMP .formatLoop         ; Continues the loop

.replacePercent:
    MOV [ebx], ah           ; Moves the count into the string

    CMP edx, 'a'            ; Look at the marker in edx
    JE .processDigit        ; Process the digit count string if its equal

    CMP edx, 'd'            ; Look at the marker in edx
    JE .processOther        ; Process the symbol count string if its equal

    ;;; Otherwise, go to .end

;;; --------------------------------------------------------------
;;; This section prints the final strings and ends the program
;;; --------------------------------------------------------------

.end:
    MOV ebx, STDOUT         ; File descriptor, standard output

    MOV eax, SYSCALL_WRITE
    MOV ecx, alphaMsg
    MOV edx, alphaMsgLen
    INT 80H

    MOV eax, SYSCALL_WRITE
    MOV ecx, digitMsg
    MOV edx, digitMsgLen
    INT 80H

    MOV eax, SYSCALL_WRITE
    MOV ecx, otherMsg
    MOV edx, otherMsgLen
    INT 80H

    MOV eax, SYSCALL_EXIT
    MOV ebx, 0
    INT 80H