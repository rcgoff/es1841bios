;
;
;-------rc ��������� ���� �������� �������� �� IBM-���� e19, ������ �� XTBIOS.ASM (� �������)
;	���� ������ �����������. ��������� ������ (��������������, ea1) - ������������ �������.
;
 	assume cs:code,ds:data
e190:	push	ds
 	mov	ax,16
 	cmp	reset_flag,1234h
 	jnz	e20a
 	jmp	e22			;rc ��� ������� ����������� ������ ����� (������� �����)
e20a:	mov	ax,16                   ; STARTING AMT. OF MEMORY OK   
 	jmp	short prt_siz           ; POST MESSAGE                 
e20b:	mov	bx,memory_size          ; GET MEM. SIZE WORD    
 	sub	bx,16                   ; 1ST 16K ALREADY DONE  
 	mov	cl,4
 	shr	bx,cl                   ; DIVIDE BY 16                
 	mov	cx,bx                   ; SAVE COUNT OF 16K BLOCKS    
 	mov	bx,0400h                ; SET PTR. TO RAM SEGMENT>16K 
e20c:	mov	ds,bx                   ; SET SEG. REG      
 	mov	es,bx                                       
 	add	bx,0400h                ; POINT TO NEXT 16K 
 	push	dx                                          
 	push	cx                      ; SAVE WORK REGS    
 	push	bx
 	push	ax
 	call	stgtst
 	jnz	e21a                    ; GO PRINT ERROR           
 	pop	ax                      ; RECOVER TESTED MEM NUMBER
 	add	ax,16
prt_siz:
 	push	ax
 	mov	bx,10                   ; SET UP FOR DECIMAL CONVERT    
 	mov	cx,3                    ; OF 3 NIBBLES                  
decimal_loop:
 	xor	dx,dx
 	div	bx                      ; DIVIDE BY 10   
 	or	dl,30h                  ; MAKE INTO ASCII
 	push	dx                      ; SAVE           
 	loop	decimal_loop
 	mov	cx,3
prt_dec_loop:
 	pop	ax                      ; RECOVER A NUMBER
 	call	prt_hex
 	loop	prt_dec_loop
 	mov	cx,22
 	mov	si,offset e300
kb_ok:	mov	al,byte ptr cs:[si]
 	inc	si
 	call	prt_hex
 	loop	kb_ok			;rc ����� ������ e300 (kb ����� ������) - 22 �������, �����������
 	pop	ax                      ; RECOVER WORK REGS   
 	cmp	ax,16                   ; FIRST PASS?         
 	je	e20b                    
 	pop	bx                      ; RESTORE REGS              
 	pop	cx                                                  
 	pop	dx                                                  
 	loop	e20c                    ; LOOP TILL ALL MEM. CHECKED -----rc � XT e21
 	mov	al,10
 	call	prt_hex                 ; LINE FEED 
 	pop	ds
 	jmp	e22  			;rc ��� �����
e21a:                                   ;rc ������ ��� stgtst
 	pop	bx
 	add	sp,6
 	mov	dx,ds
 	pop	ds
 	push	ds
 	push	bx
 	mov	bx,dx
 	push	ax
 	cmp	dh,60h			;rc ������ � 512k-640k?
 	jnb	ea1                     ;rc ��->ea1 (������������ ������)
 	mov	dx,2b0h
 	in	al,dx
 	test	al,3			;rc ���� �������������� ����� 2b0?
 	jnz	ea1                     ;rc ��->ea1 (������������ ������)
 	push	ax                      ;rc ����� �������������� �����,
 	mov	al,crt_mode
 	mov	ah,0
 	int	10h
 	pop	ax
 	mov	dx,bx                   ;rc �������� �� �������� ������ ��� ��������������,
 	and	dh,60h
 	xor	dh,60h
 	mov	cl,5
 	shr	dh,cl
 	or	al,dh
 	mov	dx,2b0h 		 
 	out	dx,al                   ;rc ���������� ��������������...
 	xor	ax,ax
 	mov	es,ax
 	mov	ds,ax
 	jmp	ca22			;rc ...� ������������ � ���� ca0 �� ������ ��������

ea1:	pop	ax      		;rc ������ ������������ ������
 	mov	dx,bx
 	pop	bx
 	mov	tabl+2,bx		;rc ���������� ����� ����� ��������� �� ����� 2b0 � ������� tabl
 	mov	memory_size,bx		;rc ��������� ������, ��������� ��
;rc------------------rc tabl � tabl1, ��� �� ��� � mem_siz � memory_size, ��������� �� ���� � �� �� ����� � ���, 
;rc------------------rc ������ tabl � memory_size � �������� ��� ������ BIOS (40h), � tabl1 � mem_siz � �������� 0h
 	push	ax
 	mov	al,10 			;rc �������� ������� ������
 	call	prt_hex
 	pop	ax
 	jmp	osh
prt_hex proc	near
 	mov	ah,14
 	mov	bh,0
 	int	10h
 	ret
prt_hex endp
