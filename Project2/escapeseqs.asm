; --------------------------------------------------------------
; Name:             escapeseqs.asm
; Executable:       escapeseqs.out
; Created:          2/27/2017
; Last modified:    3/2/2017
; Author:           Kevin Rapa
; Class:            CMSC 313, Spring 2017, Ramsey Kraya
; Assembler:        NASM
; Description: 	    Iterates through an input string and converts
;                   any escape sequences into their corresponding
;                   characters. Prints incorrect escapes as '\'
;                   along with an error message for each error type
; --------------------------------------------------------------

%define STDIN 0
%define STDOUT 1
%define SYSCALL_READ 3
%define SYSCALL_WRITE 4
%define SYSCALL_EXIT 1
%define BUFFER_SIZE 256     ; Max size the input message can be
%define NULL 0              ; The null character

%define LOOKUP [lookup + edx - 97]  ; For indexing the look-up table.

SECTION .data
    ;;; Unformatted messages to print out.
    promptMsg:      db "Enter String: "
    promptMsgLen:   equ $-promptMsg

    verifyMsg:      db 10, 10, "Original: "
    verifyMsgLen:   equ $-verifyMsg

    convertMsg:     db 10, "Convert: "
    convertMsgLen:  equ $-convertMsg

    errorOverflow:  db 10, "Error: octal value overflow in \"
    overflowLen:    equ $-errorOverflow

    errorUnknown:   db 10, "Error: unknown escape sequence \%"
    unknownLen:     equ $-errorUnknown

    errorEndEscape: db 10, "Error: escape at end of string"
    endEscapeLen:   equ $-errorEndEscape

    ;;; The lookup table for escape character values
                ;;  a   b   c   d   e   f   g   h   i   j   k   l   m 
    lookup:     db  7,  8, -1, -1, -1, 12, -1, -1, -1, -1, -1, -1, -1
                db 10, -1, -1, -1, 13, -1,  9, -1, 11, -1, -1, -1, -1
                ;;  n   o   p   q   r   s   t   u   v   w   x   y   z
SECTION .bss
    inputBuffer: resb BUFFER_SIZE    ; For holding the string
    outputBuffer: resb BUFFER_SIZE   ; For writing the output string.

    ; Copy octal values encountered to this in case of octal overflow
    overflowCopy: resb 4 

    inputLen: resb 4                 ; For holding the string length

SECTION .text
    global _start

;;; --------------------------------------------------------------
;;; Program start: Prompt for and verify input
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
    MOV ecx, inputBuffer    ; Buffer to hold the string
    MOV edx, BUFFER_SIZE    ; Size of the buffer
    INT 80H                 ; Interrupt service vector call

    MOV [ecx + eax - 1], byte NULL   ; Null terminates the string
    MOV [inputLen], eax     ; Save the size of the input

    ;;; Prepares for main loop
    MOV esi, inputBuffer    ; Move the input string address into esi
    MOV ebx, outputBuffer   ; Move the output string address into ebx

;;; --------------------------------------------------------------    
;;; Iterates through the string, parsing escapes when encountered
;;; --------------------------------------------------------------
.mainloop:
    MOV  ah, [esi]      ; move the byte ESI points to into AH
    CMP  ah, NULL       ; Compare the character in AH to null 
    JE   .end           ; Jump to the end if it's null
    INC  esi            ; Have ESI point to the next character
    CMP  ah, '\'        ; Check if it's a backslash
    JNE  .writechar     ; Write the character if it isn't
    CALL .handle_ESC    ; Figure out what the escape character is

;;; --------------------------------------------------------------    
;;; Writes a character into the output buffer, increments index
;;; into output buffer.
;;; Parameters: EAX <- next character to be written
;;;             EBX <- the address to write the character
;;; Returns:    Nothing
;;; --------------------------------------------------------------
.writechar:
    MOV [ebx], ah   ; Copy the character in AH to the output
    INC ebx         ; Increment the address to write characters
    JMP .mainloop   ; Go back and process the next character

