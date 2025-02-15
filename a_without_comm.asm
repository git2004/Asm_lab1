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
    	mov    cx, word ptr [c] 
    	mov    bh, a            
    	or    cl, cl     
    	jz    cycles    
    	or    ch, ch     
    	jz    cycles     
    	or    bh, bh   
    	jnz    program      

cycles:
    mov    dx, offset file    
    mov    di, offset string    
    mov    ah, 03Ch             
    xor    cx, cx                         
    int    21h            
    mov    bx, ax         
    mov	   cx, 8080h
    mov    bh, 80h 	

program:
	mov	al, cl
	cbw
	imul	ax
	shl	ax, 2
	mov	dx, ax
	shl	ax, 1
	add	ax, dx
	or	dx, dx
	jnz	overflow     
	mov	si, ax
	mov	ah, bh
	sar	ax, 8
	js	absolute_a
	add	si, ax
	js	overflow    
	jc	overflow     
	jmp	change_way 
	
absolute_a:
	neg ax; ax=|a|
	sub si, ax
	jc    change_way        
	js    overflow   
change_way:
    or    bl, bl       
    jnz    iteration     
    jmp    znam    
overflow:
    mov    al, bh      
    mov    bp, bx       
    mov    bx, cx       
    mov    cx, 3        
    mov    si, di      
strWrite:
    mov    dl, '+'     
    or    al, al      
    jns    positive_number      
    mov    dl, '-'       
    neg    al           
positive_number:
    aam                  
    or    al, 30h      
    mov    dh, al       
    mov    al, ah       
    aam                
    or    ax, 3030h    
    xchg    dl, al     
    stosw           
    mov    ax, dx  
    stosw               
    inc    di         
    xchg    bl, bh     
    mov    al, bl        
    loop    strWrite 
writeFile: 
    xchg    bl, bh       
    mov    di, si     
    mov    dx, di       
    mov    si, bx        
    mov    bx, bp       
    xor    bh, bh       
    mov    cx, 16      
    mov    ah, 40h     
    int    21h          
    mov    cx, si       
    mov    bx, bp      
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
    jmp    Exit

znam:
	mov	al, ch
	cbw
	mov 	bp, ax
	shl	ax,1
	mov	dx, ax
	shl	dx, 2
	add	ax, dx
	add	ax, bp
	shl	dx, 2
	shl	bp, 2
	add	dx, bp
	add	dx, ax
	imul	dx
 	mov    	bp, ax       
    	mov    	al, bh       
    	imul    al           
    	xchg    ax, cx     
    	cbw                 
    	xchg    ax, cx      
    	sub    	ax, cx       
	js	abs_a 
    	add    	bp, ax      
    	adc    	dx, 0        
    	jmp    	delenie
abs_a:
	neg    	ax         
    	sub    	bp, ax    
    	sbb    	dx, 0     
delenie:
	mov    	ax, bp   
    	idiv    si           
    	mov    	[d], ax 
Exit:
    	mov    	ah, 04Ch
    	int    	21h
    	End    	Start
