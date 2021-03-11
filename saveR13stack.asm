; saveR13stack forked from zapR13crash
; Author: Pieter van Tuijl
https://github.com/pietert2000

; Demonstrates implementation of stack as we have nested function calls.
; If no stack would be implemented, the return address in R13 would be overwritten
; everytime we call another function from within a function.

; There are several functions.  They all take one argument x which is
; passed in R1, and return one result f(x) which is also passed back
; in R1.  Each function multiplies x by a constant.  Some of the
; functions (double, triple, quadruple) do the work by themselves, but
; one of them (mult6) calculates 6*x by evaluating triple(double(x)).
; In case of the latter function, we need the stack to store a copy of the 
; return address of the caller as well as register values and local variables

; Process of stack implementation
;   1. Allocate memory in static memory
;   2. Create stack pointer (points to latest stackframe) in R14
;   3. Just before calling a function, advance to new frame
;   4. Inside callee, save return address to current frame at index 0
;   5. Just before returning, restore R13 to address of caller
;   6. Move stack pointer back by stack_size (1 in this program)

MainProgram

; Since mult6 calls another functions, we need the stack here
; to prevent R13 from being overwritten
    lea    R14,CallStack[R0]  ; R14 = &stack (stack pointer)
    store  R0,0[R14]          ; Initialize empty stack

; Call Double function with stack 
    lea    R1,2[R0]           ; R1 = argument := 2
    lea    R14,1[R14]         ; Advance stack pointer to new frame
    jal    R13,double[R0]     ; R1 := double(R1) = 2*2 = 4
; Call Triple function with stack 
    lea    R14,1[R14]         ; Advance stack pointer to new frame
    jal    R13,triple[R0]     ; R1 := triple(R1) = 3*4 = 12
; We don't use stack here, as quadruple doesn't call any other functions
    jal    R13,quadruple[R0]  ; R1 := quadruple(R1) = 4*12 = 48
    store  R1,result1[R0]     ; result1 := 4*(3*((2*2)) = 48
; Call mult6 with stack 
    lea    R1,2[R0]           ; R1 = x = 2
    lea    R14,1[R14]         ; Advance stack pointer to new frame
    jal    R13,mult6[R0]      ; R1 = triple(double(x)) = 3*(2*x)
; Store return value
    store  R1,result2[R0]     ; result2 := 6*2 = 12

    trap   R0,R0,R0           ; terminate main program

double
; receive argument x in R1
; return result in R1 = 2*x
    store  R13,0[R14]         ; Store return address of caller on top of stack

    lea    R2,2[R0]
    mul    R1,R2,R1           ; R1 := 2*x

    load   R13,0[R14]         ; restore return address of caller from top of stack
    lea    R2,1[R0]           ; R2 = stack size = 1
    sub    R14,R14,R2         ; Move stack pointer back by 1
    jump   0[R13]             ; return R1 = 2*x

triple
; receive argument x in R1
; return result in R1 = 3*x
    store  R13,0[R14]         ; Store return address of caller on top of stack

    lea    R2,3[R0]
    mul    R1,R2,R1           ; R1 := 3*x

    load   R13,0[R14]         ; restore return address of caller from top of stack
    lea    R2,1[R0]           ; for sake of completeness, as R2 actually hasn't changed
    sub    R14,R14,R2         ; Move stack pointer back by 1
    jump   0[R13]             ; return R1 = 3*x

quadruple
; receive argument x in R1
; return result in R1 = 4*x
    lea    R2,4[R0]
    mul    R1,R2,R1           ; R1 := 4*x
    jump   0[R13]             ; return R1 = 4*x

mult6
; argument and return result are in R1
    store   R13,0[R14]        ; Store caller return address to index 0 of current stackframe

    lea    R14,1[R14]         ; Advance stackpointer to new frame
    jal    R13,double[R0]     ; R1 := double(x) = 2*x
    lea    R14,1[R14]         ; Advance stackpointer to new frame
    jal    R13,triple[R0]     ; R1 : triple(2*x) = 3*(2*x)

  ; Time to restore to latest stackframe
    load   R13,0[R14]         ; Restore return address from top of stack
    lea    R2,1[R0]           ; R2 := stackframe size
    sub    R14,R14,R2         ; remove top frame from stack
    jump   0[R13]             ; return to caller, R1 = 3*(2*x)

; Static variables

result1   data  0            ; result of first sequence of calls
result2   data  0            ; result of the mult6 call
CallStack data  0            ; Stack grows beyond this point
