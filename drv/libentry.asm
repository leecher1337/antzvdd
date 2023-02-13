PAGE,132

include cmacros.inc

externFP <GrabInterrupts>

createSeg INIT_TEXT, INIT_TEXT, BYTE, PUBLIC, CODE
sBegin	INIT_TEXT
assumes CS,INIT_TEXT

?PLM=0                           ; 'C'naming
;externA  <_acrtused>             ; ensures that Win DLL startup code is linked
public  __acrtused
		__acrtused = 1

?PLM=1                           ; 'PASCAL' naming

cProc   LibEntry, <PUBLIC,FAR>   ; entry point into DLL

include CONVDLL.INC

cBegin
        push    di               ; handle of the module instance
        push    ds               ; library data segment
        push    cx               ; heap size
        push    es               ; Always NULL
        push    si               ; Always NULL

	call	GrabInterrupts
	
	pop	si
        pop     es               
        pop     cx               
        pop     ds
        pop     di

exit:

cEnd

sEnd	INIT_TEXT

end LibEntry

