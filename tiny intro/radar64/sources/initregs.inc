; Initial register values on program start
		xor	ax,ax			; cf=0
		mov	bx,ax
		mov	cx,0FFh
		mov	dx,cs
		mov	si,100h
		mov	di,sp
		mov	bp,91Ch			; maybe 912h or 91Eh (or...?)
		cld