;;; --------------------------------------------------------------
;;; Sub-routine that parses an escape sequence and converts it
;;; Parameters: ESI <- address of the next byte to be read
;;; Returns:    AH  <- Next character to be written 
;;; ***Incorrect escape sequences are printed as '\'
;;; --------------------------------------------------------------
.handle_ESC:
    ;;; A '\' is in AH right now. We'll leave it there assuming an
    ;;; error will occur and change it if necessary.

    MOV dl, [esi]       ; Move the character into DL      

    CMP dl, NULL        ; Test if it's null
    JE .escapeAtEndErr  ; Print error and end the program

    INC esi             ; Move up one from the character analyzed

    CMP dl, 48          ; Anything below 48 isn't legal
    JL  .unknownEscErr  ; Print out an error

    CMP dl, 56          ; Check if it's '0'-'7'
    JL  .isOctal        ; Parse the octal value

    CMP dl, '\'         ; Check if a backslash character
    JE .end_esc         ; End if it's a backslash

    CMP dl, 97          ; Anything below 97 isn't legal if we've
    JL .unknownEscErr   ; made it this far. End

    CMP dl, 123         ; Check if it's a lowercase letter
    JL .isLowerCase

    .end_esc:
        RET             ; Returns back to the end of main loop

    ;;; ----------------------------------------------------------
    ;;; Three subroutines here process error messages for bad
    ;;; escapes: One for an incorrect escape, one for an octal
    ;;; overflow, and one for an escape at the end of input.
    ;;; ----------------------------------------------------------
    .unknownEscErr:
        ; Place bad escape character at end
        MOV [errorUnknown + unknownLen - 1], dl 

        PUSHAD      ; Save all the registers

        MOV eax, SYSCALL_WRITE
        MOV ebx, STDOUT
        MOV ecx, errorUnknown   ; Error message for unknown escape
        MOV edx, unknownLen
        INT 80H 

        POPAD
        JMP .end_esc

    .escapeAtEndErr:
        PUSHAD                  ; Save all the registers

        MOV eax, SYSCALL_WRITE  
        MOV ebx, STDOUT
        MOV ecx, errorEndEscape ; Error message for escape at end
        MOV edx, endEscapeLen 
        INT 80H        

        POPAD                   ; Restore all the registers
        JMP .end_esc

    .overflowErr:
        PUSHAD

        MOV eax, SYSCALL_WRITE
        MOV ebx, STDOUT  
        MOV ecx, errorOverflow  ; Error message for escape at end
        MOV edx, overflowLen 
        INT 80H   

        MOV eax, SYSCALL_WRITE
        MOV ecx, overflowCopy   ; The incorrect octal value
        MOV edx, 4              ; Length of the copy buffer 
        INT 80H  

        POPAD                   ; Restore all the registers
        JMP .pop_return         ; Go back to the nested subroutine
                                    ; inside .isOctal to pop EBX

    ;;; ----------------------------------------------------------
    ;;; These two subroutines are only for use inside of handle_ESC.
    ;;; These handle the cases in which the escaped character is
    ;;; octal or a lowercase letter.
    ;;; ----------------------------------------------------------
    .isLowerCase:
        AND edx, 0FFh       ; Clear all but lower-order 8-bits of edx
        MOV dh, LOOKUP      ; Get escape character value from table
        CMP dh, -1          ; Check if the entry equals -1
        JE  .unknownEscErr  ; If it does, print error message                                  
        MOV ah, dh          ; Otherwise it's a legal escape value
        JMP .end_esc

    .isOctal:
        PUSH ebx        ; Save whatever is in ebx. Need it for val
        XOR  bx, bx     ; Clear BX to hold running total (val = 0)
        XOR  ecx, ecx   ; Clear ECX for loop count
        MOV  ecx, 3     ; Start count (octal is max three digits)
        MOV  ebp, overflowCopy   ; Address to copy octal characters
        MOV  [ebp], dword 0      ; clear the copy space

        ;;; ------------------------------------------------------
        ;;; The next three subroutines are only used by .isOctal 
        ;;; .parseLoop - processes a variable amount of characters
        ;;; .done - finishes .isOctal subroutine
        ;;; .pop_return - gets saved EBX value back into EBX, returns
        ;;; ------------------------------------------------------
        .parseLoop:
            MOV [ebp], dl   ; Mov the character into copy
            SUB dl, 48      ; Convert character into a digit
            SHL bx, 3       ; Multiply BX by 8 (val = val * 8)
            ADD bl, dl      ; Add the octal digit to the value

            MOV dl, [esi]   ; Pre-fetch the next character
            INC esi         ; Increment ESI

            CMP dl, 48      ; Check if the next character is too low
            JB .done        ; Break if it is
            CMP dl, 55      ; Check if the next character is too high
            JA .done        ; Break if it is       

            INC ebp         ; Move index in octal copy buffer up
            LOOP .parseLoop ; Decrement ECX and loop if not zero yet
    
        .done:
            DEC esi         ; Step back esi (avoids reading too far)
            CMP bx, 255     ; Check if the octal value is too high
            JA .overflowErr ; Value is too high. Print error and return
            MOV ah, bl      ; BL is where our octal value is

        .pop_return:
            POP ebx         ; Put ebx value we saved back into ebx
            RET             ; Return to mainLoop to write character

;;; --------------------------------------------------------------
;;; This section prints the final string and ends the program
;;; --------------------------------------------------------------
.end:
    MOV [ebx], byte 10      ; Terminate the new string with a newline
                            ; Makes output look a bit nicer

    ;;; Verifies what the player typed
    MOV eax, SYSCALL_WRITE
    MOV ebx, STDOUT
    MOV ecx, verifyMsg      ; The message 'Original: '
    MOV edx, verifyMsgLen
    INT 80H

    MOV eax, SYSCALL_WRITE
    MOV ecx, inputBuffer    ; The input message
    MOV edx, [inputLen]
    INT 80H

    MOV eax, SYSCALL_WRITE  ; Write the new message
    MOV ecx, convertMsg
    MOV edx, convertMsgLen
    INT 80H

    MOV eax, SYSCALL_WRITE
    MOV ecx, outputBuffer
    MOV edx, [inputLen]
    INT 80H

    MOV eax, SYSCALL_EXIT   ; Exit cleanly
    MOV ebx, 0
    INT 80H