;rc ��������� �������������� ������ � ����������� ���-�� ������ �� ���� ������������ ������ ������ ���� 1841
;rc ����������� ���� ������� �� 16k ������� 0xaa55 � ���������� (��� �������� ��������). ��� ������ (����������)  
;rc 16k ���� ����������� ������ � ����� ���������� ���������� � ��������. 
;rc � ������ ������ � ������� 0..384k ���������� ��������������.
;rc � ������ ������ � ������ 16k ����� 2b0 ����� �������������� ��� ��� ���������� ����� 2b0 ������� ���������������.
;rc � ������ ������ � 384...640k ����� ������ ����������� ��� ��������������.
;rc  �� ������ �������� � ��� ������ BIOS ����������� ������� tabl1 � �������:
;rc ����� ����� ����� (2 �����), ����� ��������� �������� �� ����� (������ 16k) (2 �����)
;rc ����� ��������� �������� �� ����� 2b0 ��������� ����� � mem_siz � ������� ������ BIOS.
;rc ���� ��������� ������������� ��. 
;rc �������� 512..640 ����������� ����� �������, �.�. ���� 2 ����� �� 512 ���� 1841 � ���� ����� 128 ���� 1840,
;rc �� � tabl1 ����� ������ 640k � ����� ����.

;rc ������������ ������ ����� �������� (aa55 � ����). �������� ����� 2b0 ��������� ����������� ������ � e190
;rc IBM-���� ���������� stgtst. �������������� ����� �������� ���������������� � ������ ����. 

 	assume	ds:abs0
ca0:                		 
 	in	al,port_b
 	and	al,0cfh		;rc 0b1100.1111	clear bit5 (i/o ch err off), bit4 (ram err off)
 	out	port_b,al
 	xor	ax,ax
 	mov	ds,ax
 	mov	es,ax
 	mov	dx,213h
 	mov	al,01
 	out	dx,al	   ; �������������� ����� ���������� rc ���������� ������ EXT, ��� � � IBM
 	mov	bx,0
 	mov	dx,2b0h
 	in	al,dx      	;rc ������ ������� ������� ����� ������ 2b0
 	and	al,0ch
 	cmp	al,0ch          ;rc ��� 1?
 	jz	ca1      
 	mov	bx,res_fl
ca1:	mov	al,0ah
 	out	dx,al           ;rc 0b0000.1010 - ����������� �������
 	in	al,dx           ;rc ������ ���� �������
 	and	al,0fh          ;rc 0b0000.1111 ������ ������� �������
 	cmp	al,0ah          ;rc ���������� � ���������
 	jnz	oshp	   ; ��� ����� 2B0 rc ���� �� ������� (������ ������ ��1840, �� ������ ���������� 2b0!)
 	mov	al,0ch
 	out	dx,al           ;rc 0b0000.1100 ��������� ������ � ������
 	xor	al,al  ; ����� ���������� ��������� ���� ������ rc � ����� ������� 00 (���� ��/��)...
ca2:	inc	dx               
 	out	dx,al
 	cmp	dl,0b3h         ;rc ...� ����� 2b1...2b3.
 	jnz	ca2             ;rc ����� �����
ca22:	mov	bx,res_fl
 	mov	cx,2000h        ;rc ������� ��� �������� 8� ���� - 16��
 	cmp	bx,1234h        ;rc ���� ������� ������� ������������?
 	jz	ca8
 	mov	ax,0f000h
 	mov	ss,ax           ;rc ��� �� ���� � ���
ca7a:	mov	sp,offset caw   ;rc ����� �������� ��� stgtst_cnt ����� ca3
ca7:	jmp	stgtst_cnt      ;rc �������� 16�� � �� �������
ca3:	mov	cx,2000h
 	je	ca8             ;rc ��� ������?->ca8
 	mov	dx,2b0h    ; ���� � ������ 16� �������� �����
 	in	al,dx	   ; ������
 	test	al,03	   ; �������������� ����? rc0b0000.0011
 	jz	ca6        ;rc 00 � ������� �������� ��������, ��� ��������� �� ����

