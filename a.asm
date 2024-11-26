.model small
.186
.stack 100h
.data
    file       db    'overflow.txt', 0
    string     db    "0000|0000|0000", 0dh, 0ah
    c          db    ?
    b          db    ?
    a          db    ?
    d          dw    ?

.code
Start:
        mov    ax, @data                  
	mov    ds, ax  
   	mov    es, ax
    	mov    cx, word ptr [c] ; cl = c, ch = b
    	mov    bh, a            ; bh = a
    	or    cl, cl     ; is c zero?
    	jz    cycles     ; jump to cycles
    	or    ch, ch     ; is b zero?
    	jz    cycles     ; jump to cycles
    	or    bh, bh     ; is a zero?
    	jnz    program   ; jump to equation     

cycles:
    mov    dx, offset file      ; dx point to file offset
    mov    di, offset string    ; di point to string offset
    mov    ah, 03Ch        ; create file   function          
    xor    cx, cx          ; normal file               
    int    21h             ; call dos 
    mov    bx, ax          ; save descr
    mov	   cx, 8080h
    mov    bh, 80h 	

program:
	mov	al, cl; al=c
	cbw
	imul	ax; ax=c**2
	shl	ax, 2; ax=4c**2
	mov	dx, ax; dx=4c**2
	shl	ax, 1; ax=8c**2
	add	ax, dx; ax=12c**2
	adc	dx, 0h; cf checking
	or	dx, dx;  or    dx, dx        ; is dx zero?
	jnz	overflow      ; if yes, jump to writing
	mov	si, ax; si=12c**2
	mov	al, bh; al=a
	cbw
	or	ax, ax; checking znak by SF
	js	absolute_a
	add	si, ax
	js	overflow      ; if sf = 1 (si > 07fff) then jump to overflow
	jc	overflow      ; if cf = 1 (e.g. si = FFFF + 1 = 0000 [cf = 1]) => jump to overflow
	jmp	short change_way  ; jmp to checking file  
	
absolute_a:
	neg ax; ax=|a|
	sub si, ax
	jc    change_way        ; if cf = 1 (e.g. 0001 - 0002 = FFFF [cf = 1, sf = 1])   
	js    overflow      ; if sf = 1 (si > 07fff) then jump to overflow	
change_way:
    or    bl, bl        ; is descriptor zero?
    jnz    iteration     ; if no then go to cycles
    jmp    short znam     ; else jump to numerator
overflow:
    mov    al, bh       ; al = a
    mov    bp, bx       ; bp = bx  (bh = a, bl = descr)
    mov    bx, cx       ; bx = b+c   
    mov    cx, 3        ; cx = 3
    mov    si, di       ; si = di
strWrite:
    mov    dl, '+'      ; dh = 2Bh
    or    al, al       ; check al sign
    jns    positive_number      ; jump if al >= 0
    mov    dl, '-'       ; dh = 2Dh
    neg    al            ; al = |al|
positive_number:
    aam                  ; adjust al to BCD (e.g. 127d==7fh => ax = 0C07h)
    or    al, 30h       ; convert al to ascii    (e.g. ax = 0C37h)
    mov    dh, al        ; dx = al|2D             (e.g. dx = 372Dh) 
    mov    al, ah        ; al = ah                (e.g. ax = 0C0Ch)
    aam                  ; adjust al to BCD       (e.g. ax = 0102h) 
    or    ax, 3030h     ; convert al to ascii    (e.g. ax = 3132h)      
    xchg    dl, al        ;                        (e.g. ax = 312Dh, dx = 3732h)  
    stosw                ; string =               (+100|0000|0000) di = di + 2
    mov    ax, dx        ;                        (e.g. ax = 3732h)
    stosw                 ; string =               (+127|0000|0000) di = di + 4
    inc    di            ;                                         di = di + 5
    xchg    bl, bh        ; bl = b, bh = a FOR 1 loop, bl = a, bh = b FOR 2 loop, bl = b, bh = a FOR 3 loop
    mov    al, bl        
    loop    strWrite     ; loop
writeFile: 
    xchg    bl, bh        ; bl = a, bh = b
    mov    di, si        ; di point to the beginning of STRING
    mov    dx, di        ; dx = di 
    mov    si, bx        ; save bx
    mov    bx, bp        ; get bl = descr
    xor    bh, bh        ; bh = 0
    mov    cx, 16        ; number of bytes to write (string length)
    mov    ah, 40h       ; write to file function
    int    21h           ; call dos
    mov    cx, si        ; restore cx
    mov    bx, bp        ; restore bx
iteration:
    cmp    cl, 7fh       
    jne    c_loop
    cmp    ch, 7fh
    jne    b_loop
    cmp    bh, 7fh
    je    closeFile
    inc    bh
    mov    ch, 7fh
b_loop:
    mov    cl, 7fh
    inc    ch    
c_loop:
    inc    cl
    jmp    program  
closeFile:
    mov    ah, 3Eh
    xor    bh, bh
    int    21h
    jmp    SHORT Exit

znam:
	mov	al, ch; al=b
	cbw
	mov 	bp, ax; bp=b
	shl	ax,1; ax=2b
	mov	dx, ax; dx=2b
	shl	dx, 2; dx=8b
	add	ax, dx; ax=10b
	add	ax, bp; ax=11b
	shl	dx, 2; dx=32b
	shl	bp, 2; bp=4b
	add	dx, bp; dx=36b
	add	dx, ax; dx=47b
	imul	dx; ax = 47*11 = 517b^2
 	mov    	bp, ax       ; dx:bp = 517b^2  
    	mov    	al, bh       ; al = a
    	imul    al           ; ax = a^2
    	xchg    ax, cx       ; al = c, cx = a^2
    	cbw                 ; ax = c 
    	xchg    ax, cx       ; ax = a^2, cx = c   
    	sub    	ax, cx       ; ax = a^2 - c
	js	abs_a ; if ax is negative jump to negative_a2c
    	add    	bp, ax       ; dx:bp = 517b^2 + a^2 -c
    	adc    	dx, 0        ; add carry to dx    
    	jmp    	short delenie ; go to div
abs_a:
	neg    	ax           ; ax = |a^2-c|
    	sub    	bp, ax    ; dx:bp = 517b^2 - (a^2 - c)
    	sbb    	dx, 0     ; sub borrow from dx
delenie:
	mov    	ax, bp    ; dx:ax = dx:bp
    	idiv    si           ; 517b^2 + a^2 - c / si
    	mov    	[d], ax    ; store result
Exit:
    	mov    	ah, 04Ch
    	int    	21h
    	End    	Start