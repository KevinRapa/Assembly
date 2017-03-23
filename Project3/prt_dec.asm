; --------------------------------------------------------------
; Name:             prt_dec.asm
; Executable:       prt_dec.out
; Created:          3/23/2017
; Last modified:    3/23/2017
; Author:           Kevin Rapa
; Class:            CMSC 313, Spring 2017, Ramsey Kraya
; Assembler:        NASM
; Description: 	    Subrouting which takes a 32 bit number on
;                   stack passed as an argument and prints it
;                   to standard output.
; --------------------------------------------------------------

%define STDOUT 1
%define SYSCALL_WRITE 4
%define MAX_LEN	10			; 32 bit value can't be >10 digits

SECTION .data
	charMod: db 48			; For converting digit to char

SECTION .bss
	strBuf: resb MAX_LEN	; Holds the string to print
	retBuf: resb 4			; holds the return address
	argBuf: resb 4			; holds the 32-bit argument

SECTION .text
	global prt_dec

;;;-------------------------------------------------------------
;;; Beginning of the subroutine

prt_dec:
	;; Saves data
	POP dword [retBuf]		; Save the return address
	POP dword [argBuf]  	; Save the argument
	PUSHAD					; Save all the registers

	;; Prepares registers for the loop.
	XOR ecx, ecx 			; Clear ECX for the count
	MOV eax, [argBuf] 		; Moves the argument into EAX
	MOV ebx, dword 10		; Moves divisor into EBX

;;;-------------------------------------------------------------
;;; Loops, performing division method and pushing the remainder
;;; onto the stack. Keeps going until quotient is zero.
;;; Counts the number of digits with ECX. By using the stack, we
;;; don't have to fill the string buffer backwards.

.divLoop:
	XOR  edx, edx	; Clear edx
	DIV  ebx 		; Divide the number by 10
	PUSH edx 		; Push remainder onto stack
	INC  ecx 		; Count number of times we've done this
	CMP  eax, 0 	; Check if quotient is 0
	JNZ  .divLoop 	; We aren't done if quotient isn't zero
	
;;;-------------------------------------------------------------
;;; Pops 32-bit integers (which were the remainders), converts
;;; each to a character and moves it into the buffer. Keeps going
;;; until ECX is zero (Number of characters to process is in ECX).
;;; Uses EAX to index since EAX is already zero 

.popLoop: 
	POP ebx 				; Pop a remainder into ebx
	ADD bl, [charMod] 		; Convert to char
	MOV [strBuf + eax], bl 	; Move the character into string
	INC eax 				; Increment index
	LOOP .popLoop 			; If ECX isn't zero, still more

;;;-------------------------------------------------------------
;;; Print the final value to standard output

	MOV eax, SYSCALL_WRITE
    MOV ebx, STDOUT
    MOV ecx, strBuf		
    MOV edx, dword MAX_LEN	
    INT 80H	

;;;-------------------------------------------------------------
;;; Clear strBuf for subsequent calls. Clears from TOP

	MOV ecx, edx				; Starts from top (10)
	XOR ah, ah 					; To clear bytes in strBuf
.clearStrBufLoop:
	MOV [strBuf + ecx - 1], ah  ; Clear a byte in strBuf
	LOOP .clearStrBufLoop 		; Repeat if not done

;;;------------------------------------------------------------
;;; Restore saved values

	POPAD 					; Restore all registers
	PUSH dword [retBuf]		; Restore return address
	RET 					; Return