;--------------rc ������ ������ � ������ 16k 2b0, ���� �������� ��� ��� - ������������
oshp:                      ; ���� ��������������  rc ��� ������ ��� ����� 2b0 ��� ������ 1840
 	mov	bl,al
 	mov	al,89h     ;rc 0b1000.1001 ���������� ����� A,B �� �����, ���� C �� ����
 	out	cmd_port,al
 	mov	al,04      ;rc 0b0000.0100
ca5:	out	port_a,al  ;rc ����� � ���� A!! ���� ������� �� ������ � IBM
 	xor	cx,cx
ca4:	loop	ca4	   ;rc ����������� ���� � ������� � ���� A ���� �������� (���� ���� 16k) � 04h... 
			   ;rc ...��� ����������� �� 2b0 (���� ��� �����) � 04h
 	xchg	bl,al
 	jmp	ca5
;--------------rc ����� ������

ca6:	or	al,3       ;rc ��������� �� ���� � ������ ������ 16k: ������ ����� ����� 0
 	out	dx,al
 	jmp	ca7a       ;rc � ������������ �� ���� ������ 16k

			;rc ���� ����� ������� ������������ ��� ���������� ������ ������ 16k
			;rc cx � ����� ������� �������� 2000h
ca8:	xor	ax,ax
 	cld
 	xor	si,si
 	xor	di,di
 	mov	bp,2b0h
 	rep	stosw       ;rc ������� ������ 16k ������
 	mov	res_fl,bx
ca9:	mov	dx,0400h    ;rc �������, ��������� �� ������� 16k
 	mov	bx,16       ;rc ���������������� ������� ��������� �������� (����� �������� � tabl1 � mem_siz)

			;rc �������� ����-���� �����
ca10:	mov	es,dx       ;rc ��������� ������� ��� stos
 	xor	di,di
 	mov	ax,0aa55h
 	mov	cx,ax
 	mov	es:[di],ax  ; �������� ������� ��������� 16� ������ rc: ����� aa55...
 	mov	al,0fh      ;rc �����???? �������� �� �����
 	mov	ax,es:[di]  ;rc ...� ����� ������
 	xor	ax,cx       ;rc ���������� � ��������
 	jnz	ca11        ;rc �����������->��� ������ ��� ������->ca11
 	mov	cx,2000h
 	rep	stosw       ;rc ���� ������->������ ��������� 16k ������ (ax=00 ����� ��� ������������ � ��������)
 	mov	cx,2000h
 	xor	di,di
 	repz	scasw	   ; ���� ������� ������ � ������ 16�? rc ������������ �� �������� �� ���� � �������� �������
 	or	cx,ax      ;rc ��������� ���� ����, ���� ��� �� ����, cx=0. or, ����� �� ����� ��������  
 	jnz	ca11	   ; ��
 	add	dx,0400h   ; ��� rc ��������� ������� (���� 16k ������)
 	add	bx,16      ;rc �������� ������� ��������� �������� �� ������ ��� �����������
 	cmp	dh,0a0h    ;rc ���������� ������� 640k?
 	jnz	ca10       ;rc ��� - ���������� ����-����
 	jmp	ca12       ;rc ��

			;rc ����� �� � ������ ���������� ��������� 16k ��� ����������� ���� � ��������� 16k
