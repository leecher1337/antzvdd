.MODEL tiny, pascal, os_dos
.STACK
.CODE
.STARTUP
        jmp     Install                 ; Jump over data and resident code

;
; DOS include files
;
        
include isvbop.inc      ; NTVDM BOP mechanism

Old2FHandler    dd      ?
VddHandle       dw      ?

; ***   VntdEntryPoint
; *
; *     The INT 2Fh handler that recognizes the Vntd-Request
; *
; *     ENTRY   AX = 1684h, BX = 6ED8h
; *
; *     EXIT    AL = 0FFh
; *             ES:DI = address of routine to call when submitting Vntd
; *                     requests
; *
; *     USES
; *
; *     ASSUMES nothing
; *
; ***

VntdEntryPoint proc
        cmp     ax,1600h
        jne     not_verchk
        mov     ax,0A04h
        iret
not_verchk:
        cmp     ax,1684h
        jne     @f
        cmp     bx,6ed8h
        jne     @f
        push    cs
        pop     es
        mov     di,offset RmVntdDispatcher
        iret
@@:     jmp     cs:Old2FHandler            ; chain int 2F
VntdEntryPoint endp


; ***   RmVntdDispatcher
; *
; *     Performs the dispatch
; *
; *     This routine just transfers control to 32-bit world, where all work is
; *     done
; *
; *     ENTRY   DI = dispatch code
; *             others - depends on function
; *
; *     EXIT    depends on function
; *
; *     USES    depends on function
; *
; *     ASSUMES 1. Dispatch codes are in range 0..7
; *
; ***

RmVntdDispatcher proc
        push    bp

;
; some APIs pass a parameter in AX. Since AX is being used for the VDD
; handle, we have to commandeer another register to hold our AX value. BP is
; always a good candidate
;

        mov     bp,ax                   ; grumble, mutter, gnash, gnash

        mov     ax,cs:VddHandle
        DispatchCall

@@:     pop     bp
        retf

RmVntdDispatcher endp


Install PROC

major_version	    equ     5	    ;Major DOS version
minor_version	    equ     00	    ;Minor DOS Version for int 21h/30h
minor_version_NT    equ     50	    ;Minor DOS VersionN for int 21h/3306


;
; when we start up we could be on any old PC - even an original, so don't
; assume anything other than a model-T processor
;

        .8086

;
; first off, get the DOS version. If we're not running on NT (VDM) then this
; TSR's not going to do much, so exit. Exit using various methods, depending
; on the DOS version (don't you hate compatibility?)
;

        mov     ah,30h
        int     21h
        jc      ancient_version         ; version not even supported

;
; version is 2.0 or higher. Check it out. al = major#, ah = minor#
;

        cmp     al,major_version
        jne     invalid_version

;
; okay, we're at least 5.0. But are we NT?
;

        mov     ax,3306h
        int     21h
        jc      invalid_version         ; ?
        cmp     bl,5
        jne     invalid_version
        cmp     bh,50
        jne     invalid_version

;
; what do you know? We're actually running on NT (unless some evil programmer
; has pinched int 21h/30h and broken it!). Enable minimum instruction set
; for NTVDM (286 on RISC).
;

        .286c

;
; perform an installation check. Bail if we're there dude ((C) Beavis & Butthead)
;

        call    InstallationCheck
        jnz     already_here            ; nope - VNTD support installed already

;
; We should find some way of deferring loading the 32-bit DLL until a
; function is called, to speed-up loading. However, if we later find we
; cannot load the DLL, it may be too late: there is no way of consistently
; returning an error and we cannot unload the TSR
;

        call    InstallVdd              ; returns IRQ in BX
        jc      initialization_error
        call    InstallInterruptHandlers

;
; free the environment segment
;

        mov     es,es:[02Ch]
        mov     ah,49h
        int     21h                     ; free environment segment
;
; finally terminate and stay resident
;

        mov     dx,OFFSET Install       ; DX = bytes in resident section
        mov     cl,4
        shr     dx,cl                   ; Convert to number of paragraphs
        inc     dx                      ;  plus one
        mov     ax,3100h
        int     21h                     ; terminate and stay resident

;
; here if the MS-DOS version check (Ah=30h) call is not supported
;

ancient_version:
        mov     dx,offset bad_ver_msg
        mov     ah,9                    ; cp/m-style write to output
        int     21h

;
; safe exit: what we really want to do here is INT 20H, but when you do this,
; CS must be the segment of the PSP of this program. Knowing that CD 20 is
; embedded at the start of the PSP, the most foolproof way of doing this is
; to jump (using far return) to the start of the PSP
;

        push    es
        xor     ax,ax
        push    ax
        retf                            ; terminate

;
; we are running on a version of DOS >= 2.00, but its not NT, so we still can't
; help. Display the familiar message and exit, but using a less programmer-
; hostile mechanism
;

invalid_version:
        mov     dx,offset bad_ver_msg
        mov     cx,BAD_VER_MSG_LEN
        jmp     short print_error_message_and_exit

;
; if we cannot initialize 32-bit support (because we can't find/load the DLL)
; then put back the hooked interrupt vectors as they were when this TSR started,
; display a message and fail to load the redir TSR
;

initialization_error:
        mov     dx,offset cannot_load_msg
        mov     cx,CANNOT_LOAD_MSG_LEN
        jmp     short print_error_message_and_exit

;
; The DOS version's OK, but this TSR is already loaded
;

already_here:
        mov     dx,offset already_loaded_msg
        mov     cx,ALREADY_LOADED_MSG_LEN

print_error_message_and_exit:
        mov     bx,1                    ; bx = stdout handle
        mov     ah,40h                  ; write to handle
        int     21h                     ; write (cx) bytes @ (ds:dx) to stdout
        mov     ax,4c01h                ; terminate program
        int     21h                     ; au revoir, cruel environment

Install ENDP

; ***   InstallationCheck
; *
; *     Test to see if this module is already loaded
; *
; *     ENTRY   nothing
; *
; *     EXIT    ZF = 0: loaded
; *
; *     USES    AX
; *
; *     ASSUMES nothing
; *
; ***

InstallationCheck proc
        push    es
        mov     ax,1684h
        mov     bx,6ed8h
        xor     di, di
        int     2fh
        or      di,di
        pop     es
        ret
InstallationCheck endp

; ***   InstallVdd
; *
; *     Load VNTD.DLL into the NTVDM process context
; *
; *     ENTRY   nothing
; *
; *     EXIT    CF = 1: error
; *             CF = 0: VNTD loaded ok
; *                     AX = VDD handle
; *                     ResidentCode:VddHandle updated
; *
; *     USES    AX, BX, SI, DI
; *
; *     ASSUMES nothing
; *
; ***

InstallVdd proc
        push    es
        push    ds
        pop     es
        mov     si,offset DllName       ; ds:si = library name
        mov     di,offset InitFunc      ; es:di = init function name
        mov     bx,offset DispFunc      ; ds:bx = dispatcher function name

        RegisterModule                  ; returns carry if problem

        mov     VddHandle,ax
        pop     es

        ret
InstallVdd endp

; ***   InstallInterruptHandlers
; *
; *     Sets the interrupt handlers for all the ints we use - 2F
; *
; *     ENTRY   ES = PSP segment
; *
; *     EXIT    Old2FHandler contains the original interrupt 2F vector
; *             Old7AHandler contains the original interrupt 7A vector
; *             OldIrqHandler contains original IRQ vector
; *
; *     USES    AX, BX, CX, DX
; *
; *     ASSUMES nothing
; *
; ***

InstallInterruptHandlers proc
;
; get and set 2F handler
;

        push    es
        mov     ax,352Fh
        int     21h
        mov     word ptr Old2FHandler,bx
        mov     word ptr Old2FHandler+2,es
        mov     dx,offset VntdEntryPoint
        mov     ax,252Fh
        int     21h
        pop     es

        ret
InstallInterruptHandlers endp

bad_ver_msg             db      'Bad DOS version',13,10
BAD_VER_MSG_LEN         equ     $-bad_ver_msg
                        db      '$'     ; for INT 21/09 display string

already_loaded_msg      db      'Driver already loaded',13,10
ALREADY_LOADED_MSG_LEN  equ     $-already_loaded_msg

cannot_load_msg         db      'cannot load driver',13, 10
CANNOT_LOAD_MSG_LEN     equ     $-cannot_load_msg

;
; strings used to load/dispatch VNTD.DLL
;

DllName         db      "VNTD.DLL",0
InitFunc        db      "VDDInitialize",0
DispFunc        db      "V86_0",0

END
