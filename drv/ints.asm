include isvbop.inc

.286
.model medium,pascal

_DATA segment word public 'DATA'

Old2fHandler    dd      ?
VddHandle       dw      -1

DllName         db      "VNTD.DLL",0
InitFunc        db      "VDDInitialize",0
DispFunc        db      "PM_0",0

_DATA ends

INIT_TEXT segment byte public 'CODE'

        assume  cs:INIT_TEXT

GrabInterrupts proc far
        pusha
        push    ds
        push    es
        push    _DATA
        pop     ds
        assume  ds:_DATA
        push    ds
        pop     es
        mov     si,offset DllName       ; ds:si = library name
        mov     di,offset InitFunc      ; es:di = init function name
        mov     bx,offset DispFunc      ; ds:bx = dispatcher function name
        RegisterModule                  ; returns carry if problem
        jc      @f
        mov     VddHandle,ax
        mov     ax,352fh
        int     21h
        mov     word ptr Old2fHandler,bx
        mov     word ptr Old2fHandler+2,es
        push    seg PmVntd2fHandler
        pop     ds
        assume  ds:nothing
        mov     dx,offset PmVntd2fHandler
        mov     ax,252fh
        int     21h
@@:     pop     es
        pop     ds
        popa
        ret
GrabInterrupts endp

INIT_TEXT ends

_TEXT segment byte public 'CODE'

        assume  cs:_TEXT

        public  PmVntd2fHandler
PmVntd2fHandler proc
        cmp     ax,1684h
        jne     @f
        cmp     bx,6ed8h
        jne     @f
        push    cs
        pop     es
        mov     di,offset PmVntdEntryPoint
        iret
@@:     push    bp
        mov     bp,sp
        push    ax
        push    ds
        mov     ax,_DATA
        mov     ds,ax
        assume  ds:_DATA
        push    word ptr Old2fHandler+2
        push    word ptr Old2fHandler
        mov     ds,[bp-4]
        mov     ax,[bp-2]
        mov     bp,[bp]
        retf    6
PmVntd2fHandler endp


        public PmVntdEntryPoint
PmVntdEntryPoint proc
        push    bp
        push    ds
        push    _DATA
        pop     ds
        assume  ds:_DATA
        mov     bp,ax
        mov     ax,VddHandle
        pop     ds
        assume  ds:nothing
        DispatchCall
        pop     bp
        ret
PmVntdEntryPoint endp

_TEXT ends

end