ca11:	cmp	dh,60h     ;rc ���������� ����� �������� � 384K
 	jnb	ca12       ;rc ����� >=384 ->ca12
 	mov	dx,bp	   ; ����� ������ 512�  rc ������ � ��������� �����������!! ������ ���� ������ ������ 384k
 	in	al,dx      ;rc ������ ���� �����
 	test	al,03      ;rc ���� ��������������?
 	jnz	ca12       ;rc ���� �������������� ���� ��� ���� ����������� ->ca12
			;rc ���� �� ���� - ���� �����������������
 	mov	dx,es      ;rc ��������������� ������� � dx
 	and	dh,60h     ;rc �������� �� ���� ����� �����
 	xor	dh,60h     ;rc ����������� ����� �����
 	mov	cl,5
 	shr	dh,cl      ;rc ������� � ������� ������� - �������� ��� ��������������
 	or	al,dh      ;rc �������� � ������ ��/�� ������
 	mov	dx,bp
 	out	dx,al      ;rc �������� � ���� ������
 	xor	dx,dx
 	xor	bx,bx
 	jmp	ca10       ;rc ������������ �� ������������ ������ � ������ ������

			;rc ����� �� ����:
			;rc �)������ �������� ��� ������ ������� � 384k...640k
			;rc �)������ �������� ��� ������ ������� � 384k...512k - ������������ ������ 
			;rc �)������ �������� � 16k..384k ��� ����� ��������������
			;rc �� ���� ���� �������, ���� �� �� 2b0, ������ ����� ���������
			;rc �� ���������� ������������� 16-�� �����, �.�. �� �������� bx.
			;rc �)���������� ������� 640k ��� ������
			;rc ���� ������� ����� ������� ����, ������� bx ����� ������� � tabl1.

ca12:	 	 	   ; ����� ���������� �������� ������ ������
 	mov	dx,bp
 	in	al,dx
 	and	al,0f3h    ;rc 0b1111.0011 - ��������� ��/��
 	out	dx,al
 	mov	dx,2b0h    ; ������� �� ����� ������ 2B0 rc(�.�. ������� tabl1 ��������� � ���)
 	in	al,dx
 	or	al,0ch     ;rc 0b0000.1100 - �������� ��/�� � 2b0
 	out	dx,al
 	test	bp,3       ;rc ������� ����� ���� 2b0?
 	jnz	ca14       ;rc ���->��������� bx �� 0 (���� �� �����)
 	mov	mem_siz,bx ;rc �� - ��������� ������ DOS �� ���������� ������������� �����
ca15:
 	mov	si,csi	   ;rc csi - ��������� � tabl1, ��� ������ ������� csi=0
 	mov	tabl1[si],bp     ;rc ����� � tabl1 ����� ����� ������� �����
 	mov	tabl1[si+2],bx   ;rc � ����� ��������� ��
 	inc	bp               ;rc ��������� �����
 	add	csi,4            ;rc ��������� �� ��������� ������� � ������� tabl1
ca16:	cmp	bp,2b4h          ;rc ��� ����� ���������?
 	jnb	ca13             ;rc ��->����� � ����������� POST
 	mov	bx,0             ;rc ����� ������� �� ���� ���� �����: �������� ������� ��,
 	mov	al,0ch
 	mov	dx,bp            
 	out	dx,al            ;rc ��� ��/�� � �������� �������� ���� ����� 
 	mov	dx,2b0h 	; ����� ���������� 2b0
 	in	al,dx
 	and	al,0f3h          ;rc �.�. ���� ��/�� 2b0, �������� ��� ��� ����
 	out	dx,al
 	mov	dx,0             ;rc ��������� ������� ��� ����� �����
 	jmp	ca10             ;rc ������� �� ���� ����� �����

ca14:	cmp	bx,0             ;rc ����� 2b1..2b3 �� ���� ��� ���� � ������ 16k?
 	jnz	ca15             ;rc ��� ->����� � �������, ��� ������
 	inc	bp               ;rc ����� ����� ����� �����
 	jmp	ca16
ca13:                            ;rc ����������� �� ������
 	mov	ax,data          
 	mov	ds,ax            ;rc ����� ds �� ��� ������ BIOS
 	mov	bp,0
 	jmp	c21              ;����������� �����
