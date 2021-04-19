;ASM-файл создан из листинга удалением разбивки на страницы,
;удалением пустых строк в начале страниц,
;исправлением строк, разбитых в листинге надвое,
;удалением пустых строк, оставшихся 
;от слишком длинных DB-последовательностей.
;Л.Ядренников (RCgoff) 25.04.2020


;Microsoft MACRO Assembler  Version 3.00
;09-15-88    
;___________________	 	 	 	
; 8/04/1986 новая клавиатура
 PAGE 55,120
;  БАЗОВАЯ СИСТЕМА ВВОДА/ВЫВОДА (БСУВВ)
;___________________
port_a	equ	60h
cod	equ	0f000h
dat	equ	0040h
sta	equ	0030h
xxdat	equ	0050h
video_ra equ	0b800h
port_b	equ	61h
port_c	equ	62h
cmd_port equ	63h
inta00	equ	20h
inta01	equ	21h
eoi	equ	20h
timer	equ	40h
tim_ctl equ	43h
timero	equ	40h
tmint	equ	01
dma08	equ	08
dma	equ	00
max_period equ	540h
min_period equ	410h
kbd_in	equ	60h
kbdint	equ	02
kb_dat	equ	60h
kb_ctl	equ	61h
;_______________
;  Расположение прерываний 8086
;_________________________
abs0	segment para
zb	label	byte
zw	label	word
stg_loc0 label	byte
 	org	2*4
nmi_ptr label	word
 	org	5*4
int5_ptr label	word
 	org	8*4
int_addr label	word
int_ptr label	dword
 	org	0dh*4
hdisk_int  label  dword
 	org	10h*4
video_int label word
 	org	13h*4
org_vector  label  dword
 	org	19h*4
boot_vec  label  dword
 	org	1dh*4
parm_ptr label	dword
 	org	01eh*4
disk_pointer label dword
diskette_parm  label  dword
 	org	01fh*4
ext_ptr label	dword
 	org	040h*4
disk_vector  label  dword
 	org	041h*4

hf_tbl_vec  label  dword
 	org	410h
eq_fl	label	byte

 	org	413h
mem_siz label	word
 	org	472h
res_fl	label	word
 	org	4d0h
csi	label	word
 	org	4e0h
tabl1	label	word
 	org	7c00h
boot_locn label far
abs0	ends

;______________________
;  Использование стека только во время инициализации
;______________________
stac	segment para stack
 	dw	128 dup(?)

tos	label	word
stac	ends

;______________________
;  Область данных ПЗУ
;____________________
data segment	para
rs232_base dw 4 dup(?)

printer_base dw 4 dup(?)

equip_flag dw ?
mfg_tst db	?
memory_size dw	?
io_ram_size dw	?
;_______________
;  Область данных клавиатуры
;_________________
kb_flag db	?

;  Размещение флажков в kb_flag

ins_state equ	80h
caps_state equ	40h
num_state equ	20h
scroll_state equ 10h
alt_shift equ	08h
ctl_shift equ	04h
left_shift equ	02h
right_shift equ 01h

kb_flag_1 db	?

ins_shift equ	80h
caps_shift equ	40h
num_shift equ	20h
scroll_shift equ 10h
hold_state equ	08h
inv_shift equ	04h
lat	 	equ	02h
lat_shift	equ	01h



alt_input db	?
buffer_head dw	?
buffer_tail dw	?
kb_buffer dw	16 dup(?)

kb_buffer_end label word

;  head=tail указывает на заполнение буфера

num_key equ	69
scroll_key equ	70
alt_key equ	56
ctl_key equ	29
caps_key equ	86
left_key equ	84
right_key equ	85
ins_key equ	82
del_key equ	83
inf_key   equ	89
inv_key_l  equ	88
inv_key_r equ	90
rus_key    equ	91
lat_key equ	87

;____________________
;  Область данных НГМД
;____________________
seek_status db	?
;
;
int_flag equ	080h
motor_status db ?
;
;
motor_count db	?
motor_wait equ	37

;
diskette_status db ?
time_out equ	80h
bad_seek equ	40h
bad_nec  equ	20h
bad_crc  equ	10h
dma_boundary equ 09h
bad_dma  equ	08h
record_not_fnd equ 04h
write_protect equ 03h
bad_addr_mark equ 02h
bad_cmd equ	01h

cmd_block  label  byte
hd_error  label  byte
nec_status db	7 dup(?)


;_____________________
;  Область данных ЭЛИ
;_____________________
crt_mode db	?
crt_cols dw	?
crt_len  dw	?
crt_start dw	?
cursor_posn dw	8 dup(?)

cursor_mode dw	?
active_page db	?
addr_6845 dw	?
crt_mode_set db ?
crt_pallette db ?

;___________________
;  Область данных НМД
;___________________
io_rom_init dw	?
io_rom_seg dw	?
last_val db	?

;___________________
;  Область данных таймера
;___________________
timer_low dw	?
timer_high dw	?
timer_ofl db	?
;counts_sec equ 18
;counts_min equ 1092
;counts_hour equ 65543
;counts_day equ 1573040 = 1800b0h

;___________________
;  Область данных системы
;___________________
bios_break db	?
reset_flag dw	?
diskw_status  db  ?
hf_num	db   ?
control_byte  db  ?
port_off  db  ?
 	 	org	7ch
stat_offset	label	byte ; смещение для хранения состояний модема

 	org	80h
buffer_start	dw	?
buffer_end	dw	?
 	org	0090h
idnpol	dw	?
 	org	0e0h
tabl	label	word
;
data	ends

;___________________
;  Область расширения данных
;_________________________________
xxdata segment	para
status_byte db	?
xxdata	ends

;_________________
;  Буфер ЭЛИ
;___________________
video_ram segment para
regen	label	byte
regenw	label	word
 	db	16384 dup(?)

video_ram ends
;____________________
;  Основной массив в ПЗУ (сегмент code)
;____________________
;***************  INT 13  *****************************************
;******************************************************************
;
;
;    Программа обслуживания накопителя на магнитном диске
;
;
;	ВВОД
;	 	(АН-шестнадцатеричное значение)
;    (АН=00) - сброс НМД (DL=80H,81H)/НГМД
;	(АН=01) считывание состояния последней операции диска в (AL)
;	 	  Замечание: DL<80Н-НГМД,DL>80Н-НМД
;	(АН=02) считывание указанных секторов в память
;	(АН=03) запись указанных секторов из памяти
;	(АН=04) проверка указанных секторов
;	(АН=05) форматизация указанной дорожки
;	(АН=06) форматизация указанной дорожки
;	 	неверного сектора
;	(АН=07) форматизация устройства,начиная с указанной дорожки
;	(АН=08) возврат текущих параметров устройства
;	(АН=09) инициализация характеристик устройства
;	 	Прерывание 41H указывает на блок данных
;	(АН=0А) длинное считывание
;	(АН=0В) длинная запись
;	 	Замечание:длинные считывание и запись включают 512 байт +
;	 	4 байта ЕСС
;	(АН=0С) установка
;	(АН=0D) селективный сброс диска
;	(АН=0Е) считать буфер сектора
;	(АН=0F) записать буфера сектора
;	(АН=10) проверить готовность устройства
;	(АН=11) рекалибровать
;	(АН=12) диагностика памяти контроллера
;	(АН=13) диагностика устройства
;	(АН=14) внутренняя диагностика контроллера
;
;
;	Регистры,используемые для операций НМД
;
;	(DL) -номер устройства (80Н-87Н для диска,контр.значение)
;	(DH) -номер головки (разрешается 0-7,не контр.значение)
;	(СН) -номер цилиндра (0-1023,не контролируемое значение)
;	(СL) -номер сектора (1-17,не контролируемое значение)
;	 	Замечание:старшие 2 бита номера цилиндра размещены
;	 	в двух старших битах регистра CL (всего 10 бит)
;	(АL) -число секторов (максимально возможное число 1-80Н,
;	      для длинного считывания/записи 1-79H)
;	(значение чередования для форматизации 1-16D)
;	(ES:BX)-адрес буфера для бит номера цилиндра
;	 	(не требуется для проверки)
;
;
;	ВЫВОД
;	АН-состояние текущей операции
;	   CF=0 -успешная операция (АН=0 при возврате)
;	   CF=1 -неверная операция (АН содержит ошибку)
;
;	Замечание:ошибка 11Н показывает,что считанные данные имеют
;	 	  исправляемую ошибку,которая была скорректирована
;	 	  алгоритмом ЕСС.Ошибка может не повторяться,если
;	 	  данные перезаписаны.(АL) содержит длину пакета.
;
;	Если были затребованы параметры устройства:
;
;	DL -количество подключенных устройств(0-2)
;	DH -максимальное используемое значение для номера головки
;	СН -максимальное используемое значение для номера цилиндра
;	CL -максимальное используемое значение для номера сектора и
;	    старших бит номера цилиндра
;
;	Замечание:если ошибка имеет место в коде диска,то диск
;	 	  сбрасывается,и операция повторяется
;
;
code segment para
;
sense_fail	equ	0ffh	  ;
undef_err	equ	0bbh
time_out	equ	80h
bad_seek	equ	40h
bad_cntlr	equ	20h
data_corrected	equ	11h
bad_ecc 	equ	10h
bad_track	equ	0bh
dma_boundary	equ	09h
init_fail	equ	07h
bad_reset	equ	05h
record_not_fnd	equ	04h
bad_addr_mark	equ	02h
bad_cmd 	equ	01h
;
;-------Порт контроллера в/в-------------------------------------
;
;	 	-считывание из порта:
;	HF_PORT+0 -считывание данных(из контроллера в CPU)
;	HF_PORT+1 -считывание состояния оборудования контроллера
;	HF_PORT+2 -считывание конфигурации переключателей
;	HF_PORT+3 -не используется
;
;	 	-запись в порт:
;	HF_PORT+0 -запись данных (из CPU в контроллер)
;	HF_PORT+1 -сброс контроллера
;	HF_PORT+2 -выработка такта выборки контроллера
;	HF_PORT+3 -запись в регистр маски ПДП/прерывания
;
;----------------------------------------------------------------

;
;

hf_port 	equ	0320h	    ; порт НМД
r1_busy 	equ	00001000b   ; бит занятости порта 1 диска
r1_bus	 	equ	00000100b   ; бит команда/данные порта 1 диска
r1_iomode	equ	00000010b   ; бит режима порта 1 диска
r1_req	 	equ	00000001b   ; бит запроса порта 1 диска

dma_read	equ	01000111b   ; 3 канал ПДП (при считывании-047Н)
dma_write	equ	01001011b   ; 3 канал ПДП (при записи-04ВН)
dma	 	equ	0	    ; адрес ПДП
dma_high	equ	082h	    ; порт для старших 4бит ПДП

tst_rdy_cmd	equ	00000000b
recal_cmd	equ	00000001b
sense_cmd	equ	00000011b
fmtdrv_cmd	equ	00000100b
chk_trk_cmd	equ	00000101b
fmttrk_cmd	equ	00000110b
fmtbad_cmd	equ	00000111b
read_cmd	equ	00001000b
write_cmd	equ	00001010b
seek_cmd	equ	00001011b
init_drv_cmd	equ	00001100b
rd_ecc_cmd	equ	00001101b
rd_buff_cmd	equ	00001110b
wr_buff_cmd	equ	00001111b
ram_diag_cmd	equ	11100000b
chk_drv_cmd	equ	11100011b
cntlr_diag_cmd	equ	11100100b
rd_long_cmd	equ	11100101b
wr_long_cmd	equ	11100110b

int_ctl_port	equ	20h
eoi	 	equ	20h

max_file	equ	8
s_max_file	equ	2

 	assume	cs:code
 	org	0c000h

 	db	055h
 	db	0aah
 	db	16d

;----------------------------------------------------------------
;      ТЕСТ НМД
;
;	-установка векторов для НМД
;	-выполнение диагностики по включению электропитания должно
;	 отображать информацию об ошибках '1701' на дисплее
;
;
;---------------------------------------------------------------

disk_setup	proc	near
 	jmp	short	l3

 	db	' БАЗОВАЯ СИСТЕМА ВВОДА/ВЫВОДА '

l3:
 	assume	ds:abs0
 	sub	ax,ax
 	mov	ds,ax	 	    ; установка сегмента DUMMY (0)
 	cli	 	; сброс признака разрешения прерывания
 	mov	ax,word ptr org_vector	; установка вектора НГМД
 	mov	word ptr disk_vector,ax ;     в прерывание 40Н
 	mov	ax,word ptr org_vector+2
 	mov	word ptr disk_vector+2,ax
 	mov	word ptr org_vector,offset disk_io  ; поддержка
 	mov	word ptr org_vector+2,cs   ; НМД

 	mov	ax,offset hd_int
 	mov	word ptr hdisk_int,ax  ; прерывание НМД
 	mov	word ptr hdisk_int+2,cs
 	mov	word ptr boot_vec,offset boot_strapt ; загрузка
 	mov	word ptr boot_vec+2,cs
 	mov	word ptr hf_tbl_vec,offset fd_tbl ; таблица параметров
 	mov	word ptr hf_tbl_vec+2,cs
 	sti	; установить признак разрешения прерывания

 	assume	ds:data
 	mov	ax,dat
 	mov	ds,ax	 	; установка сегмента DATA
 	mov	diskw_status,0	; сброс индикации состояния
 	mov	hf_num,0	; нулевое число устройств
 	mov	cmd_block+1,0	; нулевое устройство,установить
 	 	 	 	; значение в блоке команд
 	mov	port_off,0	; нулевое смещение порта

 	mov	cx,25h	 	; число повторений
l4:
 	call	hd_reset_1	; сброс контроллера
 	jnc	l7
 	loop	l4	; повторный сброс,счетчик повторений = 25Н
 	jmp	error_ex
l7:
 	mov	cx,1
 	mov	dx,80h

 	mov	ax,1200h	; диагностика памяти контроллера
 	int	13h
 	jnc	p7t
 	jmp	error_ex
p7t:
 	mov	ax,1400h	; внутренняя диагностика контроллера
 	int	13h
 	jnc	p9t
 	jmp	error_ex
p9t:
 	mov	timer_low,0	; обнуление таймера
 	mov	ax,reset_flag
 	cmp	ax,1234h	; сброс клавиатуры?
 	jne	p8t
 	mov	timer_low,410d
p8t:
 	in	al,021h
 	and	al,0feh 	; таймер доступен
 	out	021h,al 	; запуск таймера
p4t:
 	call	hd_reset_1	; сброс контроллера
 	jc	p10t
 	mov	ax,1000h	; проверить готовность устройства
 	int	13h
 	jnc	p2t
p10t:
 	mov	ax,timer_low
 	cmp	ax,446d 	; 25 секунд
 	jb	p4t
 	jmp	error_ex
p2t:
 	mov	cx,1
 	mov	dx,80h	 	; DL=80Н - НМД 0
 	mov	ax,0900h	; установка параметров у-ва
 	int	13h
 	jc	error_ex

 	mov	ax,1100h	; рекалибровка
 	int	13h
 	jc	error_ex

 	mov	ax,0fc00h
 	mov	es,ax	 	; установка сегмента ES=FC00
 	sub	bx,bx	 	; смещение (ВХ) равно 0
 	mov	ax,0f00h	; запись буфера сектора (АН=0F)
 	int	13h

 	jc	error_ex

 	inc	hf_num	 	; нулевое устройство опрошено

 	mov	dx,213h 	; блок расширения
 	mov	al,0
 	out	dx,al	 	; отключение блока расширения
 	mov	dx,321h 	; считывание состояния оборудования
 	 	 	 	; контроллера.Находится ли контроллер
 	 	 	 	; в системном блоке?
 	in	al,dx
 	and	al,0fh	 	; выделение 4-х младших бит
 	cmp	al,0fh
 	je	box_on
 	mov	timer_low,420d	; контроллер в системном блоке
box_on:
 	mov	dx,213h 	; блок расширения
 	mov	al,0ffh
 	out	dx,al	 	; включение блока расширения

 	mov	cx,1
 	mov	dx,081h 	; DL=81 - НМД 1
p3t:
 	sub	ax,ax	 	; сброс диска (АН=00)
 	int	13h
 	jc	pod_done
 	mov	ax,01100h	; рекалибровка (АН=11)
 	int	13h
 	jnc	p5t
 	mov	ax,timer_low
 	cmp	ax,446d 	; 25 секунд
 	jb	p3t
 	jmp	pod_done
p5t:
 	mov	ax,0900h	; инициализация характеристик устройства
 	int	13h
 	jc	pod_done
 	inc	hf_num	 	; увеличение числа устройств
 	cmp	dx,[80h + s_max_file - 1]
 	jae	pod_done
 	inc	dx	 	; увеличение номера устройства
 	jmp	p3t

;------Ошибки POD

error_ex:
 	mov	bp,0fh	 	; флажки ошибок POD
 	sub	ax,ax
 	mov	si,ax	 	; счетчик равен 0
 	mov	cx,f17tl	; сообщение числа символов (6 байт)
 	mov	bh,0	 	; обнуление страницы
out_ch:
 	mov	al,cs:f17t[si]	; получение байта
 	mov	ah,14d	 	; ЭЛИ
 	int	10h	 	; отображение символа
 	inc	si	 	; следующий символ
 	loop	out_ch
 	stc	; установка признака переноса
pod_done:
 	cli	; сброс признака разрешения прерывания
 	in	al,021h
 	or	al,01h	 	; таймер неработоспособен
 	out	021h,al
 	sti	; установить признак разрешения прерывания
 	call	dsbl	 	; сброс маски прерывания
 	ret

f17t	db	'1701',0dh,0ah  ;    1701

f17tl	equ	$-f17t

hd_reset_1	proc	near	; сброс контроллера
 	push	cx	 	; сохранение регистров
 	push	dx
 	clc	 	 	; сброс переноса
 	mov	cx,0100h	; счетчик повторений
l6:
 	call	port_1
 	out	dx,al	 	; сброс контроллера
 	call	port_1
 	in	al,dx	 	; считывание состояния
 	and	al,2	 	; проверка сброса бита 1(ввод/вывод)
 	jz	r3t
 	loop	l6	 	; повторение сброса,счетчик = 100Н
 	stc	; установить признак переноса при неудачном сбросе
r3t:
 	pop	dx	 	; восстановление регистров
 	pop	cx
 	ret
hd_reset_1	endp

disk_setup	endp

;-----------INT 19---------------------------------------
;
;    Прерывание 19H загрузки системы
;    -БСУВВ НМД размещает в прерывании 19H вектор
;     первоначальной загрузки с указателем на эту программу загрузки
;    -сброс векторов параметров неверного НМД  или НГМД
;    -программа загрузки будет прочитана из цилиндра 0 сектора 1
;    -последовательность загрузки:
;	  -попытка загрузить систему с НГМД в ячейку BOOT_LOCN
;	   (0000/7C00)
;	  -если НГМД отсутствует, НМД используется
;	   как действительный блок загрузки.Действительный блок
;	   загрузки на НМД содержит байты 055Н 0ААН,
;	   как последние два байта блока
;	  -если отсутствуют и НГМД, и НМД, то устанавливается преры-
;	вание типа INT 18H, которое вызывает выполнение программ
;	тестирования и инициализации системы
;----------------------------------------------------------------------

boot_strapt:
 	assume	ds:abs0,es:abs0
 	sub	ax,ax
 	mov	ds,ax	 	; установка сегмента DUMMY (0)

;-----Установка параметров векторов---------------------------

 	cli	; сброс признака разрешения прерывания
 	mov	word ptr hf_tbl_vec,offset fd_tbl
 	mov	word ptr hf_tbl_vec+2,cs
 	mov	word ptr diskette_parm,offset diskette_tbl
 	mov	word ptr diskette_parm+2,cs
 	sti	; установка признака разрешения прерывания

;-------Попытка загрузки с НГМД----------------------------------

 	mov	cx,3	 	; установить счетчик повторений
h1t:
 	push	cx	 	; запомнить счетчик повторений
 	sub	dx,dx	 	; обнуление номера устройства
 	sub	ax,ax	 	; сброс НГМД
 	int	13h
 	jc	h2t	 	; если ошибка,еще попытка
 	mov	ax,0201h	; считывание одного сектора

 	sub	dx,dx
 	mov	es,dx	 	; установка сегмента
 	mov	bx,offset boot_locn ; начальный адрес блока загрузки

 	mov	cx,1	 	; сектор 1,дорожка 0
 	int	13h
h2t:	pop	cx	 	; восстановление числа повторений
 	jnc	h4t	 	; при неудачном считывании CF=1
 	cmp	ah,80h	; если time-out,нет повторения
 	jz	h5	; попытка загрузки с НГМД
 	loop	h1t	; проделать загрузку с НГМД для нужного
 	 	 	; числа повторений
 	jmp	h5	; невозможность загрузки программы с НГМД
h4t:	 	 	 	; загрузка была успешной
 	db	0eah,00h,7ch,0,0   ; JMP     BOOT_LOCN

;-------Попытка загрузки с НГМД---------------------------------------

h5:
 	sub	ax,ax	 	; сброс НГМД (АН=0)
 	sub	dx,dx
 	int	13h
 	mov	cx,3	 	; установить счетчик повторений
h6:	 	 	 	; IPL_SYSTEM
 	push	cx	 	; запомнить счетчик повторений
 	mov	dx,0080h	; нулевой НМД
 	sub	ax,ax	 	; сброс диска (АН=0)
 	int	13h
 	jc	h7	 	; если ошибка,еще попытка
 	mov	ax,0201h	; считывание одного сектора
 	sub	bx,bx
 	mov	es,bx	 	; установка сегмента
 	mov	bx,offset boot_locn ; начальный адрес блока загрузки
 	mov	dx,80h	 	; НМД 0
 	mov	cx,1	 	; сектор 1, дорожка 0
 	int	13h
h7:	pop	cx	 	; восстановить счетчик повторений
 	jc	h8
 	mov	ax,word ptr boot_locn+510d  ; считываются последние
 	 	 	 	 	    ; 2 байта блока загрузки
 	cmp	ax,0aa55h	; тест для генерации BOOT (последние
 	 	 	 	; 2 байта блока должны быть равны АА55Н)
 	jz	h4t	 	; загрузка была успешной
h8:
 	loop	h6  ;проделать загрузку для нужного числа повторений

;----Невозможность загрузки с НГМД или с НМД--------------------

 	int	18h	 	; RESTART
;-------Таблица параметров НГМД-------------------------------------
diskette_tbl:
 	db	11001111b	; SRT=C,HD UNLOAD=0F-первый байт
 	db	2	 	; HD LOAD=1,MODE=DMA-второй байт
 	db	25h	 	; ожидание после выключения мотора
 	db	2	 	; 512 байт на сектор
 	db	8	 	; ЕОТ (последний сектор на дорожке)
 	db	02ah	 	; длина пробела
 	db	0ffh	 	; DTL
 	db	050h	 	; длина пробела для форматизации
 	db	0f6h	 	; полный байт для форматизации
 	db	25	 	; время установки головки (мсек)
 	db	4	 	; время запуска мотора (1/8 сек)

;

dsbl	proc	near
 	assume	ds:data
 	push	ds	 	; запомнить сегмент
 	mov	ax,dat
 	mov	ds,ax	 	; установка сегмента DATA

 	mov	ah,port_off
 	push	ax	 	; запомнить смещение порта

 	mov	port_off,0h	; смещение равно 0Н
 	call	port_3	 	; порт 323
 	sub	al,al
 	out	dx,al	 	; сброс маски INT/DMA (в порт 323
 	 	 	 	; записывается нулевой байт)
 	mov	port_off,4h	; смещение равно 4Н
 	call	port_3	 	; порт 327
 	sub	al,al
 	out	dx,al	 	; сброс маски INT/DMA
 	mov	port_off,8h	; смещение равно 8Н
 	call	port_3	 	; порт 32В
 	sub	al,al
 	out	dx,al	 	; сброс маски INT/DMA
 	mov	port_off,0ch	; смещение равно 0СН
 	call	port_3	 	; порт 32F
 	sub	al,al
 	out	dx,al	 	; сброс маски INT/DMA
 	mov	al,07h
 	out	dma+10,al	; установить режим ПДП невозможным
 	cli
 	in	al,021h
 	or	al,020h
 	out	021h,al 	; невозможность прерывания 5
 	sti	; установить признак разрешения прерывания
 	pop	ax	 	; восстановить смещение порта
 	mov	port_off,ah
 	pop	ds	 	; восстановить сегмент
 	ret
dsbl	endp

;---------------------------------------------------------------------
;-------Точка входа в БСУВВ НМД---------------------------------------
;----------------------------------------------------------------------

disk_io proc	far
 	assume	ds:nothing,es:nothing
 	cmp	dl,80h	 	; проверка наличия НМД
 	jae	hard_disk	; есть НМД
 	int	40h	 	; НГМД
ret_2:
 	ret	2
hard_disk:
 	assume	ds:data
 	sti	 	     ; установка признака разрешения прерывания
 	or	ah,ah
 	jnz	a3
 	int	40h	 	; сброс НГМД
 	sub	ah,ah
 	cmp	dl,[80h + s_max_file - 1] ; устройство 80 и 81
 	ja	ret_2	 	; если номер устройства больше
 	 	 	 	; максимального,то на выход
a3:
 	cmp	ah,08	 	; возврат параметров
 	jnz	a2
 	jmp	get_parmt_n	; возврат параметров устройства
a2:
 	push	bx	 	; запомнить регистры
 	push	cx
 	push	dx
 	push	ds
 	push	es
 	push	si
 	push	di

 	call	disk_io_cont	; выполнение операции

 	push	ax
 	call	dsbl	 	; убедиться,что все сброшено
 	mov	ax,dat
 	mov	ds,ax	 	; установить сегмент DATA
 	pop	ax
 	mov	ah,diskw_status ; получить состояние операции
 	cmp	ah,1	 	; установить флажок переноса для
 	 	 	 	; индикации неуспешной операции
 	cmc	; заменить значение CF на противоположное
 	pop	di	 	; восстановление регистров
 	pop	si
 	pop	es
 	pop	ds
 	pop	dx
 	pop	cx
 	pop	bx
 	ret	2
disk_io endp
;-------Таблица переходов по АН--------------------------------------
m1t	label	word
 	dw	disk_resett	; 000h
 	dw	return_status	; 001h
 	dw	disk_readt	; 002h
 	dw	disk_writet	; 003h
 	dw	disk_verft	; 004h
 	dw	fmt_trk 	; 005h
 	dw	fmt_bad 	; 006h
 	dw	fmt_drv 	; 007h
 	dw	bad_command	; 008h
 	dw	init_drv	; 009h
 	dw	rd_long 	; 00ah
 	dw	wr_long 	; 00bh
 	dw	disk_seek	; 00ch
 	dw	disk_resett	; 00dh
 	dw	rd_buff 	; 00eh
 	dw	wr_buff 	; 00fh
 	dw	tst_rdy 	; 010h
 	dw	hdisk_recal	; 011h
 	dw	ram_diag	; 012h
 	dw	chk_drv 	; 013h
 	dw	cntlr_diag	; 014h
m1tl	equ	$-m1t
;-------Формирование 1-го байта управляющего блока(устр.+головка)-----
setup_a proc	near
 	mov	diskw_status,0	; сброс индикации состояния
 	push	cx	 	; запомнить СХ

;-------Вычисление сдвига порта (PORT_OFF)---------------------------

 	mov	ch,dl	 	; запомнить номер устройства в СН
 	or	dl,1	 	; установка младшего разряда в 1
 	dec	dl	 	; уменьшить номер устройства на 1
 	shl	dl,1  ; выработка сдвига для пары 0-1(2-3,4-5,6-7)
 	mov	port_off,dl	; запись сдвига
 	mov	dl,ch	 	; восстановление номера устройства
 	and	dl,1	 	; выделение младшего разряда

 	mov	cl,5	 	; счетчик сдвига
 	shl	dl,cl ; номер устройства сдвигается на 5 разрядов влево
 	or	dl,dh	; номер головки + сдвинутый номер устройства
 	mov	cmd_block+1,dl	; формирование 1-го байта упр.слова
 	pop	cx	 	; восстанавливаем СХ
 	ret
setup_a endp

disk_io_cont	proc	near	; выполнение операции
 	push	ax
 	mov	ax,dat
 	mov	ds,ax	 	; установка сегмента DATA
 	pop	ax
 	cmp	ah,01h	 	; проверяется возврат состояния (АН=1)
 	jnz	a4
 	jmp	return_status	; переход на возврат состояния
a4:
 	sub	dl,80h	 	; номер устройства начинается с 0
 	cmp	dl,max_file	; проверка номера устройства
 	jae	bad_command

 	call	setup_a 	  ; формирование 1-го байта упр.блока

;-------Формирование блока команд---------------------------------

 	dec	cl	; сектора 0-16 для контроллера
 	mov	cmd_block+0,0
 	mov	cmd_block+2,cl	; сектор и старшие 2 бита цилиндра
 	mov	cmd_block+3,ch	; цилиндр
 	mov	cmd_block+4,al	; чередование/число блоков
 	mov	al,control_byte
 	mov	cmd_block+5,al	; управляющий байт
 	push	ax	 	; запомнить АХ
 	mov	al,ah	 	; получить в AL код операции
 	xor	ah,ah	 	; нулевой старший байт
 	sal	ax,1 ; сдвиг на 2 разряда влево для получения смещения
 	mov	si,ax	; смещение получить в SI для ветвления
 	cmp	ax,m1tl ; смещение в пределах заданной области?
 	pop	ax	 	; восстановление АХ
 	jnb	bad_command
 	jmp	word ptr cs:[si + offset m1t ] ; переход по смещению
bad_command:
 	mov	diskw_status,bad_cmd	; ошибка в команде
 	mov	al,0
 	ret
disk_io_cont	endp

;---------------------------------------------------------------------
;	Сброс диска (АН=00Н)
;---------------------------------------------------------------------

disk_resett	proc	near
 	call	port_1	 	; порт сброса
 	out	dx,al	 	; сброс контроллера
 	call	port_1
 	in	al,dx	 	; получить состояние
 	and	al,2	 	; проверка сброса бита 1 (ввод/вывод)
 	jz	dr1
 	mov	diskw_status,bad_reset	; неудачный сброс
 	ret
dr1:
 	jmp	init_drv	; инициализация параметров устройства
disk_resett	endp

;----------------------------------------------------------------------
;	Программа состояния диска (АН=001)
;---------------------------------------------------------------------

return_status	proc	near
 	mov	al,diskw_status ; получение предыдущего состояния
 	mov	diskw_status,0	; сброс состояния
 	ret
return_status	endp

;-----------------------------------------------------------------------
;	Программа считывания диска (АН=002Н)
;-----------------------------------------------------------------------

disk_readt	proc	near
 	mov	al,dma_read	; байт режима для чтения ПДП
 	mov	cmd_block+0,read_cmd	; код операции
 	jmp	dma_opn
disk_readt	endp

;--------------------------------------------------------------------
;	Программа записи диска (АН=003Н)
;--------------------------------------------------------------------

disk_writet	proc	near
 	mov	al,dma_write	; байт режима для записи ПДП (3 канал)
 	mov	cmd_block+0,write_cmd
 	jmp	dma_opn
disk_writet	endp

;---------------------------------------------------------------------
;	Проверка диска (АН=004Н)
;---------------------------------------------------------------------

disk_verft	proc	near
 	mov	cmd_block+0,chk_trk_cmd
 	jmp	ndma_opn
disk_verft	endp

;--------------------------------------------------------------------
;	Форматизация (АН=005Н,006Н,007Н)
;--------------------------------------------------------------------

fmt_trk proc	near	 	; форматизация дорожки (АН=005Н)
 	mov	cmd_block,fmttrk_cmd
 	jmp	short	fmt_cont
fmt_trk endp

fmt_bad proc	near	    ; форматизация неверной дорожки (АН=006Н)
 	mov	cmd_block,fmtbad_cmd
 	jmp	short	fmt_cont
fmt_bad endp

fmt_drv proc	near	 	; форматизация устройства (АН=007Н)
 	mov	cmd_block,fmtdrv_cmd
fmt_drv endp

fmt_cont:
 	mov	al,cmd_block+2
 	and	al,11000000b	; обнуление поля сектора
 	mov	cmd_block+2,al
 	jmp	ndma_opn

;--------------------------------------------------------------------
;	Получение параметров устройства (АН=008Н)
;--------------------------------------------------------------------

get_parmt_n	label	near
get_parmt	proc	far
 	push	ds	 	; сохранение регистров
 	push	es
 	push	bx

 	assume	ds:abs0
 	sub	ax,ax
 	mov	ds,ax	 	; установка сегмента
 	les	bx,hf_tbl_vec	; адрес таблицы параметров FD_TBL
 	assume	ds:data
 	mov	ax,dat
 	mov	ds,ax	 	; установка сегмента DATA

 	sub	dl,80h
 	cmp	dl,max_file	; проверка номера устройства
 	jae	g4t

 	call	setup_a  ; формирование 1-го байта упр. блока

 	call	sw2_offs ; формирование смещения для таблицы параметров
 	jc	g4t
 	add	bx,ax	; адрес таблицы параметров

 	mov	ax,es:[bx]	; максимальный номер цилиндра
 	sub	ax,2	; установить номер 0-N и зарезервировать
 	 	 	; последнюю дорожку для диагностики
 	mov	ch,al	; мл.разряды номера цилиндра в СН
 	and	ax,0300h	; старшие 2 бита цилиндра
 	shr	ax,1
 	shr	ax,1	; сдвиг на 2 разряда вправо (из АН в AL)
 	or	al,011h 	; максимальное число секторов
 	mov	cl,al	; в CL-ст.разряды номера цилиндра+число секторов

 	mov	dh,es:[bx][2]	; максимальный номер головки
 	dec	dh	 	; номер головки начинается с 0
 	mov	dl,hf_num	; число устройств
 	sub	ax,ax
g5t:
 	pop	bx	 	; сохранить регистры
 	pop	es
 	pop	ds
 	ret	2
g4t:
 	mov	diskw_status,init_fail	; неверная операция
 	mov	ah,init_fail	 	; код ошибки в АН
 	sub	al,al	 	 	; нулевые параметры
 	sub	dx,dx
 	sub	cx,cx
 	stc	 	 	 	; установить флажок ошибки
 	jmp	g5t
get_parmt	endp

;----------------------------------------------------------------------
;	Инициализация характеристик устройства
;----------------------------------------------------------------------
;	Таблица параметров НМД
;	Таблица составлена из следующих блоков:
;	(1 слово)-максимальное число цилиндров
;	(1 байт) -максимальное число головок
;	(1 слово)- начальный цилиндр уменьшения тока записи
;	(1 слово)- начальный цилиндр предкомпенсации
;	(1 байт) -максимальная длина блока данных ЕСС
;	(1 байт) -байт управления
;	 	бит 7-невозможность повторения доступа к диску
;	 	бит 6-невозможность повторения ЕСС
;	 	биты  5-3-нули
;	 	биты 2-0 -выбор устройства
;	(1 байт) -стандартное значение time_out
;	(1 байт) -значение time_out для форматизации устройства
;	(1 байт) -значение time_out для проверки устройства
;	(4 байта)-резерв для последующего использования
;
;	-чтобы определить набор параметров,строится таблица значений
;	 и помещается соответствующий вектор в прерывание 41H
;

;	Установка переключателей на плате
;
;	 	 	устройство 0	устройство 1
;	 	   ------------------------------------
;	включен    :	 	      / 	      :
;	 	   :   -1-    -2-     /   -3-	-4-   :
;	выключен   :	 	      / 	      :
;	 	   ------------------------------------
;
;	Таблица расшифровки:
;
;	 	1/3	2/4	вход таблицы
;	      -------------------------------
;	       вкл   : вкл   :	    0
;	       вкл   : выкл  :	    1
;	       выкл  : вкл   :	    2
;	       выкл  : выкл  :	    3
;	      -------------------------------

fd_tbl:

;-------Тип устройства 00 ( 10 Mb, г.Пенза )------------------------

 	dw	0cdh
 	db	06d
 	dw	080h
 	dw	0000d
 	db	0bh
 	db	05h
 	db	0ch
 	db	0b4h
 	db	028h
 	db	0,0,0,0

;-------Тип устройства 01 ( 20 Мб,615 цилиндров )-------------------

 	dw	0267h
 	db	04d
 	dw	0267h
 	dw	0300d
 	db	0bh
 	db	05h
 	db	028h
 	db	0e0h
 	db	042h
 	db	0,0,0,0

;-------Тип устройства 02 ( 20 Мб, 612 цилиндров )-----------------

 	dw	0612d
 	db	04d
 	dw	0612d
 	dw	0
 	db	0bh
 	db	05h
 	db	028h
 	db	0e0h
 	db	042h
 	db	0,0,0,0

;-------Тип устройства 03 --------------------------------------------

 	dw	0306d
 	db	04d
 	dw	0306d
 	dw	0000d
 	db	0bh
 	db	05h
 	db	0ch
 	db	0b4h
 	db	028h
 	db	0,0,0,0

init_drv	proc	near	; инициализация устройства

;------Для нулевого устройства---------------------------------------

 	mov	cmd_block+0,init_drv_cmd	; код операции
 	mov	cmd_block+1,0	; устройство 0,головка 0
 	call	init_drv_r ; считываем 8 байт из таблицы параметров
 	jc	init_drv_out

;-------Для первого устройства -------------------------------------

 	mov	cmd_block+0,init_drv_cmd	; код операции
 	mov	cmd_block+1,00100000b	; устройство 1,головка 0
 	call	init_drv_r  ; считываем 8 байт из таблицы параметров
init_drv_out:
 	ret
init_drv	endp
;------Считываем 8 байт из таблицы параметров-----------------------
init_drv_r	proc	near
 	assume	es:code
 	sub	al,al
 	call	command 	; выдача команды (6 байт)
 	jnc	b1t
 	ret
b1t:
 	push	ds
 	assume	ds:abs0
 	sub	ax,ax
 	mov	ds,ax	 	; установка сегмента
 	les	bx,hf_tbl_vec	; адрес таблицы параметров FD_TBL
 	pop	ds
 	assume	ds:data
 	call	sw2_offs	; сдвиг таблицы параметров
 	jc	b3t
 	add	bx,ax	 	; сдвиг начального адреса таблицы

;----Получение параметров устройства----------------------------

 	mov	di,1
 	call	init_drv_s	;запись первого байта из таблицы
 	 	 	 	;параметров (адрес BX+DI)-старший байт
 	 	 	 	;максимального номера цилиндра
 	jc	b3t

 	mov	di,0	 	; 0 байт из таблицы
 	call	init_drv_s	; младший байт номера цилиндра
 	jc	b3t

 	mov	di,2	 	; 2 байт из таблицы
 	call	init_drv_s	; максимальное число головок
 	jc	b3t

 	mov	di,4	 	; 4 байт из таблицы
 	call	init_drv_s	; ст.байт записи текущего цилиндра
 	jc	b3t

 	mov	di,3	 	; 3 байт из таблицы
 	call	init_drv_s	; мл.байт записи текущего цилиндра
 	jc	b3t

 	mov	di,6	 	; 6 байт из таблицы
 	call	init_drv_s	; ст.байт записи с предкомпенсацией
 	jc	b3t

 	mov	di,5	 	; 5 байт из таблицы
 	call	init_drv_s	;мл.байт записи с предкомпенсацией
 	jc	b3t

 	mov	di,7	 	; 7 байт из таблицы
 	call	init_drv_s	; максимальная длина блока данных ЕСС
 	jc	b3t

 	mov	di,8	 	; 8 байт из таблицы
 	mov	al,es:[bx + di] ; байт управления
 	mov	control_byte,al

 	sub	cx,cx
b5t:
 	call	port_1
 	in	al,dx	 	; считывание состояния
 	test	al,r1_iomode	; проверка режима ввода
 	jnz	b6t
 	loop	b5t
b3t:
 	mov	diskw_status,init_fail	; неверная операция
 	stc	 	 	 	; установить перенос
 	ret
b6t:
 	call	port_0	 	 	; порт данных
 	in	al,dx	 	 	; считывание байта состояния
 	and	al,2	 	 	; проверяется бит ошибки
 	jnz	b3t	 	 	; переход по ошибке
 	ret
 	assume	es:nothing
init_drv_r	endp

;-------Послать байт в контроллер------------------------------------

init_drv_s	proc	near
 	call	hd_wait_req	; ожидание установки запроса
 	jc	d1t	 	; нет запроса
 	call	port_0	 	; порт данных
 	mov	al,es:[bx + di] ; считывание байта из таблицы
 	out	dx,al	 	; запись байта в контроллер
d1t:
 	ret
init_drv_s	endp

;--------------------------------------------------------------------
;	Длинное считывание (АН=0АН)
;--------------------------------------------------------------------

rd_long 	proc	near
 	call	chk_long	; проверка длины блока
 	jc	g8t
 	mov	cmd_block+0,rd_long_cmd ; код операции
 	mov	al,dma_read	 	; 3 канал ПДП
 	jmp	short	dma_opn
rd_long 	endp

;----------------------------------------------------------------------
;	Длинная запись (АН=0ВН)
;---------------------------------------------------------------------

wr_long 	proc	near
 	call	chk_long	; проверка длины блока
 	jc	g8t
 	mov	cmd_block+0,wr_long_cmd ; код операции
 	mov	al,dma_write	; 3 канал ПДП
 	jmp	short	dma_opn
wr_long 	endp

chk_long	proc	near	; проверка длины блока
 	mov	al,cmd_block+4	; счетчик
 	cmp	al,080h 	; длинные считывание и запись от 1 до 79Н
 	cmc	; заменяет значение переноса на противоположное
 	ret
chk_long	endp

;-------------------------------------------------------------------
;	Установка (АН=0СН)
;-------------------------------------------------------------------

disk_seek	proc	near
 	mov	cmd_block,seek_cmd	; код операции
 	jmp	short	ndma_opn
disk_seek	endp

;--------------------------------------------------------------------
;	Считывание буфера сектора (АН=0ЕН)
;--------------------------------------------------------------------

rd_buff proc	near
 	mov	cmd_block+0,rd_buff_cmd ; код операции
 	mov	cmd_block+4,1	 	; один сектор
 	mov	al,dma_read	 	; 3 канал ПДП
 	jmp	short	dma_opn
rd_buff endp

;-------------------------------------------------------------------
;	Запись буфера сектора (АН=0FH)
;-------------------------------------------------------------------

wr_buff proc	near
 	mov	cmd_block+0,wr_buff_cmd ; код операции
 	mov	cmd_block+4,1	 	; один сектор
 	mov	al,dma_write	 	; 3 канал ПДП
 	jmp	short	dma_opn
wr_buff endp

;---------------------------------------------------------------------
;	Проверка готовности диска (АН=010Н)
;---------------------------------------------------------------------

tst_rdy proc	near
 	mov	cmd_block+0,tst_rdy_cmd ; код операции
 	jmp	short	ndma_opn
tst_rdy endp

;--------------------------------------------------------------------
;	Рекалибровка (АН=011Н)
;---------------------------------------------------------------------

hdisk_recal	proc	near
 	mov	cmd_block+0,recal_cmd	; код операции
 	jmp	short	ndma_opn
hdisk_recal	endp

;--------------------------------------------------------------------
;	Диагностика памяти контроллера (АН=012Н)
;--------------------------------------------------------------------

ram_diag	proc	near
 	mov	cmd_block+0,ram_diag_cmd
 	jmp	short	ndma_opn
ram_diag	endp

;---------------------------------------------------------------------
;	Диагностика устройства (АН=013Н)
;--------------------------------------------------------------------

chk_drv proc	near
 	mov	cmd_block+0,chk_drv_cmd
 	jmp	short	ndma_opn
chk_drv endp

;---------------------------------------------------------------------
;	Внутренняя диагностика контроллера (АН=014Н)
;--------------------------------------------------------------------

cntlr_diag	proc	near
 	mov	cmd_block+0,cntlr_diag_cmd
cntlr_diag	endp

;--------------------------------------------------------------------
;	Программы поддержки
;--------------------------------------------------------------------

ndma_opn:
 	mov	al,02h
 	call	command 	; получение команды
 	jc	g11
 	jmp	short	g3t
g8t:
 	mov	diskw_status,dma_boundary	; нарушение границы
 	ret
dma_opn:
 	call	dma_setupt	; установка операции ПДП
 	jc	g8t
 	mov	al,03h
 	call	command 	; получение команды
 	jc	g11
 	mov	al,03h
 	out	dma+10,al	; инициализация каналов
g3t:
 	in	al,021h
 	and	al,0dfh 	; разрешение прерываний диска
 	out	021h,al
 	call	wait_intt	; ожидание прерывания
g11:
 	call	error_chk	; обработка ошибок
 	ret

;---------------------------------------------------------------------
;	 	КОМАНДА
;	Посылает управляющий блок в контроллер
;	ВВОД
;
;	AL=маска регистра DMA/INT
;
;---------------------------------------------------------------------

command proc	near
 	mov	si,offset cmd_block ; начальный адрес для считывания
 	 	 	 	    ; блока команд
 	call	port_2
 	out	dx,al	; выработка сигнала выборки контроллера
 	call	port_3
 	out	dx,al	; установка маски DMA/INT
 	sub	cx,cx	; счетчик ожидания
 	call	port_1
wait_busy:
 	in	al,dx	; получение состояния контроллера
 	and	al,0fh	; выделение младших бит
 	cmp	al,r1_busy or r1_bus or r1_req	; проверка наличия
 	 	 	 	; сигналов от контроллера:
 	 	 	 	;	бит 3-занято
 	 	 	 	;	бит 2-команда/данные
 	 	 	 	;	бит 0-запрос
 	je	c1t
 	loop	wait_busy	; ожидание установки бит
 	mov	diskw_status,time_out
 	stc	 	 	; установка флажка по ошибке
 	ret
c1t:
 	cld	 	 	; сброс признака направления
 	mov	cx,6	 	; счетчик байт команды
cm3:	 	; получение 6 байт управляющего блока
 	call	port_0	 	; порт данных
 	lodsb	 	 	; получение байта команды
 	out	dx,al	 	; запись данных из CPU в контроллер
 	loop	cm3	 	; счетчик повторения равен 6

 	call	port_1	 	; порт состояния
 	in	al,dx	 	; считывание состояния контроллера
 	test	al,r1_req	; проверка бита запроса (R1_REQ)
 	jz	cm7
 	mov	diskw_status,bad_cntlr	; сбой контроллера
 	stc	 	 	; установить флажок переноса
cm7:
 	ret
command endp

;---------------------------------------------------------------------
;	Считывание байт уточненного состояния
;---------------------------------------------------------------------
;
;	Байт 0
;
;	бит  7	-адрес действителен,когда бит установлен
;	бит  6	-резерв,устанавливается в 0
;	биты 5-4-тип ошибки
;	биты 3-0-код ошибки
;
;	Байт 1
;
;	биты 7-6-нули
;	бит  5	-устройство (0-1)
;	биты 4-0-номер головки
;
;	Байт 2
;
;	биты 7-5-старшие 2 бита номера цилиндра
;	биты 4-0-номер сектора
;
;	Байт 3
;
;	биты 7-0-младшие биты номера цилиндра
;
;-------------------------------------------------------------------

error_chk	proc	near	; обработка ошибок
 	assume	es:data
 	mov	al,diskw_status ; состояние операции в AL
 	or	al,al	 	; проверить наличие ошибок
 	jnz	g21	 	; переход по ошибке
 	ret	 	 	; нет ошибок

;-------Считывание уточненного состояния----------------------------

g21:
 	mov	ax,dat
 	mov	es,ax	 	; установка сегмента
 	sub	ax,ax
 	mov	di,ax	 	; смещение для нулевого байта
 	mov	cmd_block+0,sense_cmd	; код операции
 	sub	al,al
 	call	command 	; выдача команды считывания состояния
 	jc	sense_abort	; переход по ошибке
 	mov	cx,4	 	; счетчик равен 4
g22:
 	call	hd_wait_req	; ожидание запроса
 	jc	g24
 	call	port_0	 	; порт данных
 	in	al,dx	 	; считывание байта состояния
 	db 26h,88h,45h,42h	; mov	es:hd_error[di],al
 	inc	di	 	; смещение для следующего байта
 	call	port_1
 	loop	g22	 	; счетчик повторения равен 4
 	call	hd_wait_req	; ожидание запроса
 	jc	g24	 	; нет запроса
 	call	port_0	 	; порт данных
 	in	al,dx	 	; байт состояния
 	test	al,2	 	; проверка бита ошибки
 	jz	stat_err	; нет ошибок при считывании б/с
sense_abort:
 	mov	diskw_status,sense_fail ; ошибки при считывании б/с
g24:
 	stc	 	 	; установить флажок переноса
 	ret
error_chk	endp

t_0	dw	type_0
t_1	dw	type_1
t_2	dw	type_2
t_3	dw	type_3

stat_err:
 	mov	bl,es:hd_error	; получение байта ошибки
 	mov	al,bl
 	and	al,0fh	 	; выделение кода ошибки(0-3 разр)
 	and	bl,00110000b	; выделение типа ошибки(4-5 разр)
 	sub	bh,bh	 	; обнулить ВН
 	mov	cl,3	 	; счетчик сдвига равен 3
 	shr	bx,cl	 	; сдвинуть вправо тип ошибки
 	jmp	word ptr cs:[bx + offset t_0]	; переход по типу
 	 	 	 	; ошибки:  000-тип 0
 	 	 	 	;	   010-тип 1
 	 	 	 	;	   100-тип 2
 	 	 	 	;	   110-тип 3
 	assume	es:nothing

type0_table	label	byte
 	db	0,bad_cntlr,bad_seek,bad_cntlr,time_out,0,bad_cntlr
 	db	0,bad_seek
type0_len	equ	$-type0_table
type1_table	label	byte
 	db	bad_ecc,bad_ecc,bad_addr_mark,0,record_not_fnd
 	db	bad_seek,0,0,data_corrected,bad_track
type1_len	equ	$-type1_table
type2_table	label	byte
 	db	bad_cmd,bad_addr_mark
type2_len	equ	$-type2_table
type3_table	label	byte
 	db	bad_cntlr,bad_cntlr,bad_ecc
type3_len	equ	$-type3_table

;-------Ошибки типа 0-----------------------------------------------

type_0:
 	mov	bx,offset type0_table	; адрес таблицы ошибок типа 0
 	cmp	al,type0_len	; проверить,определяется ли ошибка
 	jae	undef_err_l	; неопределяемая ошибка
 	xlat	cs:type0_table	; поиск таблицы
 	mov	diskw_status,al ; установить код ошибки
 	ret

;-------Ошибки типа 1----------------------------------------------

type_1:
 	mov	bx,offset type1_table	; адрес таблицы ошибок типа 1
 	mov	cx,ax	 	; сохранить код ошибки
 	cmp	al,type1_len	; проверить,определяется ли ошибка
 	jae	undef_err_l	; неопределяемая ошибка
 	xlat	cs:type1_table	; поиск таблицы
 	mov	diskw_status,al ; установить код ошибки
 	and	cl,08h	 	; выделить 3 бит
 	cmp	cl,08h	 	; коррекция ЕСС?
 	jnz	g3t0

;-------Получение длины пакета ошибок ЕСС----------------------------

 	mov	cmd_block+0,rd_ecc_cmd	; код операции
 	sub	al,al
 	call	command 	; получение 6 байт команды
 	jc	g3t0
 	call	hd_wait_req	; ожидание запроса
 	jc	g3t0
 	call	port_0	 	; порт данных
 	in	al,dx	 	; получить байт состояния
 	mov	cl,al	 	; запомнить б/с в CL
 	call	hd_wait_req	; ожидание запроса
 	jc	g3t0
 	call	port_0	 	; порт данных
 	in	al,dx	 	; получить байт состояния
 	test	al,01h	 	; проверить 0 бит
 	jz	g3t0	 	; 0 бит равен 1-ошибка
 	mov	diskw_status,bad_cntlr	; сбой контроллера
 	stc	 	 	; установить флажок переноса
g3t0:
 	mov	al,cl	 	; получить байт состояния в AL
 	ret

;-------Ошибки типа 2------------------------------------------------

type_2:
 	mov	bx,offset type2_table	; адрес таблицы ошибок типа 2
 	cmp	al,type2_len	; проверить,определяется ли ошибка
 	jae	undef_err_l	 	; неопределяемая ошибка
 	xlat	cs:type2_table	 	; поиск таблицы
 	mov	diskw_status,al 	; установить код ошибки
 	ret

;-------Ошибки типа 3------------------------------------------------

type_3:
 	mov	bx,offset type3_table	; адрес таблицы ошибок типа 3
 	cmp	al,type3_len	; проверить,определяется ли ошибка
 	jae	undef_err_l	 	; неопределяемая ошибка
 	xlat	cs:type3_table	 	; поиск таблицы
 	mov	diskw_status,al 	; установить код ошибки
 	ret

undef_err_l:
 	mov	diskw_status,undef_err	; наличие неопределяемой ошибки
 	ret

hd_wait_req	proc	near	; ожидание установки запроса
 	push	cx
 	sub	cx,cx	 	; установить счетчик
 	call	port_1
l1:
 	in	al,dx	 	; считывание состояния оборудования
 	test	al,r1_req	; проверка наличия запроса
 	jnz	l2	 	; бит запроса установлен
 	loop	l1	 	; ожидание запроса
 	mov	diskw_status,time_out	; запрос не установлен
 	stc	 	 	; установить флажок переноса
l2:
 	pop	cx
 	ret
hd_wait_req	endp

;-------------------------------------------------------------------
;	Установка ПДП
;------------------------------------------------------------------
;
;	ВВОД
;
;	(AL)   -байт режима для ПДП
;	(ES:BX)-адрес для данных считывания/записи
;----------------------------------------------------------------------
dma_setupt	proc	near
 	push	ax	; сохраняем байт режима для ПДП
 	mov	al,cmd_block+4	; получаем значение счетчика
 	cmp	al,81h	 	; 80Н-максимальное число секторов
 	pop	ax	 	; байт режима
 	jb	j1t
 	stc	 	; устанавливаем флажок переноса по ошибке
 	ret
j1t:
 	push	cx
 	cli
 	out	dma+12,al
 	push	ax
 	pop	ax
 	out	dma+11,al	; вывод байта режима в порт 0В ПДП

;-------Генерация физического адреса----------------------------------

 	mov	ax,es	 	; получить значение ES
 	mov	cl,4	 	; установить счетчик сдвига
 	rol	ax,cl	; циклически сдвинуть на 4 разр. содержимое АХ
 	mov	ch,al	; получить старшую часть ES в СН(4 ст.бита)
 	and	al,0f0h 	; обнулить младшие разряды AL
 	add	ax,bx	; сложить значение смещения(ВХ) со сдвинутым
 	 	 	; значением сегментного регистра
 	jnc	j33t	; проверка наличия переноса
 	inc	ch	; перенос означает,что 4 ст.бита должны быть
 	 	 	; увеличены на 1
j33t:
 	push	ax	; сохранить физический адрес
 	out	dma+6,al    ; вывод первого байта адреса в порт 06 ПДП
 	mov	al,ah	    ; получить второй байт адреса
 	out	dma+6,al    ; вывод второго байта адреса в порт 06 ПДП
 	mov	al,ch	    ; получить 4 старших бита адреса
 	and	al,0fh	    ; выделение младших бит AL
 	out	dma_high,al ; вывод 4 ст.битов в регистр страницы

;-------Определение счетчика-----------------------------------------

 	mov	al,cmd_block+4	; получение числа блоков
 	shl	al,1
 	dec	al
 	mov	ah,al
 	mov	al,0ffh

;-------Длинное считывание и длинная запись-----------------------------

 	push	ax	 	; сохранить счетчик байт
 	mov	al,cmd_block+0	; получение кода операции
 	cmp	al,rd_long_cmd	; длинное считывание ?
 	je	add4
 	cmp	al,wr_long_cmd	; длинная запись?
 	je	add4
 	pop	ax	 	; восстановление счетчика
 	jmp	short	j20t
add4:
 	pop	ax	 	; восстановление счетчика
 	mov	ax,516d 	; 512 байтов + 4 байта ЕСС
 	push	bx	 	; сохранить регистр
 	sub	bh,bh
 	mov	bl,cmd_block+4	; получение числа блоков
 	push	dx
 	mul	bx	 	; вычисление количества байт
 	pop	dx
 	pop	bx
 	dec	ax	 	; счет от 0 до N
j20t:
 	push	ax	 	; сохранить значение счетчика
 	out	dma+7,al	; вывод мл.байта счетчика в порт 07 ПДП
 	mov	al,ah	 	; получить старший байт счетчика
 	out	dma+7,al	; вывод ст.байта счетчика в порт 07 ПДП
 	sti	 	; установить признак разрешения прерывания
 	pop	cx	 	; восстановить значение счетчика
 	pop	ax	 	; восстановить значение адреса
 	add	ax,cx	 	; проверка границы области 64К
 	pop	cx
 	ret
dma_setupt	endp

;---------------------------------------------------------------------
;	Ожидание прерывания
;--------------------------------------------------------------------

wait_intt	proc	near
 	sti	 	; установить признак разрешения прерывания
 	push	bx	; сохранить регистры
 	push	cx
 	push	es
 	push	si
 	push	ds
 	assume	ds:abs0
 	sub	ax,ax
 	mov	ds,ax	 	; установка сегмента
 	les	si,hf_tbl_vec	; адрес таблицы параметров FD_TBL в SI
 	assume	ds:data
 	pop	ds	 	; восстановление сегмента DATA

;-------Установка времени ожидания (time_out)-------------------------

 	sub	bh,bh
 	mov	bl,byte ptr es:[si][9]	; стандартный time_out из FD_TBL
 	mov	ah,cmd_block	 	; код операции в АН
 	cmp	ah,fmtdrv_cmd	 	; форматизация устройства?
 	jnz	w5
 	mov	bl,byte ptr es:[si][0ah]  ; time_out для форматизации
 	jmp	short	w4
w5:
 	cmp	ah,chk_drv_cmd	 	; проверка устройства?
 	jnz	w4
 	mov	bl,byte ptr es:[si][0bh]  ; time_out для проверки
w4:
 	sub	cx,cx	 	; установка счетчика

;-------Ожидание прерывания------------------------------------------

w1:
 	call	port_1	 	; порт состояния
 	in	al,dx	 	; считывание состояния контроллера
 	and	al,020h 	; 5 бит -запрос на прерывание
 	cmp	al,020h 	; 5 бит установлен?
 	jz	w2
 	loop	w1	 	; счетчик ожидания равен 64К
 	dec	bx
 	jnz	w1
 	mov	diskw_status,time_out
w2:
 	call	port_0	 	; порт данных
 	in	al,dx	 	; считывание байта состояния
 	and	al,2	 	; выделение бита ошибки
 	or	diskw_status,al ; сохранить ошибку
 	call	port_3
 	xor	al,al
 	out	dx,al	 	; сброс маски прерывания
 	pop	si	 	; восстановление регистров
 	pop	es
 	pop	cx
 	pop	bx
 	ret
wait_intt	endp

hd_int	proc	near	 	; прерывание НМД
 	push	ax
 	mov	al,eoi	 	; конец прерывания
 	out	int_ctl_port,al
 	mov	al,07h	 	; установить режим ПДП неработоспособным
 	out	dma+10,al	; запись в порт 10 ПДП
 	in	al,021h
 	or	al,020h
 	out	021h,al
 	pop	ax
 	iret
hd_int	endp

;----------------------------------------------------------------------
;	Порты: выработка значений портов по значению сдвига порта
;----------------------------------------------------------------------

port_0	proc	near
 	mov	dx,hf_port	; базовое значение порта (320Н)
 	push	ax
 	sub	ah,ah
 	mov	al,port_off	; значение сдвига адреса порта
 	add	dx,ax	 	; формирование адреса порта
 	pop	ax
 	ret
port_0	endp

port_1	proc	near
 	call	port_0
 	inc	dx
 	ret
port_1	endp

port_2	proc	near
 	call	port_1
 	inc	dx
 	ret
port_2	endp

port_3	proc	near
 	call	port_2
 	inc	dx
 	ret
port_3	endp

;-------------------------------------------------------------------
;-------Определить сдвиг таблицы параметров----------------------------

sw2_offs	proc	near
 	call	port_2
 	in	al,dx	; считывание конфигурации переключателей
 	push	ax	; запомнить переключатели
 	call	port_1	; порт состояния
 	in	al,dx	; считывание состояния контроллера
 	and	al,2	; проверяется бит 1
 	pop	ax	; восстановление переключателей
 	jnz	sw2_offs_err
 	mov	ah,cmd_block+1	; устройство + головка
 	and	ah,00100000b	; устройство 0 или 1
 	jnz	sw2_and
 	shr	al,1	 	; в AL -конфигурация переключателей
 	shr	al,1	 	; сдвиг на 2 разряда вправо
sw2_and:
 	and	al,011b 	; сохранить 2 младших разряда
 	mov	cl,4	 	; установка счетчика сдвига
 	shl	al,cl	 	; сдвиг на 4 разр.-определение смещения
 	 	 	 	;	00Н-тип 0
 	 	 	 	;	10Н-тип 1
 	 	 	 	;	20Н-тип 2
 	 	 	 	;	30Н-тип 3
 	sub	ah,ah
 	ret
sw2_offs_err:
 	stc	 	; установить флажок переноса по ошибке
 	ret
sw2_offs	endp

 	db	'08/16/82'

end_address	label	byte
;   Изменения для НМД

 	assume cs:code,ss:code,es:abs0,ds:data

rom_check	proc	near
 	mov	ax,dat
 	mov	es,ax
 	sub	ah,ah
 	mov	al,[bx+2]
 	mov	cl,09h
 	shl	ax,cl
 	mov	cx,ax
 	push	cx
 	mov	cx,4
 	shr	ax,cl
 	add	dx,ax
 	pop	cx
 	call	ros_checksum_cnt
 	jz	rom_check_1
 	call	rom_err
 	jmp	rom_check_end
rom_check_1:
 	push	dx
 	assume es:data
 	mov	es:io_rom_init,0003h
 	mov	es:io_rom_seg,ds
 	call	dword ptr es:io_rom_init
 	assume es:abs0
 	pop	dx
rom_check_end:
 	ret
rom_check	endp



rom_err   proc	near
 	push	dx
 	push	ax
 	mov	dx,ds
 	cmp	dx,0c800h
 	jl	rom_err_beep
 	call	prt_seg
 	mov	si,offset f3a
 	call	e_msg
rom_err_end:
 	pop	ax
 	pop	dx
 	ret
rom_err_beep:
 	mov	dx,0102h
 	call	err_beep
 	jmp	short rom_err_end
rom_err endp



f3a	db	'ROM',13,10


prt_seg proc	near
 	mov	al,dh
 	call	xpc_byte
 	mov	al,dl
 	call	xpc_byte
 	mov	al,'0'
 	call	prt_hex
 	mov	al,' '
 	call	prt_hex
 	ret
prt_seg endp


xpc_byte  proc	near
 	push	ax
 	mov	cl,4
 	shr	al,cl
 	call	xlat_pr
 	pop	ax
 	and	al,0fh


xlat_pr proc	near
 	add	al,090h
 	daa
 	adc	al,040h
 	daa
 	call	prt_hex
 	ret
xlat_pr endp
xpc_byte endp



e_msg	proc	near
 	mov	bp,si
 	call	p_msg1
 	ret
e_msg	endp



p_msg1	proc	near
g12a:
 	mov	al,cs:[si]
 	inc	si
 	push	ax
 	call	prt_hex
 	pop	ax
 	cmp	al,10
 	jne	g12a
 	ret
p_msg1	endp


ros_checksum_cnt  proc	near
 	xor	al,al
c26k:
 	add	al,ds:[bx]
 	inc	bx
 	loop	c26k
 	or	al,al
 	ret
ros_checksum_cnt  endp
;-----------------------------------------------------------
;
;     INT 10  (AH=13H)
;
;     Пересылка цепочки символов
;
;     ES:BP  - начальный адрес цепочки символов
;     CX     - количество символов
;     DH,DL  - строка и колонка для начала записи
;     BH     - номер страницы
;
;     AL=0:
;	       цепочка = (символ,символ,символ,...)
;	       BL = атрибут
;	       курсор не движется
;     AL = 1:
;	       цепочка = (символ,символ,символ,...)
;	       BL = атрибут
;	       курсор движется
;     AL =2:
;	       цепочка = (символ,атрибут,символ,атрибут,...)
;	       курсор не движется
;     AL = 3:
;	       цепочка = (символ,атрибут,символ,атрибут,...)
;	       курсор движется
;
;-----------------------------------------------------
byxod1: jmp	byxod
ah13:


 	push	bp
 	cmp	al,04
 	jnb	byxod1
 	cmp	cx,0
 	je	byxod1
 	push	bx
 	mov	bl,bh	; номер страницы
 	sub	bh,bh
 	shl	bx,1
 	mov	si,word ptr [bx + offset cursor_posn]	; si=позиция
 	 	 	; курсора для заданной страницы
 	pop	bx
 	push	si
 	push	ax
 	mov	ax,200h ; установить позицию курсора
 	int	10h
 	pop	ax
rdcimb: push	cx
 	push	bx	; номер активной страницы
 	push	ax
 	xchg	al,ah
 	mov	al,es:[bp+0]	; считать в AL символ строки
 	inc	bp
 	cmp	al,0dh	; возврат каретки
 	jz	zaptel
 	cmp	al,0ah	; граница поля
 	jz	zaptel
 	cmp	al,08	; возврат на одну позицию
 	jz	zaptel
 	cmp	al,07	; звуковой сигнал
 	jz	zaptel
 	mov	cx,0001
 	cmp	ah,2
 	jnb	picat
piczn:	mov	ah,09	; писать знак/атрибут
 	int	10h
 	inc	dl	; колонка
 	cmp	dl,byte ptr crt_cols
 	jnb	pockol
 	jmp	ustkur
picat:	mov	bl,es:[bp+0]
 	inc	bp
 	jmp	piczn
zaptel: mov	ah,0eh	; запись телетайпа
 	int	10h
 	mov	bl,bh
 	sub	bh,bh
 	shl	bx,1
 	mov	dx,word ptr [bx + offset cursor_posn]
 	jmp	bozin
pockol: cmp	dh,24h	; последняя строка ?
 	jnz	nepocl
 	mov	ax,0e0ah	; перевод строки
 	int	10h
 	dec	dh
nepocl: inc	dh
 	sub	dl,dl
ustkur: mov	ax,200h ; установить курсор
 	int	10h
bozin:	pop	ax
 	pop	bx
 	pop	cx
 	loop	rdcimb
 	pop	dx
 	cmp	al,01
 	jz	byxod
 	cmp	al,03
 	jz	byxod
 	mov	ax,200h
 	int	10h	; установить	старую позицию курсора
byxod:	pop	bp
 	jmp	video_return
 	iret

;=============================================================
; ПОДДЕРЖКА АДАПТЕРОВ СТЫКА С2 В АСИНХРОННОМ РЕЖИМЕ ПО ОПРОСУ
; МОДУЛЬ ПОЛУЧАЕТ УПРАВЛЕНИЕ ПО КОМАНДЕ  INT  14H
;=============================================================
;  (AH) = 00h - инициализировать адаптер
;	(AL) - параметры:
;	   7	 6	5      4      3       2      1	   0
;	   ---скорость---      контроль    стоп-бит  -длина-
;	   000 - 110	       Х0-нет	    0 - 1    10 - 7 бит
;	   001 - 150	       01-нечет     1 - 2    11 - 8 бит
;	   010 - 300	       11-чет
;	   011 - 600
;	   100 - 1200
;	   101 - 2400
;	   110 - 4800
;	   111 - 9600
;	(DX) - номер адаптера стыка С2 (0,1)
;     ВЫХОД:
;	 ----------- (AH) ------------
;	 7   6	 5   4	 3   2	 1   0
;	 |   |	 |   |	 |   |	 |   |___ приемник содержит данные
;	 |   |	 |   |	 |   |	 |_______ переполнение
;	 |   |	 |   |	 |   |___________ ошибка четности
;	 |   |	 |   |	 |_______________ ошибка стоп-бита
;	 |   |	 |   |___________________ пауза
;	 |   |	 |_______________________ адаптер готов к передаче
;	 |   |___________________________ передатчик пуст
;	 |_______________________________ тайм-аут
;
;	 ------------- (AL) ----------
;	 7   6	 5   4	 3   2	 1   0
;	 |   |	 |   |	 0   0	 0   0
;	 |   |	 |   |	 |   |	 |   |___ изменен бит 4
;	 |   |	 |   |	 |   |	 |_______ изменен бит 5
;	 |   |	 |   |	 |   |___________ изменен бит 6
;	 |   |	 |   |	 |_______________ изменен бит 7
;	 |   |	 |   |___________________ готов к передаче (цепь 106 вкл)
;	 |   |	 |_______________________ аппаратура передачи данных готова
;	 |   |	 	 	 	  (цепь 107 вкл)
;	 |   |___________________________ индикатор вызова (цепь 125 вкл)
;	 |_______________________________ детектор линейного
;	 	 	 	 	  сигнала (цепь 109 вкл)
;	 ЗАМЕЧАНИЕ: Если бит 7 в AH равен 1, значение остальных бит в AH
;	 	    непредсказуемо
;  (AH) = 01h - передать символ
;	(AL) - символ для передачи
;	(DX) - номер адаптера стыка С2 (0,1)
;     ВЫХОД:
;	(AL) сохраняется
;	(AH) - как при инициализации ((AH) = 0)
;  (AH) = 02h - принять символ из канала связи
;	(DX) - номер адаптера стыка С2 (0,1)
;     ВЫХОД:
;	(AL) - принятый символ
;	(AH) - как при инициализации ((AH) = 0)
;  (AH) = 03h - уточнить состояние
;	(DX) - номер адаптера стыка С2 (0,1)
;     ВЫХОД:
;	(AL) и (AH) - как при инициализации ((AH) = 0)
;  (AH) = FFh - расширенная инициализация адаптера стыка С2
;	-------------- (CL) ---------------
;	7    6	  5    4    3	 2    1   0
;	0    0	  0    0    ----скорость----
;	 	 	 	 0-50
;	 	 	 	 1-75
;	 	 	 	 2-100
;	 	 	 	 3-110
;	 	 	 	 4-150
;	 	 	 	 5-200
;	 	 	 	 6-300
;	 	 	 	 7-600
;	 	 	 	 8-1200
;	 	 	 	 9-2400
;	 	 	 	 A-4800
;	 	 	 	 B-6400
;	 	 	 	 C-9600
;	 	 	 	 D-19200
;	------------------- (AL) -----------------------
;	7     6     5	   4	  3	  2	 1     0
;	стоп-бит    контроль	  --длина--	 1     0
;	 01-1	    Х0 - нет	  00 - 5 бит
;	 10-1.5     01 - нечет	  01 - 6 бит
;	 11-2	    11 - чет	  10 - 7 бит
;	 	 	 	  11 - 8 бит
;	(DX) - номер адаптера стыка С2 (0,1)
;     ВЫХОД:
;	(AL) и (AH) - как при инициализации ((AH) = 0)
;	 ЗАМЕЧАНИЕ: Эта функция используется только для ЕС1840, ЕС1841
;	 	    для адаптеров стыка С2 в модуле ЕС1840.0004
 	assume	cs:code,ds:data
rs232_io	proc	far
 	STI
 	push	ds
 	push	bx
 	push	cx
 	push	dx
 	push	si
 	cmp	ah,0	; проверить вид инициализации (если есть)
 	jne	v0ok	; обойти преобразование
;------- преобразовать (AX) к виду как при (AH) = FFh -----------
;------ постоянные значения
 	mov	ah,01001010b
;------ длина
 	test	al,1
 	jz	v0p1
 	or	ah,00000100b
;------стоп-биты
v0p1:
 	test	al,4
 	jz	v0p2
 	or	ah,80h
;------ контроль
v0p2:
 	test	al,00001000b
 	jz	v0p3
 	or	ah,00010000b
 	test	al,00010000b
 	jz	v0p3
 	or	ah,00100000b
;------ скорость и номер функции
v0p3:
 	mov	cl,5
 	shr	al,cl
 	sub	bh,bh
 	mov	bl,al
 	mov	cl,cs: z0b[bx]
 	mov	al,ah
 	mov	ah,0ffh
;========================================================
v0ok:
;-------- загрузить базовый адрес адаптера -------------
 	mov	si,dx
 	shl	si,1
 	mov	dx,dat
 	mov	ds,dx
 	mov	dx,[si]
 	or	dx,dx
 	jnz	v00
 	jmp	v0to	; недействительный адаптер
;------ выбрать функцию --------------------------------
v00:
 	dec	ah
 	jnz	$+5
 	jmp	v0b	; передать символ
 	dec	ah
 	jnz	$+5
 	jmp	v0c	; принять символ
 	dec	ah
 	jnz	$+5
 	jmp	v0d	; уточнить состояние
 	cmp	ah,0fch
 	je	v0a	; расширенная инициализация
 	jmp	v0to	; недействительная функция
;============================================================
;------ функция FFh - расширенная инициализация ---------
v0a:
 	push	ax
;------ записать управляющее слово адаптера
 	add	dx,7
 	mov	al,8ah
 	out	dx,al	;упр. слово --> 2/3ff
;----- замаскировать все прерывания адаптера
 	dec	dx
 	mov	al,8
 	out	dx,al	;маски запрета прерываний --> 2/3fe
;------ выбрать таймер
 	sub	dx,2
 	mov	bx,dx
 	mov	al,80h
 	mov	dh,3
 	CLI
 	out	dx,al	;выбор таймера --> 3fc
 	mov	dx,bx
;------ определить смещение делителя скорости
 	shl	cl,1
 	sub	ch,ch
 	mov	bx,cx
;----- записать управляющее слово таймера
 	mov	cx,dx
 	mov	dx,3fbh
 	mov	al,36h
 	cmp	ch,3
 	je	v0a1
 	mov	al,76h
v0a1:
 	out	dx,al	;упр. слово --> 3fb
;------ записать делитель скорости
 	sub	dx,3
 	cmp	ch,3
 	je	v0a2
 	inc	dx
v0a2:
 	mov	ax,cs: z0a[bx]
 	out	dx,al	;младший байт делителя --> 3f8/3f9
 	call	v0z	;задержка
 	mov	al,ah
 	out	dx,al	;старший байт делителя --> 3f8/3f9
 	mov	dx,cx
 	cmp	dh,3
 	je	v0a3
;------ восстановить режим адаптера в 3fc
 	mov	dh,3
 	mov	al,8
 	out	dx,al	;режим --> 3fc
 	mov	dh,2
v0a3:
;------ установить контроллер прерываний
 	mov	al,0A4h
 	in	al,21h
 	mov	ah,al
 	mov	al,0a4h
 	out	21h,al	; открыть маски IRQ3,IRQ4
 	mov	al,0ch
 	out	20h,al	; уст. режим POLL
 	nop
 	nop
 	nop
 	in	al,20h	; сбр. режима POLL
 	nop
 	nop
 	nop
 	mov	al,20h	; СБРОС ложного прерывания
 	out	20h,al
 	mov	al,ah
 	out	21h,al
 	STI
;------ сбросить контроллер адаптера
 	mov	al,40h
 	out	dx,al	;сброс --> 2/3fc
;------ записать режим адаптера
 	call	v0z	;задержка
 	mov	al,8
 	out	dx,al	;режим --> 2/3fc
;------ загрузить режим в передающую микросхему
 	sub	dx,3
 	pop	ax
 	out	dx,al	;режим --> 2/3f9
;------ записать команду ПЕРЕДАЧА + ПРИЁМ
 	call	v0z	;задержка
 	mov	al,00000101b
 	out	dx,al
;------ выход
 	sub	ah,ah
 	jmp	v0d	;уточнить состояние
;=================================================================
;------ функция 1 - передать символ ------------------------------
v0b:
 	sub	ah,ah
 	push	ax
;------ записать команду ВКЛ. Ц.108 + ВКЛ. Ц.105 + ПЕРЕДАЧА + ПРИЁМ
 	inc	dx
 	mov	al,00100111b
 	out	dx,al
;------ проверить готовность адаптера к передаче + ВКЛ.Ц.107 + ВКЛ.Ц.106
 	sub	cx,cx
 	call	v0z	;задержка
v0b1:
 	in	al,dx	;баит состояния 1 <-- 2/3f9
 	and	al,81h
 	mov	bl,al
 	inc	dx
 	in	al,dx	;байт состояния 2 <-- 2/3fa
 	and	al,01h
 	shl	al,1
 	or	al,bl
 	cmp	al,81h
 	je	v0b2
 	dec	dx
 	loop	v0b1
 	 	 	;условия(е) не выполнены(о)
 	pop	ax
 	jmp	short	v0to
;------ передать байт
v0b2:
 	dec	dx
 	dec	dx
 	pop	ax
 	out	dx,al	;байт данных --> 2/3f8
;------ выход
 	jmp	short	v0end
;==============================================================
; передача управления вызывающей программе
;------ выход по тайм-ауту
v0to:
 	or	ah,80h
;------ все другие выходы, кроме приема
v0end:
 	call	v0e	; уточнить состояние адаптера
v0end1: 	 	; выход из функции приема
 	pop	si
 	pop	dx
 	pop	cx
 	pop	bx
 	pop	ds
 	iret
;==============================================================
;------ функция 2 - принять символ ----------------------------
v0c:
 	sub	ah,ah
;------ записать команду ВКЛ. Ц.108 + ПЕРЕДАЧА + ПРИЁМ
 	inc	dx
 	mov	al,00000111b
 	out	dx,al
;------ проверить готовность приемника + ВКЛ. Ц.107
 	sub	cx,cx
 	call	v0z	;задержка
v0c1:
 	in	al,dx	;байт состояния 1 <-- 2/3f9
 	and	al,82h
 	cmp	al,82h
 	je     v0c2
 	loop	v0c1
 	 	 	;условия(е) не выплнены(о)
 	sub	al,al
 	jmp	short	v0to
;------ прочитать байт из приемника
v0c2:
 	dec	dx
 	in	al,dx	;2/3f8 <-- байт из приемникa
;------ уточнить состояние адаптера
 	call	v0e
 	and	ah,00011110b
;------ сбросить триггеры ошибок приема
 	inc	dx
 	mov	cl,al
 	mov	al,00010110b
 	out	dx,al	;команда --> 2/3f9
 	mov	al,cl
;------ выход
 	jmp	short	v0end1
;=============================================================
;------ уточнить состояние ---------------------------------
v0d:
;------ прочитать состояние модема в AL
 	sub	ah,ah
 	mov	dx,[si] ; база адаптера
 	inc	dx
 	in	al,dx	;байт состояния 1 <-- 2/3f9
 	test	al,10000000b
 	jz	$+5
 	or	ah,00100000b	; цепь 107 вкл.
 	inc	dx
 	in	al,dx	;байт состояния 2 <-- 2/3fa
 	out	dx,al	;сбросить бит 3
 	test	al,00000001b
 	jnz	$+5
 	or	ah,00010000b	; цепь 106 вкл.
 	test	al,00000010b
 	jnz	$+5
 	or	ah,10000000b	; цепь 109 вкл.
 	test	al,00001000b
 	jz	$+5
 	or	ah,01000000b	; цепь 125 вкл.
;------ установить биты изменения
 	mov	dx,[si] ; база адаптера
 	mov	al,ah
 	xchg	al,stat_offset[si]
 	xor	al,ah
 	mov	cl,4
 	shr	al,cl
 	or	al,ah
;------ выход
 	sub	ah,ah
 	jmp	short	v0end
;=============================================================
;------ прочитать состояние адаптера в AH --------------------
v0e	proc	near
 	push	dx
 	push	ax
 	sub	ah,ah
 	mov	dx,[si] ; база адаптера
 	inc	dx
 	in	al,dx	;байт состояния 1 <-- 2/3f9
 	test	al,00000001b
 	jz	$+5
 	or	ah,00100000b	; передатчик пуст
 	test	al,00000010b
 	jz	$+5
 	or	ah,00000001b	; приемник содержит данные
 	test	al,00000100b
 	jz	$+5
 	or	ah,01000000b	; адаптер пуст
 	test	al,00001000b
 	jz	$+5
 	or	ah,00000100b	; ошибка четности
 	test	al,00010000b
 	jz	$+5
 	or	ah,00000010b	; переполнение
 	test	al,00100000b
 	jz	$+5
 	or	ah,00001000b	; ошибка стоп-бита
 	test	al,01000000b
 	jz	$+5
 	or	ah,00010000b	; пауза
 	pop	dx
 	or	ah,dh	 	; тайм-аут
 	mov	al,dl	 	; восстановить AL
 	pop	dx
 	ret
v0e	endp
;=============================================================
;------ подпрограмма задержки процессора ---------------------
v0z	proc	near
 	ret
v0z	endp
;=============================================================
;------ делители скорости
z0a	dw	1536,1024,768,698,512,384,256,128,64,32,16,12,8,4
;------ для преобразования форматов
z0b	db	3h,4h,6h,7h,8h,9h,0Ah,0Ch
rs232_io	endp
     assume cs:code,ds:data
;------------------------------------------------------
;
;      Загрузить знакогенератор пользователя  (INT 10H, AH=11H)
;
;  На входе:
;
;	ES:BP  -  адрес таблицы, сформированной пользователем
;	CX     -  количество передаваемых символов
;	BL     -  код символа, начиная с которого загружается
;	 	  таблица пользователя
;	BH     -  количество байт на знакоместо
;	DL     -  идентификатор таблицы пользователя
;	AL     -  режим
;	 	  AL=0	 -  загрузить знакогенератор
;	 	  AL=1	 -  выдать идентификатор таблицы
;
;	 	  AL=3	 -  загрузить вторую половину знакогенератора:
;	 	 	    BL=0 - загрузить вторую половину знакогене-
;	 	 	    ратора из ПЗУ кодовой таблицы с русским
;	 	 	    алфавитом,
;	 	 	    BL=1 - загрузить вторую половину знакогене-
;	 	 	    ратора из ПЗУ стандартной кодовой таблицей
;	 	 	    ASCII (USA)
;
;   На выходе:
;
;	AH   -	количество байт на знакоместо
;	AL   -	идентификатор таблицы пользователя
;
;	CF=1   -   операция завершена успешно
;
;--------------------------------------------------
   znak:
 	xchg	dl,dh
 	xchg	bl,dh
 	push	bp
 	cmp	al,0
 	mov	ax,dat
 	mov	ds,ax
 	jnz	wid
 	mov	dh,bh
 	mov	idnpol,dx
 	push	cx
 	cmp	bh,8
 	jbe	zagr8
;
;
;      Загрузка знакогенератора черно-белого дисплея
;
;
 	mov	ax,0dc00h
 	mov	ds,ax	; база знакогенератора
 	mov	cl,5
 	mov	dx,3b8h
zgr:

 	mov	al,0
 	out	dx,al
 	mov	ax,0	; смещение в знакогенераторе
 	mov	al,bl
 	shl	ax,cl
 	mov	di,ax
 	pop	cx
kolby:	mov	bl,bh	; число байт на знакоместо
zapby:	mov	al,es:[bp]    ; считывание байта из таблицы
 	mov	byte ptr [di],al   ; запись байта в знакогенератор
 	inc	di
 	inc	bp
 	dec	bl
 	jnz	zapby
 	loop	kolby
 	mov	ax,dat
 	mov	ds,ax
 	cmp	bh,8
 	jbe	gr8
 	mov	ah,29h
weport: mov	al,ah
 	out	dx,al
wid:

 	mov	ax,idnpol
 	pop	bp
 	stc
 	jmp	video_return
;
;
;    Загрузка знакогенератора цветного дисплея
;
;
zagr8:	mov	ax,0b800h
 	mov	ds,ax	; база знакогенератора
 	mov	cl,3
 	mov	dx,3dfh
 	mov	al,01
 	out	dx,al
 	mov	dx,3d8h
 	jmp	zgr
gr8:	mov	dx,3dfh
 	mov	al,0
 	out	dx,al
 	mov	dx,3d8h
 	mov	bl,crt_mode
 	mov	bh,0
 	mov	ah,cs:[bx+offset m7]
 	jmp	weport

;
;__________________________________
;
;   Загрузка знакогенератора цветного дисплея
;
;__________________________________
;
zagrcw: mov	ax,0b800h
 	mov	es,ax
 	mov	al,1
 	mov	dx,3dfh
 	out	dx,al	   ; порт 3DF = 1
 	mov	dx,3d8h
 	in	al,dx
 	mov	bl,al	   ; сохранить значение порта 3D8
 	mov	al,0
 	out	dx,al	   ; порт 3D8 = 0
 	xor	di,di
 	mov	cx,400h
 	xor	ax,ax
 	cld
 	rep	stosw
 	mov	si,offset crt_char_gen
 	mov	cx,400h
 	xor	di,di
zn:	mov	al,cs:[si]
 	mov	byte ptr es:[di],al
 	inc	si
 	inc	di
 	loop	zn
 	mov	cx,400h    ; счетчик для 128 символов русского алфавита
 	mov	si,offset crt_char_rus
trus:	mov	al,cs:[si]
 	mov	byte ptr es:[di],al
 	inc	si
 	inc	di
 	loop	trus
 	mov	al,0
 	mov	dx,3dfh
 	out	dx,al	   ; порт 3DF = 0
 	mov	dx,3d8h
 	mov	al,bl
 	out	dx,al	   ; восстановить значение порта 3D8
 	jmp	kzagr
;
;
;*************************************************
;   Знакогенератор графический русский
;************************************************


crt_char_rus	label	byte

;**************************************************
;	 	 	 	 	 	 **
;  Новый знакогенератор для ЕС1841	 	 **
;	 	 	 	 	 	 **
;**************************************************
;
;
 	 	db 018h,018h,0ffh,000h,0ffh,000h,000h,000h
 	 	db 06ch,06ch,06ch,0ffh,000h,000h,000h,000h
 	 	db 000h,000h,0ffh,000h,0ffh,018h,018h,018h
 	 	db 018h,018h,0f8h,018h,0f8h,018h,018h,018h
 	 	db 06ch,06ch,06ch,0ech,06ch,06ch,06ch,06ch
 	 	db 000h,000h,000h,0fch,06ch,06ch,06ch,06ch
 	 	db 000h,000h,0f8h,018h,0f8h,018h,018h,018h
 	 	db 000h,000h,000h,0ffh,06ch,06ch,06ch,06ch
 	 	db 06ch,06ch,06ch,07fh,000h,000h,000h,000h
 	 	db 018h,018h,01fh,018h,01fh,000h,000h,000h
 	 	db 000h,000h,01fh,018h,01fh,018h,018h,018h
 	 	db 06ch,06ch,06ch,0fch,000h,000h,000h,000h
 	 	db 018h,018h,0f8h,018h,0f8h,000h,000h,000h
 	 	db 018h,018h,01fh,018h,01fh,018h,018h,018h
 	 	db 06ch,06ch,06ch,06fh,06ch,06ch,06ch,06ch
 	 	db 000h,000h,000h,07fh,06ch,06ch,06ch,06ch
 	 	db 000h,000h,07fh,060h,06fh,06ch,06ch,06ch
 	 	db 000h,000h,0fch,00ch,0ech,06ch,06ch,06ch
 	 	db 06ch,06ch,0ech,00ch,0fch,000h,000h,000h
 	 	db 06ch,06ch,06fh,060h,07fh,000h,000h,000h
 	 	db 000h,000h,0ffh,000h,0ffh,000h,000h,000h
 	 	db 06ch,06ch,06ch,06ch,06ch,06ch,06ch,06ch
 	 	db 000h,000h,0ffh,000h,0efh,06ch,06ch,06ch
 	 	db 06ch,06ch,0ech,00ch,0ech,06ch,06ch,06ch
 	 	db 06ch,06ch,0efh,000h,0ffh,000h,000h,000h
 	 	db 06ch,06ch,06fh,060h,06fh,06ch,06ch,06ch
 	 	db 06ch,06ch,0efh,000h,0efh,06ch,06ch,06ch
 	 	db 092h,000h,092h,000h,092h,000h,092h,000h
 	 	db 092h,049h,092h,049h,092h,049h,092h,000h
 	 	db 0aah,055h,0aah,055h,0aah,055h,0aah,000h
 	 	db 06ch,06ch,06ch,0efh,06ch,06ch,06ch,06ch
 	 	db 018h,018h,0ffh,000h,0ffh,018h,018h,018h
 	 	db 000h,000h,000h,01fh,018h,018h,018h,018h
 	 	db 000h,000h,000h,0f8h,018h,018h,018h,018h
 	 	db 018h,018h,018h,0f8h,000h,000h,000h,000h
 	 	db 018h,018h,018h,01fh,000h,000h,000h,000h
 	 	db 000h,000h,000h,0ffh,000h,000h,000h,000h
 	 	db 018h,018h,018h,018h,018h,018h,018h,018h
 	 	db 000h,000h,000h,0ffh,018h,018h,018h,018h
 	 	db 018h,018h,018h,0f8h,018h,018h,018h,018h
 	 	db 018h,018h,018h,0ffh,000h,000h,000h,000h
 	 	db 018h,018h,018h,01fh,018h,018h,018h,018h
 	 	db 018h,018h,018h,0ffh,018h,018h,018h,018h
 	 	db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
 	 	db 000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh
 	 	db 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h
 	 	db 00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh
 	 	db 0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h
 	 	db 01eh,036h,066h,066h,07eh,066h,066h,000h
 	 	db 07ch,060h,060h,07ch,066h,066h,07ch,000h
 	 	db 07ch,066h,066h,07ch,066h,066h,07ch,000h
 	 	db 07eh,060h,060h,060h,060h,060h,060h,000h
 	 	db 038h,06ch,06ch,06ch,06ch,06ch,0feh,0c6h
 	 	db 07eh,060h,060h,07ch,060h,060h,07eh,000h
 	 	db 0dbh,0dbh,07eh,03ch,07eh,0dbh,0dbh,000h
 	 	db 03ch,066h,006h,01ch,006h,066h,03ch,000h
 	 	db 066h,066h,06eh,07eh,076h,066h,066h,000h
 	 	db 03ch,066h,06eh,07eh,076h,066h,066h,000h
 	 	db 066h,06ch,078h,070h,078h,06ch,066h,000h
 	 	db 01eh,036h,066h,066h,066h,066h,066h,000h
 	 	db 0c6h,0eeh,0feh,0feh,0d6h,0c6h,0c6h,000h
 	 	db 066h,066h,066h,07eh,066h,066h,066h,000h
 	 	db 03ch,066h,066h,066h,066h,066h,03ch,000h
 	 	db 07eh,066h,066h,066h,066h,066h,066h,000h
 	 	db 07ch,066h,066h,066h,07ch,060h,060h,000h
 	 	db 03ch,066h,060h,060h,060h,066h,03ch,000h
 	 	db 07eh,018h,018h,018h,018h,018h,018h,000h
 	 	db 066h,066h,066h,03eh,006h,066h,03ch,000h
 	 	db 07eh,0dbh,0dbh,0dbh,07eh,018h,018h,000h
 	 	db 066h,066h,03ch,018h,03ch,066h,066h,000h
 	 	db 066h,066h,066h,066h,066h,066h,07fh,003h
 	 	db 066h,066h,066h,03eh,006h,006h,006h,000h
 	 	db 0dbh,0dbh,0dbh,0dbh,0dbh,0dbh,0ffh,000h
 	 	db 0dbh,0dbh,0dbh,0dbh,0dbh,0dbh,0ffh,003h
 	 	db 0e0h,060h,060h,07ch,066h,066h,07ch,000h
 	 	db 0c6h,0c6h,0c6h,0f6h,0deh,0deh,0f6h,000h
 	 	db 060h,060h,060h,07ch,066h,066h,07ch,000h
 	 	db 078h,00ch,006h,03eh,006h,00ch,078h,000h
 	 	db 0ceh,0dbh,0dbh,0fbh,0dbh,0dbh,0ceh,000h
 	 	db 03eh,066h,066h,066h,03eh,036h,066h,000h
 	 	db 000h,000h,078h,00ch,07ch,0cch,076h,000h
 	 	db 000h,03ch,060h,03ch,066h,066h,03ch,000h
 	 	db 000h,03ch,066h,07ch,066h,066h,07ch,000h
 	 	db 000h,000h,07eh,060h,060h,060h,060h,000h
 	 	db 000h,000h,03ch,06ch,06ch,06ch,0feh,0c6h
 	 	db 000h,000h,03ch,066h,07eh,060h,03ch,000h
 	 	db 000h,000h,0dbh,07eh,03ch,07eh,0dbh,000h
 	 	db 000h,000h,03ch,066h,00ch,066h,03ch,000h
 	 	db 000h,000h,066h,06eh,07eh,076h,066h,000h
 	 	db 000h,018h,066h,06eh,07eh,076h,066h,000h
 	 	db 000h,000h,066h,06ch,078h,06ch,066h,000h
 	 	db 000h,000h,01eh,036h,066h,066h,066h,000h
 	 	db 000h,000h,0c6h,0feh,0feh,0d6h,0c6h,000h
 	 	db 000h,000h,066h,066h,07eh,066h,066h,000h
 	 	db 000h,000h,03ch,066h,066h,066h,03ch,000h
 	 	db 000h,000h,07eh,066h,066h,066h,066h,000h
 	 	db 000h,000h,07ch,066h,066h,07ch,060h,000h
 	 	db 000h,000h,03ch,066h,060h,066h,03ch,000h
 	 	db 000h,000h,07eh,018h,018h,018h,018h,000h
 	 	db 000h,000h,066h,066h,03eh,006h,03ch,000h
 	 	db 000h,000h,07eh,0dbh,0dbh,07eh,018h,000h
 	 	db 000h,000h,066h,03ch,018h,03ch,066h,000h
 	 	db 000h,000h,066h,066h,066h,066h,07fh,003h
 	 	db 000h,000h,066h,066h,03eh,006h,006h,000h
 	 	db 000h,000h,0dbh,0dbh,0dbh,0dbh,0ffh,000h
 	 	db 000h,000h,0dbh,0dbh,0dbh,0dbh,0ffh,003h
 	 	db 000h,000h,0e0h,060h,07ch,066h,07ch,000h
 	 	db 000h,000h,0c6h,0c6h,0f6h,0deh,0f6h,000h
 	 	db 000h,000h,060h,060h,07ch,066h,07ch,000h
 	 	db 000h,000h,07ch,006h,03eh,006h,07ch,000h
 	 	db 000h,000h,0ceh,0dbh,0fbh,0dbh,0ceh,000h
 	 	db 000h,000h,03eh,066h,03eh,036h,066h,000h
 	 	db 066h,07eh,060h,07ch,060h,060h,07eh,000h
 	 	db 000h,066h,03ch,066h,07eh,060h,03ch,000h
 	 	db 000h,000h,000h,000h,003h,006h,00ch,018h
 	 	db 000h,000h,000h,000h,0c0h,060h,030h,018h
 	 	db 018h,030h,060h,0c0h,000h,000h,000h,000h
 	 	db 018h,00ch,006h,003h,000h,000h,000h,000h
 	 	db 000h,000h,018h,00ch,07eh,00ch,018h,000h
 	 	db 000h,000h,018h,030h,07eh,030h,018h,000h
 	 	db 018h,03ch,07eh,018h,018h,018h,018h,000h
 	 	db 018h,018h,018h,018h,07eh,03ch,018h,000h
 	 	db 018h,018h,000h,07eh,000h,018h,018h,000h
 	 	db 018h,018h,07eh,018h,018h,000h,07ch,000h
 	 	db 0cfh,0cch,0efh,0fch,0dch,0cch,0cch,000h
 	 	db 000h,066h,03ch,066h,066h,03ch,066h,000h
 	 	db 000h,000h,000h,01ch,01ch,000h,000h,000h
 	 	db 000h,000h,000h,000h,000h,000h,000h,000h


 	assume	ds:abs0
ca0:
 	in	al,port_b
 	and	al,0cfh
 	out	port_b,al
 	xor	ax,ax
 	mov	ds,ax
 	mov	es,ax
 	mov	dx,213h
 	mov	al,01
 	out	dx,al	   ; активизировать плату расширения
 	mov	bx,0
 	mov	dx,2b0h
 	in	al,dx
 	and	al,0ch
 	cmp	al,0ch
 	jz	ca1
 	mov	bx,res_fl
ca1:	mov	al,0ah
 	out	dx,al
 	in	al,dx
 	and	al,0fh
 	cmp	al,0ah
 	jnz	oshp	   ; нет платы 2B0
 	mov	al,0ch
 	out	dx,al
 	xor	al,al  ; сброс активности остальных плат памяти
ca2:	inc	dx
 	out	dx,al
 	cmp	dl,0b3h
 	jnz	ca2
ca22:	mov	bx,res_fl
 	mov	cx,2000h
 	cmp	bx,1234h
 	jz	ca8
 	mov	ax,0f000h
 	mov	ss,ax
ca7a:	mov	sp,offset caw
ca7:	jmp	stgtst_cnt
ca3:	mov	cx,2000h
 	je	ca8
 	mov	dx,2b0h    ; сбой в первых 16К основной платы
 	in	al,dx	   ; памяти
 	test	al,03	   ; реконфигурация была?
 	jz	ca6
oshp:
 	mov	bl,al	   ; была реконфигурация
 	mov	al,89h
 	out	63h,al
 	mov	al,04
ca5:	out	60h,al
 	xor	cx,cx
ca4:	loop	ca4
 	xchg	bl,al
 	jmp	ca5
ca6:	or	al,3
 	out	dx,al
 	jmp	ca7a
ca8:	xor	ax,ax
 	cld
 	xor	si,si
 	xor	di,di
 	mov	bp,2b0h
 	rep	stosw
 	mov	res_fl,bx
ca9:	mov	dx,0400h
 	mov	bx,16
ca10:	mov	es,dx
 	xor	di,di
 	mov	ax,0aa55h
 	mov	cx,ax
 	mov	es:[di],ax  ; проверка наличия очередных 16К памяти
 	mov	al,0fh
 	mov	ax,es:[di]
 	xor	ax,cx
 	jnz	ca11
 	mov	cx,2000h
 	rep	stosw
 	mov	cx,2000h
 	xor	di,di
 	repz	scasw	   ; есть сбойные адреса в порции 16К?
 	or	cx,ax
 	jnz	ca11	   ; да
 	add	dx,0400h   ; нет
 	add	bx,16
 	cmp	dh,0a0h
 	jnz	ca10
 	jmp	ca12
ca11:	cmp	dh,60h
 	jnb	ca12
 	mov	dx,bp	   ; адрес меньше 512К
 	in	al,dx
 	test	al,03
 	jnz	ca12
 	mov	dx,es
 	and	dh,60h
 	xor	dh,60h
 	mov	cl,5
 	shr	dh,cl
 	or	al,dh
 	mov	dx,bp
 	out	dx,al
 	xor	dx,dx
 	xor	bx,bx
 	jmp	ca10
ca12:	 	 	   ; сброс активности текущего модуля памяти
 	mov	dx,bp
 	in	al,dx
 	and	al,0f3h
 	out	dx,al
 	mov	dx,2b0h    ; возврат на плату памяти 2B0
 	in	al,dx
 	or	al,0ch
 	out	dx,al
 	test	bp,3
 	jnz	ca14
 	mov	mem_siz,bx
ca15:
 	mov	si,csi
 	mov	tabl1[si],bp
 	mov	tabl1[si+2],bx
 	inc	bp
 	add	csi,4
ca16:	cmp	bp,2b4h
 	jnb	ca13
 	mov	bx,0
 	mov	al,0ch
 	mov	dx,bp
 	out	dx,al
 	mov	dx,2b0h 	; сброс активности 2b0
 	in	al,dx
 	and	al,0f3h
 	out	dx,al
 	mov	dx,0
 	jmp	ca10
ca14:	cmp	bx,0
 	jnz	ca15
 	inc	bp
 	jmp	ca16
ca13:
 	mov	ax,dat
 	mov	ds,ax
 	mov	bp,0
 	jmp	c21
;
;
 	assume cs:code,ds:data
e190:	push	ds
 	mov	ax,16
 	cmp	reset_flag,1234h
 	jnz	e20a
 	jmp	e22
e20a:	mov	ax,16
 	jmp	short prt_siz
e20b:	mov	bx,memory_size
 	sub	bx,16
 	mov	cl,4
 	shr	bx,cl
 	mov	cx,bx
 	mov	bx,0400h
e20c:	mov	ds,bx
 	mov	es,bx
 	add	bx,0400h
 	push	dx
 	push	cx
 	push	bx
 	push	ax
 	call	stgtst
 	jnz	e21a
 	pop	ax
 	add	ax,16
prt_siz:
 	push	ax
 	mov	bx,10
 	mov	cx,3
decimal_loop:
 	xor	dx,dx
 	div	bx
 	or	dl,30h
 	push	dx
 	loop	decimal_loop
 	mov	cx,3
prt_dec_loop:
 	pop	ax
 	call	prt_hex
 	loop	prt_dec_loop
 	mov	cx,22
 	mov	si,offset e300
kb_ok:	mov	al,byte ptr cs:[si]
 	inc	si
 	call	prt_hex
 	loop	kb_ok
 	pop	ax
 	cmp	ax,16
 	je	e20b
 	pop	bx
 	pop	cx
 	pop	dx
 	loop	e20c
 	mov	al,10
 	call	prt_hex
 	pop	ds
 	jmp	e22
e21a:
 	pop	bx
 	add	sp,6
 	mov	dx,ds
 	pop	ds
 	push	ds
 	push	bx
 	mov	bx,dx
 	push	ax
 	cmp	dh,60h
 	jnb	ea1
 	mov	dx,2b0h
 	in	al,dx
 	test	al,3
 	jnz	ea1
 	push	ax
 	mov	al,crt_mode
 	mov	ah,0
 	int	10h
 	pop	ax
 	mov	dx,bx
 	and	dh,60h
 	xor	dh,60h
 	mov	cl,5
 	shr	dh,cl
 	or	al,dh
 	mov	dx,2b0h
 	out	dx,al
 	xor	ax,ax
 	mov	es,ax
 	mov	ds,ax
 	jmp	ca22
ea1:	pop	ax
 	mov	dx,bx
 	pop	bx
 	mov	tabl+2,bx
 	mov	memory_size,bx
 	push	ax
 	mov	al,10
 	call	prt_hex
 	pop	ax
 	jmp	osh
prt_hex proc	near
 	mov	ah,14
 	mov	bh,0
 	int	10h
 	ret
prt_hex endp
e300	db	'  Kb ОБ',0cah,'ЕМ ПАМЯТИ (С)',0dh
f39	db	'  ОШИБКА  ( НАЖМИ КЛАВИШУ "Ф1" )'


;-------int 15--------------------------
;
;   Программа поддержки расширенной памяти
;
;   AH = 87H
;	  Переслать блок, параметры которого указаны в таблице GDT
;
;   На входе
;	  ES:SI - адрес таблицы
;	  CX	- количество пересылаемых слов
;
;   AH = 88H
;	   Определить об'ем расширенной памяти
;
;   На выходе
;	  AX - об'ем расширенной памяти
;	  CF = 0, если расширенная память присутствует
;	  CF = 1, если расширенная память отсутствует
;
;   AH = C7H
;	  Переслать блок в соответствии с указанными параметрами
;
;   На входе
;	  CX - количество пересылаемых слов
;	  DS:SI - адрес источника
;	  ES:DI - адрес приемника
;	  BL	- логический номер платы источника
;	  BH	- логический номер платы приемника
;
;   AH = C8H
;	  Определить об'ем памяти платы, логический номер которой
;	  указан в AL
;
;   На выходе
;	  AX  - об'ем памяти выбранной платы
;	  CF = 0, если плата присутствует
;	     CF = 1, если плата отсутствует
;---------------------------------------
 	assume cs:code
ex_memory proc far
;
 	sti
;
 	cmp ah,0c7h	; анализ операций
 	je move_mem_block_1    ; переход по AH=C7
;
 	push ds
 	push bx
;
 	cmp ah,87h
 	je move 	; переход по AH=87
;
 	mov bx,40h	; установить базовый адрес для об'ема памяти
 	mov ds,bx	; 40:Е2
 	mov bx,0e2h
;
 	cmp ah,88h
 	je ex_mem_size	; переход по AH=88
;
 	cmp ah,0c8h
 	je mem_block	; переход по AH=C8
;
 	pop bx
 	pop ds
 	mov ah,86h	; выход. Заданный код операции не обрабатывается
 	stc
 	ret 2
;
;
move_mem_block_1:
 	jmp move_mem_block
;
;
;
ex_mem_size:	 	    ; AH=88
 	mov ax,[bx+4]	; прочитать об'ем первого расширенного блока
 	 	 	; памяти (40:Е6)
 	add ax,[bx+8]	; добавить об'ем второго расширенного блока
 	 	 	; памяти (40:ЕА)
 	add ax,[bx+12]	; добавить об'ем третьего расширенного блока
 	 	 	; памяти (40:ЕЕ)
 	jmp short mem_inf
;
;
mem_block:	 	    ; AH=C8
 	and ax,3	; преобразовать логический номер платы
 	add al,al
 	add al,al	; определить величину смещения
 	add bx,ax
 	mov ax,[bx]	; прочитать об'ем заданного блока памяти
mem_inf:
 	cmp ax,1	; определить существует ли запрашиваемая память
 	pop bx
 	pop ds
 	ret 2	 	; выход
;
;
move:	 	 	     ; AH=87
 	push es 	; сохранить регистры
 	push dx
 	push si
 	push di
 	push cx
 	add si,16	; получить смещение в таблице GDT
 	mov ah,es:[si+4]  ; получить старший байт адреса источника
 	mov al,es:[si+12] ; получить старший байт адреса назначения
 	and ax,0f0f0h
 	cmp ax,0
 	je main_mem	; источник и назначение осуществляется
 	 	 	; в основную память
 	cmp ah,0
 	je in_mem	; пересылка из основной памяти в расширенную
 	cmp al,0
 	je out_mem	; пересылка из расширенной памяти в основную
;   источник и назначение в расширенной памяти
 	call ext	; определить реальный адрес источника
 	 	 	; расширенной памяти
ext_mem:
 	mov bl,bh  ; сохранить номер платы источника расширенной памяти
 	push ds
 	push di
 	add si,8  ; установить адрес назначения в таблице GDT
 	call ext  ; определить реальный адрес назначения расширенной
 	 	  ; памяти
 	jmp short move_block
;
in_mem:
 	call main  ; определить реальный адрес источника основной
 	 	   ; памяти
 	jmp short ext_mem
;
out_mem:
 	call ext ; определить реальный адрес источника из расширенной
 	 	 ; памяти
ext_mem_1:
 	mov bl,bh ; сохранить номер платы источника расширенной памяти
 	push ds
 	push di
 	add si,8 ; установить адрес назначения в таблице GDT
 	call main ; определить реальный адрес назначения из основной
 	 	  ; памяти
 	jmp short move_block
;
main_mem:
 	call main ; определить реальный адрес источника из основной
 	 	  ; памяти
 	jmp short ext_mem_1
;
;
move_block:
 	push ds ; установить DS:SI - адрес источника
 	pop es	;	     ES:DI - адрес назначения
 	pop si
 	pop ds
;
 	call go 	; переслать
;
;
 	xor ax,ax	; установить CF=0
 	pop cx	 	; восстановить регистры
 	pop di
 	pop si
 	pop dx
 	pop es
 	pop bx
 	pop ds
 	ret 2	; выход
;
;
;
move_mem_block: 	 ; AH=C7
 	push ds
 	push si
 	push di
 	mov ax,40h
 	mov ds,ax
 	and bx,303h  ; определить смещение для определения параметров
 	add bx,bx    ; платы источника и платы назначения
 	add bx,bx
 	or bx,0e0e0h
 	mov si,bx
 	xchg bh,bl
 	mov di,bx
 	and si,0ffh  ; уст адрес смещения для параметров источника
 	and di,0ffh  ; уст адрес смещения для параметров приемника
 	mov bx,[si]  ; прочитать параметры источника
 	mov ax,[di]  ; прочитать параметры приемника
 	mov bh,al    ; сохранить адрес платы источника в BL
 	pop di	     ; сохранить адрес платы приемника в BH
 	pop si
 	pop ds
;
 	call go 	; переслать
;
 	xor ax,ax	; установить CF=0
 	ret 2	 	; выход
;
;
;
;
;
main_port proc near   ; прочитать адрес порта основной памяти
 	 	      ; в AH (40:E0)
 	push ds
 	push bx
 	mov ax,40h
 	mov ds,ax
 	mov bx,0e0h
 	mov ah,[bx]
 	pop bx
 	pop ds
 	ret
main_port endp
;
;
main proc near	; определить реальный адрес основной памяти в DS:DI
 	push ax
 	call main_port	; определить адрес порта основной памяти
 	mov bh,ah  ; сохранить адрес порта основной памяти в BH
 	mov ax,es:[si+2]
 	push ax
 	pop di
 	and di,0fh   ; определение адреса обращения (DI)
 	shr ax,1     ; определение базового адреса (DS)
 	shr ax,1
 	shr ax,1
 	shr ax,1
 	and ax,0fffh
 	push bx
 	mov bl, es:[si+4]
 	add bl,bl
 	add bl,bl
 	add bl,bl
 	add bl,bl
 	or ah,bl
 	pop bx
 	mov ds,ax
 	pop ax
 	ret
main endp
;
;
ext proc near
 	push ax
 	push dx
 	push ds
 	push bx
 	mov ax,40h
 	mov ds,ax
 	mov ax,es:[si+3] ;уменьшить адрес расширенной памяти на 100000H
 	sub ah,10h
 	mov bx,0e0h
;
scanirov:
 	call mem_2   ; определить адрес порта расширенной памяти
 	cmp ax,dx
 	jc find
 	sub ax,dx
 	cmp bx,0f0h
 	je error_ext
 	jmp short scanirov
;
find:	; определить диапазон адресов выбранной зоны расширенной памяти
;
 	mov dx,ax
 	mov ah,[bx]
 	pop bx
 	pop ds
 	mov bh,ah  ; сохранить адрес порта выбранной памяти в BH
 	add dx,dx  ; определение базового адреса (DS)
 	add dx,dx
 	add dx,dx
 	add dx,dx
 	and dx,0fff0h
 	mov ax,es:[si+2]
 	shr ax,1
 	shr ax,1
 	shr ax,1
 	shr ax,1
 	and al,0fh
 	or dl,al
 	mov ds,dx
 	mov di,es:[si+2]  ; определить адрес обращения (DI)
 	and di,0fh
 	pop dx
 	pop ax
 	ret
;
ext endp
;
;
mem_2 proc near
 	add bx,4
 	mov dx,[bx+2]
 	add dx,dx
 	add dx,dx
 	ret
mem_2 endp
;
error_ext:
 	nop
;
;
go proc near
;
 	call main_port	; сохранить адрес порта основной памяти в AH
;
;
 	cli	 	; закрыть прерывание
 	mov dx,200h	; уст адрес порта платы основной памяти
 	mov dl,ah
 	in al,dx
 	and al,0f3h ;*** reset r&w
 	out dx,al ; выключить режим чтения/записи для основной памяти
;
;
 	mov dl,bl ; уст адрес порта платы источника
 	in al,dx
 	and al,0f3h   ; выключить режим чтения/записи
 	or al,4     ; включить режим чтения для источника
 	out dx,al
;
;
 	mov dl,bh	; установить адрес порта платы назначения
 	in al,dx
 	and al,0f3h	; выключить режим чтения/записи
 	or al,8 	; включить режим записи для приемника
 	out dx,al
;
 	cld	 	; переслать по счетчику
 	rep movsw
;
 	in al,dx  ; выключить режим чтения/записи для платы приемника
 	and al,0f3h
 	out dx,al
 	mov dl,bl  ; выключить режим чтения/записи для платы источника
 	in al,dx
 	and al,0f3h
 	out dx,al
;
 	mov dl,ah	; установить адрес порта основной памяти
 	in al,dx
 	or al,0ch      ; включить режим чтения/записи
 	out dx,al  ; перевести основную память в режим чтения/записи
;
 	sti	   ; включить прерывания
 	ret
go endp
;
;
;
;
ex_memory endp
;
pmsg	proc	near
 	mov	ax,dat
 	mov	ds,ax
 	mov	bp,si
gr12:
 	mov	al,cs:[si]
 	inc	si
 	mov	bh,0
 	mov	ah,14
 	int	10h
 	loop	gr12
 	ret
pmsg	endp


;----------------------------------------
;
;   Записать телетайп (INT 10H, AH=14)
;
;   Эта программа выводит символ в буфер ЭЛИ с одновременной уста-
; новкой позиции курсора и передвижением курсора на экране.
;   После записи символа в последнюю позицию строки выполняется ав-
; томатический переход на новую строку. Если страница экрана за-
; полнена (позиция курсора 24,79/39), выполняется перемещение экрана
; на одну строку вверх. Освободившаяся строка заполняется значением
; атрибута символа (для алфавитно-цифрового режима). Для графики цвет=00
; После записи очередного символа курсор установлен в следующую позицию.
;
;   ВХОД
;	   AL - код выводимого символа,
;	   BL - цвет переднего плана для графики.
;
;----------------------------------------

 	assume	cs:code,ds:data
write_tty	proc	near
 	push	ax	 	; сохранить регистры
 	push	ax
 	mov	ah,3
 	mov	bh,active_page
 	int	10h	 	; считать положение текущего курсора
 	pop	ax	 	; восстановить символ

;   DX содержит текущую позицию курсора

 	cmp	al,8	 	; есть возврат на одну позицию ?
 	je	u8	 	; возврат на одну позицию
 	cmp	al,0dh	 	; есть возврат каретки ?
 	je	u9	 	; возврат каретки
 	cmp	al,0ah	 	; есть граница поля ?
 	je	u10	 	; граница поля
 	cmp	al,07h	 	; звуковой сигнал ?
 	je	u11	 	; звуковой сигнал

;   Запись символа на экран

 	mov	bh,active_page
 	mov	ah,10	 	; запись символа без атрибута
 	mov	cx,1
 	int	10h

;   Положение курсора для следующего символа

 	inc	dl
 	cmp	dl,byte ptr crt_cols
 	jnz	u7	 	; переход к установке курсора
 	mov	dl,0
 	cmp	dh,24	 	; проверка граничной строки
 	jnz	u6	 	; установить курсор

;   Сдвиг экрана
u1:

 	mov	ah,2
 	mov	bh,0
 	int	10h	 	; установить курсор


 	mov	al,crt_mode	; получить текущий режим
 	cmp	al,4
 	jc	u2	 	; считывание курсора
 	cmp	al,7
 	mov	bh,0	 	; цвет заднего плана
 	jne	u3

u2:	 	 	 	; считывание курсора
 	mov	ah,8
 	int	10h	   ; считать символ/атрибут текущего курсора
 	mov	bh,ah	 	; запомнить в BH

;   Перемещение экрана на одну строку вверх

u3:
 	mov	ax,601h
 	mov	cx,0	 	; верхний левый угол
 	mov	dh,24	 	; координаты нижнего правого
 	mov	dl,byte ptr crt_cols	; угла
 	dec	dl
u4:
 	int	10h

;   Выход из прерывания

u5:
 	pop	ax	 	; восстановить символ
 	jmp	video_return	; возврат к программе

u6:	 	 	 	; установить курсор
 	inc	dh	 	; следующая строка
u7:	 	 	 	; установить курсор
 	mov	ah,2
 	jmp	short u4	; установить новый курсор

;   Сдвиг курсора на одну позицию влево

u8:
 	cmp	dl,0
 	je	u7	 	; установить курсор
 	dec	dl	 	; нет - снова его передать
 	jmp	short u7

;   Перемещение курсора в начало строки

u9:
 	mov	dl,0
 	jmp	short u7	; установить курсор

;   Перемещение курсора на следующую строку

u10:
 	cmp	dh,24	 	; последняя строка экрана
 	jne	u6	 	; да - сдвиг экрана
 	jmp	short u1	; нет - снова установить курсор

;   Звуковой сигнал

u11:
 	mov	bl,2	 	; уст длительность звукового сигнала
 	call	beep	 	; звук
 	jmp	short u5	; возврат
write_tty	endp

ah12:
 	cmp	al,3
 	jnz	ah121
 	push	bx
 	mov	ax,cs
 	mov	es,ax
 	mov	cx,80h
 	mov	dx,80h
 	pop	bx
 	mov	bp,offset crt_char_rus
 	cmp	bl,0
 	mov	bx,0800h
 	jz	rav
 	mov	bp,offset crt_char_ibm
rav:
 	mov	ax,1100h
 	push	ax
 	int	10h
 	pop	ax
 	int	10h
 	jmp	video_return
ah121:
 	jmp	znak
stgtst:
 	 	mov	cx,2000h

stgtst_cnt	proc	near
 	 	mov	bx,cx
 	 	cld
 	 	sub	di,di
 	 	sub	ax,ax
c2_1:
 	 	mov	[di],al
 	 	mov	al,[di]
 	 	xor	al,ah
 	 	jnz	c7
 	 	inc	ah
 	 	mov	al,ah
 	 	jnz	c2_1
 	 	mov	ax,055aah
 	 	mov	dx,ax
 	 	rep	stosw
 	 	in	al,port_b
 	 	or	al,030h
 	 	out	port_b,al
 	 	nop
 	 	and	al,0cfh
 	 	out	port_b,al
;
 	 	dec	di
 	 	dec	di
 	 	std
 	 	mov	si,di
 	 	mov	cx,bx
c3:
 	 	lodsw
 	 	xor	ax,dx
 	 	jne	c7x
 	 	mov	ax,0aa55h
 	 	stosw
 	 	loop	c3
;
 	 	cld
 	 	inc	di
 	 	inc	di
 	 	mov	si,di
 	 	mov	cx,bx
 	 	mov	dx,ax
c4:
 	 	lodsw
 	 	xor	ax,dx
 	 	jne	c7x
 	 	mov	ax,0ffffh
 	 	stosw
 	 	loop	c4
;
 	 	dec	di
 	 	dec	di
 	 	std
 	 	mov	si,di
 	 	mov	cx,bx
 	 	mov	dx,ax
c5:
 	 	lodsw
 	 	xor	ax,dx
 	 	jne	c7x
 	 	mov	ax,00101h
 	 	stosw
 	 	loop	c5
;
 	 	cld
 	 	inc	di
 	 	inc	di
 	 	mov	si,di
 	 	mov	cx,bx
 	 	mov	dx,ax
c6:
 	 	lodsw
 	 	xor	ax,dx
 	 	jne	c7x
 	 	stosw
 	 	loop	c6
;
 	 	dec	di
 	 	dec	di
 	 	std
 	 	mov	si,di
 	 	mov	cx,bx
 	 	mov	dx,ax
c6x:
 	 	lodsw
 	 	xor	ax,dx
 	 	jne	c7x
 	 	loop	c6x
;
 	 	in	al,port_c
 	 	and	al,040h
 	 	mov	al,0
c7:
 	 	cld
 	 	ret
c7x:
 	 	cmp	al,0
 	 	jnz	c7
 	 	xor	al,ah
 	 	inc	si
 	 	jmp	short c7
stgtst_cnt	endp

 	org	0DC00h

crt_char_ibm	label byte

 	DB	78H,0CCH,0C0H,0CCH,78H	 	;0100 78 CC C0 CC 78
 	DB	18H,0CH,78H,0,0CCH	 	;0105 18 0C 78 00 CC
 	DB	0,3 DUP(0CCH),7EH	 	;010A 00 CC CC CC 7E
 	DB	0,1CH,0,78H,0CCH	 	;010F 00 1C 00 78 CC
 	DB	0FCH,0C0H,78H,0,7EH	 	;0114 FC C0 78 00 7E
 	DB	0C3H,3CH,6,3EH,66H	 	;0119 C3 3C 06 3E 66
 	DB	3FH,0,0CCH,0,78H	 	;011E 3F 00 CC 00 78
 	DB	0CH,7CH,0CCH,7EH,0	 	;0123 0C 7C CC 7E 00
 	DB	0E0H,0,78H,0CH,7CH	 	;0128 E0 00 78 0C 7C
 	DB	0CCH,7EH,0,2 DUP(30H),78H	;012D CC 7E 00 30 30 78
 	DB	0CH,7CH,0CCH,7EH,0	 	;0133 0C 7C CC 7E 00
 	DB	2 DUP(0),78H,0C0H	 	;0138 00 00 78 C0
 	DB	0C0H,78H,0CH,38H,7EH	 	;013C C0 78 0C 38 7E
 	DB	0C3H,3CH,66H,7EH,60H	 	;0141 C3 3C 66 7E 60
 	DB	3CH,0,0CCH,0,78H	 	;0146 3C 00 CC 00 78
 	DB	0CCH,0FCH,0C0H,78H,0	 	;014B CC FC C0 78 00
 	DB	0E0H,0,78H,0CCH,0FCH	 	;0150 E0 00 78 CC FC
 	DB	0C0H,78H,0,0CCH,0	 	;0155 C0 78 00 CC 00
 	DB	70H,3 DUP(30H),78H	 	;015A 70 30 30 30 78
 	DB	0,7CH,0C6H,38H,18H	 	;015F 00 7C C6 38 18
 	DB	2 DUP(18H),3CH,0	 	;0164 18 18 3C 00
 	DB	0E0H,0,70H,3 DUP(30H),78H	;0168 E0 00 70 30 30 30 78
 	DB	0,0C6H,38H,6CH,0C6H	 	;016F 00 C6 38 6C C6
 	DB	0FEH,2 DUP(0C6H),0	 	;0174 FE C6 C6 00
 	DB	2 DUP(30H),0,78H	 	;0178 30 30 00 78
 	DB	0CCH,0FCH,0CCH,0,1CH	 	;017C CC FC CC 00 1C
 	DB	0,0FCH,60H,78H,60H	 	;0181 00 FC 60 78 60
 	DB	0FCH,3 DUP(0),7FH	 	;0186 FC 00 00 00 7F
 	DB	0CH,7FH,0CCH,7FH,0	 	;018B 0C 7F CC 7F 00
 	DB	3EH,6CH,0CCH,0FEH,0CCH	 	;0190 3E 6C CC FE CC
 	DB	0CCH,0CEH,0,78H,0CCH	 	;0195 CC CE 00 78 CC
 	DB	0,78H,2 DUP(0CCH),78H	 	;019A 00 78 CC CC 78
 	DB	2 DUP(0),0CCH,0 	 	;019F 00 00 CC 00
 	DB	78H,2 DUP(0CCH),78H	 	;01A3 78 CC CC 78
 	DB	2 DUP(0),0E0H,0 	 	;01A7 00 00 E0 00
 	DB	78H,2 DUP(0CCH),78H	 	;01AB 78 CC CC 78
 	DB	0,78H,0CCH,0,0CCH	 	;01AF 00 78 CC 00 CC
 	DB	2 DUP(0CCH),7EH,0	 	;01B4 CC CC 7E 00
 	DB	0,0E0H,0,3 DUP(0CCH),7EH	;01B8 00 E0 00 CC CC CC 7E
 	DB	2 DUP(0),0CCH,0 	 	;01BF 00 00 CC 00
 	DB	2 DUP(0CCH),7CH,0CH	 	;01C3 CC CC 7C 0C
 	DB	0F8H,0C3H,18H,3CH,66H	 	;01C7 F8 C3 18 3C 66
 	DB	66H,3CH,18H,0,0CCH	 	;01CC 66 3C 18 00 CC
 	DB	0,4 DUP(0CCH),78H	 	;01D1 00 CC CC CC CC 78
 	DB	0,2 DUP(18H),7EH	 	;01D7 00 18 18 7E
 	DB	2 DUP(0C0H),7EH,18H	 	;01DB C0 C0 7E 18
 	DB	18H,38H,6CH,64H,0F0H	 	;01DF 18 38 6C 64 F0
 	DB	60H,0E6H,0FCH,0,0CCH	 	;01E4 60 E6 FC 00 CC
 	DB	0CCH,78H,0FCH,30H,0FCH	 	;01E9 CC 78 FC 30 FC
 	DB	2 DUP(30H),0F8H,0CCH	 	;01EE 30 30 F8 CC
 	DB	0CCH,0FAH,0C6H,0CFH,0C6H	;01F2 CC FA C6 CF C6
 	DB	0C7H,0EH,1BH,18H,3CH	 	;01F7 C7 0E 1B 18 3C
 	DB	2 DUP(18H),0D8H,70H	 	;01FC 18 18 D8 70
 	DB	1CH,0,78H,0CH,7CH	 	;0200 1C 00 78 0C 7C
 	DB	0CCH,7EH,0,38H,0	 	;0205 CC 7E 00 38 00
 	DB	70H,3 DUP(30H),78H	 	;020A 70 30 30 30 78
 	DB	2 DUP(0),1CH,0	 	 	;020F 00 00 1C 00
 	DB	78H,2 DUP(0CCH),78H	 	;0213 78 CC CC 78
 	DB	2 DUP(0),1CH,0	 	 	;0217 00 00 1C 00
 	DB	3 DUP(0CCH),7EH,0	 	;021B CC CC CC 7E 00
 	DB	0,0F8H,0,0F8H,0CCH	 	;0220 00 F8 00 F8 CC
 	DB	2 DUP(0CCH),0,0FCH	 	;0225 CC CC 00 FC
 	DB	0,0CCH,0ECH,0FCH,0DCH	 	;0229 00 CC EC FC DC
 	DB	0CCH,0,3CH,2 DUP(6CH),3EH	;022E CC 00 3C 6C 6C 3E
 	DB	0,7EH,2 DUP(0),38H	 	;0234 00 7E 00 00 38
 	DB	2 DUP(6CH),38H,0	 	;0239 6C 6C 38 00
 	DB	7CH,2 DUP(0),30H	 	;023D 7C 00 00 30
 	DB	0,30H,60H,0C0H,0CCH	 	;0241 00 30 60 C0 CC
 	DB	78H,4 DUP(0),0FCH	 	;0246 78 00 00 00 00 FC
 	DB	2 DUP(0C0H),5 DUP(0),0FCH	;024C C0 C0 00 00 00 00 00 FC
 	DB	2 DUP(0CH),2 DUP(0),0C3H	;0254 0C 0C 00 00 C3
 	DB	0C6H,0CCH,0DEH,33H,66H	 	;0259 C6 CC DE 33 66
 	DB	0CCH,0FH,0C3H,0C6H,0CCH 	;025E CC 0F C3 C6 CC
 	DB	0DBH,37H,6FH,0CFH,3	 	;0263 DB 37 6F CF 03
 	DB	2 DUP(18H),0,18H	 	;0268 18 18 00 18
 	DB	3 DUP(18H),2 DUP(0),33H 	;026C 18 18 18 00 00 33
 	DB	66H,0CCH,66H,33H,0	 	;0272 66 CC 66 33 00
 	DB	2 DUP(0),0CCH,66H	 	;0277 00 00 CC 66
 	DB	33H,66H,0CCH,2 DUP(0),22H	;027B 33 66 CC 00 00 22
 	DB	88H,22H,88H,22H,88H	 	;0281 88 22 88 22 88
 	DB	22H,88H,55H,0AAH,55H	 	;0286 22 88 55 AA 55
 	DB	0AAH,55H,0AAH,55H,0AAH	 	;028B AA 55 AA 55 AA
 	DB	0DBH,77H,0DBH,0EEH,0DBH 	;0290 DB 77 DB EE DB
 	DB	77H,0DBH,0EEH,0CH DUP(18H),0F8H ;0295 77 DB EE 18 18 18 18 18 18 18 18 18 18 18 18 F8
 	DB	5 DUP(18H),0F8H,18H	 	;02A5 18 18 18 18 18 F8 18
 	DB	0F8H,3 DUP(18H),36H	 	;02AC F8 18 18 18 36
 	DB	3 DUP(36H),0F6H,36H	 	;02B1 36 36 36 F6 36
 	DB	2 DUP(36H),4 DUP(0),0FEH	;02B6 36 36 00 00 00 00 FE
 	DB	3 DUP(36H),2 DUP(0),0F8H	;02BD 36 36 36 00 00 F8
 	DB	18H,0F8H,3 DUP(18H),36H 	;02C3 18 F8 18 18 18 36
 	DB	36H,0F6H,6,0F6H,36H	 	;02C9 36 F6 06 F6 36
 	DB	0AH DUP(36H),2 DUP(0),0FEH	;02CE 36 36 36 36 36 36 36 36 36 36 00 00 FE
 	DB	6,0F6H,5 DUP(36H),0F6H	 	;02DB 06 F6 36 36 36 36 36 F6
 	DB	6,0FEH,3 DUP(0),36H	 	;02E3 06 FE 00 00 00 36
 	DB	3 DUP(36H),0FEH,0	 	;02E9 36 36 36 FE 00
 	DB	2 DUP(0),2 DUP(18H),0F8H	;02EE 00 00 18 18 F8
 	DB	18H,0F8H,7 DUP(0),0F8H	 	;02F3 18 F8 00 00 00 00 00 00 00 F8
 	DB	7 DUP(18H),1FH,0	 	;02FD 18 18 18 18 18 18 18 1F 00
 	DB	2 DUP(0),4 DUP(18H),0FFH	;0306 00 00 18 18 18 18 FF
 	DB	7 DUP(0),0FFH,18H	 	;030D 00 00 00 00 00 00 00 FF 18
 	DB	6 DUP(18H),1FH,18H	 	;0316 18 18 18 18 18 18 1F 18
 	DB	2 DUP(18H),4 DUP(0),0FFH	;031E 18 18 00 00 00 00 FF
 	DB	3 DUP(0),4 DUP(18H),0FFH	;0325 00 00 00 18 18 18 18 FF
 	DB	5 DUP(18H),1FH,18H	 	;032D 18 18 18 18 18 1F 18
 	DB	1FH,3 DUP(18H),36H	 	;0334 1F 18 18 18 36
 	DB	3 DUP(36H),37H,36H	 	;0339 36 36 36 37 36
 	DB	4 DUP(36H),37H,30H	 	;033E 36 36 36 36 37 30
 	DB	3FH,5 DUP(0),3FH	 	;0344 3F 00 00 00 00 00 3F
 	DB	30H,37H,5 DUP(36H),0F7H 	;034B 30 37 36 36 36 36 36 F7
 	DB	0,0FFH,5 DUP(0),0FFH	 	;0353 00 FF 00 00 00 00 00 FF
 	DB	0,0F7H,5 DUP(36H),37H	 	;035B 00 F7 36 36 36 36 36 37
 	DB	30H,37H,3 DUP(36H),0	 	;0363 30 37 36 36 36 00
 	DB	0,0FFH,0,0FFH,0 	 	;0369 00 FF 00 FF 00
 	DB	2 DUP(0),2 DUP(36H),0F7H	;036E 00 00 36 36 F7
 	DB	0,0F7H,3 DUP(36H),18H	 	;0373 00 F7 36 36 36 18
 	DB	18H,0FFH,0,0FFH,0	 	;0379 18 FF 00 FF 00
 	DB	2 DUP(0),4 DUP(36H),0FFH	;037E 00 00 36 36 36 36 FF
 	DB	5 DUP(0),0FFH,0 	 	;0385 00 00 00 00 00 FF 00
 	DB	0FFH,3 DUP(18H),0	 	;038C FF 18 18 18 00
 	DB	3 DUP(0),0FFH,36H	 	;0391 00 00 00 FF 36
 	DB	6 DUP(36H),3FH,0	 	;0396 36 36 36 36 36 36 3F 00
 	DB	2 DUP(0),2 DUP(18H),1FH 	;039E 00 00 18 18 1F
 	DB	18H,1FH,5 DUP(0),1FH	 	;03A3 18 1F 00 00 00 00 00 1F
 	DB	18H,1FH,3 DUP(18H),0	 	;03AB 18 1F 18 18 18 00
 	DB	3 DUP(0),3FH,36H	 	;03B1 00 00 00 3F 36
 	DB	6 DUP(36H),0FFH,36H	 	;03B6 36 36 36 36 36 36 FF 36
 	DB	2 DUP(36H),2 DUP(18H),0FFH	;03BE 36 36 18 18 FF
 	DB	18H,0FFH,7 DUP(18H),0F8H	;03C3 18 FF 18 18 18 18 18 18 18 F8
 	DB	7 DUP(0),1FH,18H	 	;03CD 00 00 00 00 00 00 00 1F 18
 	DB	2 DUP(18H),8 DUP(0FFH),0	;03D6 18 18 FF FF FF FF FF FF FF FF 00
 	DB	3 DUP(0),4 DUP(0FFH),0F0H	;03E1 00 00 00 FF FF FF FF F0
 	DB	7 DUP(0F0H),8 DUP(0FH),0FFH	;03E9 F0 F0 F0 F0 F0 F0 F0 0F 0F 0F 0F 0F 0F 0F 0F FF
 	DB	3 DUP(0FFH),6 DUP(0),76H	;03F9 FF FF FF 00 00 00 00 00 00 76
 	DB	0DCH,0C8H,0DCH,76H,0	 	;0403 DC C8 DC 76 00
 	DB	0,78H,0CCH,0F8H,0CCH	 	;0408 00 78 CC F8 CC
 	DB	0F8H,2 DUP(0C0H),0	 	;040D F8 C0 C0 00
 	DB	0FCH,0CCH,4 DUP(0C0H),0 	;0411 FC CC C0 C0 C0 C0 00
 	DB	0,0FEH,5 DUP(6CH),0	 	;0418 00 FE 6C 6C 6C 6C 6C 00
 	DB	0FCH,0CCH,60H,30H,60H	 	;0420 FC CC 60 30 60
 	DB	0CCH,0FCH,3 DUP(0),7EH	 	;0425 CC FC 00 00 00 7E
 	DB	3 DUP(0D8H),70H,0	 	;042B D8 D8 D8 70 00
 	DB	0,4 DUP(66H),7CH	 	;0430 00 66 66 66 66 7C
 	DB	60H,0C0H,0,76H,0DCH	 	;0436 60 C0 00 76 DC
 	DB	4 DUP(18H),0,0FCH	 	;043B 18 18 18 18 00 FC
 	DB	30H,78H,2 DUP(0CCH),78H 	;0441 30 78 CC CC 78
 	DB	30H,0FCH,38H,6CH,0C6H	 	;0446 30 FC 38 6C C6
 	DB	0FEH,0C6H,6CH,38H,0	 	;044B FE C6 6C 38 00
 	DB	38H,6CH,2 DUP(0C6H),6CH 	;0450 38 6C C6 C6 6C
 	DB	6CH,0EEH,0,1CH,30H	 	;0455 6C EE 00 1C 30
 	DB	18H,7CH,2 DUP(0CCH),78H 	;045A 18 7C CC CC 78
 	DB	3 DUP(0),7EH,0DBH	 	;045F 00 00 00 7E DB
 	DB	0DBH,7EH,2 DUP(0),6	 	;0464 DB 7E 00 00 06
 	DB	0CH,7EH,2 DUP(0DBH),7EH 	;0469 0C 7E DB DB 7E
 	DB	60H,0C0H,38H,60H,0C0H	 	;046E 60 C0 38 60 C0
 	DB	0F8H,0C0H,60H,38H,0	 	;0473 F8 C0 60 38 00
 	DB	78H,6 DUP(0CCH),0	 	;0478 78 CC CC CC CC CC CC 00
 	DB	0,0FCH,0,0FCH,0 	 	;0480 00 FC 00 FC 00
 	DB	0FCH,2 DUP(0),30H	 	;0485 FC 00 00 30
 	DB	30H,0FCH,2 DUP(30H),0	 	;0489 30 FC 30 30 00
 	DB	0FCH,0,60H,30H,18H	 	;048E FC 00 60 30 18
 	DB	30H,60H,0,0FCH,0	 	;0493 30 60 00 FC 00
 	DB	18H,30H,60H,30H,18H	 	;0498 18 30 60 30 18
 	DB	0,0FCH,0,0EH,1BH	 	;049D 00 FC 00 0E 1B
 	DB	1BH,0AH DUP(18H),0D8H	 	;04A2 1B 18 18 18 18 18 18 18 18 18 18 D8
 	DB	0D8H,70H,2 DUP(30H),0	 	;04AE D8 70 30 30 00
 	DB	0FCH,0,2 DUP(30H),0	 	;04B3 FC 00 30 30 00
 	DB	0,76H,0DCH,0,76H	 	;04B8 00 76 DC 00 76
 	DB	0DCH,2 DUP(0),38H	 	;04BD DC 00 00 38
 	DB	2 DUP(6CH),38H,0	 	;04C1 6C 6C 38 00
 	DB	6 DUP(0),2 DUP(18H),0	 	;04C5 00 00 00 00 00 00 18 18 00
 	DB	6 DUP(0),18H,0	 	 	;04CE 00 00 00 00 00 00 18 00
 	DB	2 DUP(0),0FH,0CH	 	;04D6 00 00 0F 0C
 	DB	2 DUP(0CH),0ECH,6CH	 	;04DA 0C 0C EC 6C
 	DB	3CH,1CH,78H,4 DUP(6CH),0	;04DE 3C 1C 78 6C 6C 6C 6C 00
 	DB	2 DUP(0),70H,18H	 	;04E6 00 00 70 18
 	DB	30H,60H,78H,5 DUP(0),3CH	;04EA 30 60 78 00 00 00 00 00 3C
 	DB	3 DUP(3CH),0AH DUP(0)	 	;04F3 3C 3C 3C 00 00 00 00 00 00 00 00 00 00




 	org	0e000h

 	db	16h dup(?) 


;____________________
;  Сброс системы - фаза 1
;____________________
;_____________________
;  Проверка 16К памяти
;_____________________
c1	dw	c11	 	;адрес возврата
caw	dw	ca3


 	org	0e05bh


;___________________
;  ТЕСТ.01
;	Тест процессора 8086. Осуществляет проверку регистра
;	признаков, команд перехода и считывания-записи
;	общих и сегментных регистров.
;_____________________________________
reset	label	near
start:	cli	 	 	; сброс признака разрешения прерывания
 	mov	ah,0d5h 	;уст признаки SF,CF,ZF,AF
 	sahf
 	jnc	err01	 	;CF=0,в программу ошибок
 	jnz	err01	 	;ZF=0,в программу ошибок
 	jnp	err01	 	;PF=0,в программу ошибок
 	jns	err01	 	;SF=0,в программу ошибок
 	lahf	 	 	;загрузить признаки в AH
 	mov	cl,5	 	;загрузить счетчик
 	shr	ah,cl	 	;выделить бит переноса
 	jnc	err01	 	;признак AF=0
 	mov	al,40h	 	;уст признак переполнения
 	shl	al,1	 	;уст для контроля
 	jno	err01	 	;признак OF не уст
 	xor	ah,ah	 	;уст AH=0
 	sahf	 	 	;уст в исходное состояние SF,CF,ZF,PF
 	jc	err01	 	;признак CF=1
 	jz	err01	 	;признак ZF=1
 	js	err01	 	;признак SF=1
 	jp	err01	 	;признак PF=1
 	lahf	 	 	;загрузить признаки в AH
 	mov	cl,5	 	;загрузить счетчик
 	shr	ah,cl	 	;выделить бит переноса
 	jc	err01	 	;признак IF=1
 	shl	ah,1	 	;контроль, что OF сброшен
 	jo	err01
 	mov	ax,0ffffh	;уст эталона в AX
 	stc
c8:	mov	ds,ax	 	;запись во все регистры
 	mov	bx,ds
 	mov	es,bx
 	mov	cx,es
 	mov	ss,cx
 	mov	dx,ss
 	mov	sp,dx
 	mov	bp,sp
 	mov	si,bp
 	mov	di,si
 	jnc	c9
 	xor	ax,di	 	;проверка всех регистров
 	 	 	 	;эталонами "FFFF", "0000"
 	jnz	err01
 	clc
 	jnc	c8
c9:
 	or	ax,di	 	;нулевым шаблоном все регистры проверены ?
 	jz	c10	 	;ДА - переход к следующему тесту
err01:	jmp   short  start
;_______________________
; ТЕСТ.02
;_______________________
c10:
 	mov	al,0	 	;запретить прерывaния NMI
 	out	0a0h,al
 	out	83h,al	 	;инициализация регистрa страниц ПДП
 	mov	al,99h	 	;уст A,C -ввод, B - вывод
       out	cmd_port,al	 	;запись в регистр режима
 	 	 	 	 	;трехканального порта
 	mov	al,0fch 	 	;блокировка контроля по четности
 	out	port_b,al
 	sub	al,al
 	mov	dx,3d8h
 	out	dx,al	 	;блокировка цветного ЭЛИ
 	inc	al
 	mov	dx,3b8h
 	out	dx,al	 	;блокировка черно-белого ЭЛИ
 	mov	ax,cod	 	;уст сегментного регистра SS
 	mov	ss,ax
 	mov	bx,0e000h	 	;уст начального адреса памяти
 	mov	sp,offset c1	 	;уст адреса возврата
 	jmp	ros
c11:	jne	err01
;------------------------
;  ТЕСТ.03
;   Осуществляет проверку, инициализацию и запуск ПДП и
; таймера 1 для регенерации памяти
;_________________________
;   Блокировка контроллера ПДП

ros:	mov	al,04
 	out	dma08,al

;   Проверка правильности функционирования
;   таймера 1

 	mov	al,54h	 	;выбор таймера 1,LSB, режим 2
 	out	timer+3,al
 	sub	cx,cx
 	mov	bl,cl
 	mov	al,cl	 	;уст начального счетчика таймера в 0
 	out	timer+1,al
c12:
 	mov	al,40h
 	out	timer+3,al
 	in	al,timer+1	;считывание счетчика таймера 1
 	or	bl,al	 	;все биты таймера включены ?
 	cmp	bl,0ffh 	;ДА - сравнение с FF
 	je	c13	 	;биты таймера сброшены
 	loop	c12	 	;биты таймера установлены
 	jmp	short err01	;сбой таймера 1, останов системы
c13:
 	mov	al,bl	 	;уст счетчика таймера 1
 	sub	cx,cx
 	out	timer+1,al
c14:	 	;цикл таймера
 	mov	al,40h
 	out	timer+3,al
 	in	al,timer+1	 	;считывание счетчика таймера 1
 	and	bl,al
 	jz	c15
 	loop	c14	 	;цикл таймера
 	jmp	short err01

;   Инициализация таймера 1

c15:
 	mov	al,54h
 	out	timer+3,al	;запись в регистр режима таймера
 	mov	al,7	;уст коэффициента деления для регенерации
 	out	timer+1,al	;запись в счетчик таймера 1
 	out	dma+0dh,al	;послать гашение ПДП

;   Цикл проверки регистров ПДП

 	mov	al,0ffh 	;запись шаблона FF во все регистры
c16:	mov	bl,al	 	;сохранить шаблон для сравнения
 	mov	bh,al
 	mov	cx,8	 	;уст цикла счетчика
 	mov	dx,dma	 	;уст адреса регистра порта ввода/вывода
c17:	out	dx,al	 	;запись  шаблона в регистр
 	out	dx,al	 	;старшие 16 бит регистра
 	mov	ax,0101h	;изменение AX перед считыванием
 	in	al,dx
 	mov	ah,al	 	;сохранить младшие 16 бит регистра
 	in	al,dx
 	cmp	bx,ax	 	;считан тот же шаблон ?
 	je	c18	 	;ДА - проверка следующего регистра
 	jmp	err01	 	;НЕТ - ошибка
c18:	 	 	 	;выбор следующего регистра ПДП
 	inc	dx	 	;установка адреса следующего
 	 	 	 	;регистра ПДП
 	loop	c17	 	;запись шаблона для следующего регистра
 	not	al	 	  ;уст шаблона в 0
 	jz	c16

;   Инициализация и запуск ПДП

 	mov	al,0ffh 	;уст счетчика 64K для регенерации
 	out	dma+1,al
 	out	dma+1,al
 	mov	al,058h 	;уст режим ПДП, счетчик 0, считывание
 	out	dma+0bh,al	;запись в регистр режима ПДП
 	mov	al,0	 	;доступность контроллера ПДП
 	out	dma+8,al	;уст регистр команд ПДП
 	out	dma+10,al	;доступность канала 0 для регенерации
 	mov	al,41h	 	;уст режим дла канала 1
 	out	dma+0bh,al
 	mov	al,42h	 	;уст режим для канала 2
 	out	dma+0bh,al
 	mov	al,43h	 	;уст режим для канала 3
 	out	dma+0bh,al
;____________________
;   ТЕСТ.04
;
;   Осуществляет считывание-запись эталонов в 16К байт ОЗУ,
; тестирование клавиатуры, установку стека, вектора NMI
; и вектора режима печати экрана ЭЛИ
;___________________
;   Определение об'ема памяти
;   и заполнение памяти данными

 	jmp	ca0

;____________________
;   Инициализация контроллера
;   прерываний 8259
;____________________
c21:
 	mov	al,13h	 	;ICW1 - EDGE, SNGL, ICW4
 	out	inta00,al
 	mov	al,8	 	;УСТ ICW2 - прерывание типа 8(8-F)
 	out	inta01,al
 	mov	al,9	 	;уст ICW4 - BUFFERD , режим 8086
 	out	inta01,al

;   Установка сегмента стека и SP

c25:
 	mov	ax,sta	 	;получить величину стека
 	mov	ss,ax	 	;уст стек
 	mov	sp,offset tos	;стек готов

;   Установка указателя вектора прерывания NMI

 	mov	es:nmi_ptr,offset nmi_int
 	mov	es:nmi_ptr+2,cod
 	jmp	short tst6	;переход к следующему тесту

ros_checksum proc  near
 	mov	cx,8192 	;число байт для сложения
 	xor	al,al
c26:	add	al,cs:[bx]
 	inc	bx	 	;указание следующего байта
 	loop	c26	 	;сложить все байты в модуле ROS
 	or	al,al	 	;сумма = 0 ?
 	ret
ros_checksum endp
;______________________
;   Начальный тест надежности
;______________________
 	assume	cs:code,es:abs0

d1	db	' СБОЙ  ПАРИТЕТА ПАМЯТИ'
d1l	equ	22
d2	db	'parity check 1'
d2l	equ	0eh
;______________________
;   ТЕСТ.06
;	 Тест контроллера прерываний
;	 8259
;_______________________
tst6:
 	sub	ax,ax	 	;уст регистра ES
 	mov	es,ax

;-----уст вектора прерываний 5

 	mov	es:int5_ptr,offset print_screen   ; печать экрана
 	mov	es:int5_ptr+2,cod

;   Проверка регистра масок прерываний (IMR)

 	cli	 	 	;сброс признака разрешения прерываний
 	mov	al,0	 	;уст IMR в 0
 	out	inta01,al
 	in	al,inta01	;считывание IMR
 	or	al,al	 	;IMR=0 ?
 	jnz	d6	 	;IMR не 0,в программу ошибок
 	mov	al,0ffh 	;недоступность прерываний
 	out	inta01,al	;запись в IMR
 	in	al,inta01	;считывание IMR
 	add	al,1	 	;все биты IMR установлены ?
 	jnz	d6	 	;НЕТ - в программу ошибок

;   Контроль ожидания прерывания

 	cld	 	 	; уст признак направления
 	mov	cx,8
 	mov	di,offset int_ptr	; уст адресацию таблицы
d3:
 	mov	ax,offset d11	; установить адрес процедуры прерываний
 	stosw
 	mov	ax,cod	; получить адрес сегмента процедуры
 	stosw
 	add	bx,4	;уст BX для указания следующего значения
 	loop	d3

;   Прерывания размаскированы

 	xor	ah,ah	 	;очистить регистр AH
 	sti	 	 	; установка признака разрешения прерывания
 	sub	cx,cx	 	; ожидание 1 сек любого прерывания,
d4:	loop	d4	 	; которое может произойти
d5:	loop	d5
 	or	ah,ah	 	; прерывание возникло ?
 	jz	d7	 	; нет - к следующему тесту
d6:	mov	dx,101h 	; уст длительности звукового сигнала
 	call	err_beep	; идти в программу звукового сигнала
 	cli
 	hlt	 	 	; останов системы
;__________________
;   ТЕСТ.07
;	 Проверка таймера 8253
;___________________
d7:
 	mov	ah,0	 	; сброс признака прерывания таймера
 	xor	ch,ch	 	; очистить регистр CH
 	mov	al,0feh   ; маскировать все прерывания, кроме LVL 0
 	out	inta01,al	; запись IMR
 	mov	al,00010000b	; выбрать TIM 0, LSD, режим 0, BINARY
 	out	tim_ctl,al  ;записать регистр режима управления таймера
 	mov	cl,16h	 	; уст счетчик программного цикла
 	mov	al,cl	 	; установить счетчик таймера 0
 	out	timero,al	; записать счетчик таймера 0
d8:	test	ah,0ffh 	; прерывание таймера 0 произошло ?
 	jnz	d9	 	; да - таймер считал медленно
 	loop	d8	 	; ожидание прерывания определенное время
 	jmp	short d6   ;прерывание таймера 0 не произошло - ошибка
d9:	mov	cl,18	 	; уст счетчик программного цикла
 	mov	al,0ffh 	; записать счетчик таймера 0
 	out	timero,al
 	mov	ah,0	 	; сброс признака,полученного прерывания
 	mov	al,0feh 	; недоступность прерываний таймера 0
 	out	inta01,al
d10:	test	ah,0ffh 	; прерывание таймера 0 произошло ?
 	jnz	d6	 	; да - таймер считает быстро
 	loop	d10	 	; ожидание прерывания определенное время
 	jmp	tst8	 	; переход к следующему тесту
;____________________
;   Программа обслуживания
;   временного прерывания
;____________________
d11	proc	near
 	mov	ah,1
 	push	ax	 	; хранить регистр AX
 	mov	al,0ffh 	; размаскировать все прерывания
 	out	inta01,al
 	mov	al,eoi
 	out	inta00,al
 	pop	ax	 	; восстановить регистр AX
 	iret
d11	endp

nmi_int proc	near
 	push	ax	 	; хранить регистр AX
 	in	al,port_c
 	test	al,40h	 	; ошибка паритета при вводе/выводе ?
 	jz	d12	 	; да - признак сбрасывается в 0
 	mov	si,offset d1	; адрес поля сообщения об ошибке
 	mov	cx,d1l	 	; длина поля сообщения об ошибке
 	jmp	short d13	; отобразить ошибку на дисплее
d12:
 	test	al,80h
 	jz	d14
 	mov	si,offset d2	; адрес поля сообщения об ошибке
 	mov	cx,d2l	 	; длина поля сообщения об ошибке
d13:
 	mov	ax,0	 	; инициировать и установить режим ЭЛИ
 	int	10h	 	; вызвать процедуру VIDEO_IO
 	call	p_msg	 	; распечатать ошибку
 	cli
 	hlt	 	 	; останов системы
d14:
 	pop	ax	 	; восстановить AX
 	iret
nmi_int endp
;____________________
;   Начальный тест надежности
;____________________
 	assume	cs:code,ds:data

e1	db	' 201'
e1l	equ	04h
e1n	db	' (0)'
 	db	' (1)'
e1nl	equ	4

;   Выполнение программы БСУВВ,
;   генерирующей вектора прерываний

tst8:
 	cld	 	 	; установить признак направления вперед
 	mov	di,offset video_int   ; уст адреса области прерываний
 	push	cs
 	pop	ds	 	; уст адреса таблицы векторов
 	mov	si,offset vector_table+20h  ; смещение VECTOR_TABLE+32
 	mov	cx,20h
 	rep	movsw	 	; передать таблицу векторов в память

;   Установка таймера 0 в режим 3

 	mov	al,0ffh
 	out	inta01,al
 	mov	al,36h	 	; выбор счетчика 0,считывания-за-
; писи младшего,затем старшего байта счетчика,уст режима 3
 	out	timer+3,al	; запись режима таймера
 	mov	al,0c7h
 	out	timer,al	; записать младшую часть счетчика
 	mov	al,0dbh
 	out	timer,al	; записать старшую часть счетчика


 	assume	ds:data
 	mov	ax,dat	 	; DS - сегмент данных
 	mov	ds,ax
e3:
 	cmp	reset_flag,1234h
 	jz	e3a
 	call	bct	;загрузка знакогенератора Ч/Б ЭЛИ
;_____________________
;   ТЕСТ.08
;	 Инициализация и запуск
;	 контроллера ЭЛИ
;______________________
e3a:	in	al,port_a	; считывание состояния переключателей
 	mov	ah,0
 	mov	equip_flag,ax	; запомнить считанное состояние пере-
 	 	 	 	; ключателей
 	and	al,30h	 	; выделить переключатели ЭЛИ
 	jnz	e7	 	; переключатели ЭЛИ установлены в 0 ?
 	jmp	e19	 	; пропустить тест ЭЛИ
e7:
 	xchg	ah,al
 	cmp	ah,30h	 	; адаптер ч/б ?
 	je	e8	 	; да - установить режим для ч/б адаптера
 	inc	al	 ; уст цветной режим для цветного адаптера
 	cmp	ah,20h	 	; режим 80х25 установлен ?
 	jne	e8	 	; нет - уст режим для 40х25
 	mov	al,3	 	; установить режим 80х25
e8:
 	push	ax	 	; хранить режим ЭЛИ в стеке
 	sub	ah,ah	 	;
 	int	10h
 	pop	ax
 	push	ax
 	mov	bx,0b000h
 	mov	dx,3b8h 	; регистр режима для ч/б
 	mov	cx,2048 	; счетчик байт для ч/б адаптера
 	mov	al,1	 	; уст режим для ч/б адаптера
 	cmp	ah,30h	 	; ч/б адаптер ЭЛИ подключен ?
 	je	e9	 	; переход к проверке буфера ЭЛИ
 	mov	bx,0b800h
 	mov	dx,3d8h 	; регистр режима для цветного адаптера
 	mov	cx,2000h
 	dec	al	 	; уст режим в 0 для цветного адаптера
;
;	Проверка буфера ЭЛИ
;
e9:
 	out	dx,al	 	; блокировка ЭЛИ для цветного адаптера
 	mov	es,bx
 	mov	ax,dat	 	; DS - сегмент данных
 	mov	ds,ax
 	cmp	reset_flag,1234h
 	je	e10
 	mov	ds,bx	 	;
 	call	stgtst_cnt	; переход к проверке памяти
 	je	e10
 	mov	dx,102h
 	call	err_beep

;___________________________
;
;   ТЕСТ.09
;	 Осуществляет проверку формирования строк в буфере ЭЛИ
;_________________________
e10:
 	pop	ax   ; получить считанные переключатели ЭЛИ в AH
 	push	ax	 	; сохранить их
 	mov	ah,0
 	int	10h
 	mov	ax,7020h	; запись пробелов в режиме реверса
 	sub	di,di	 	; установка начала области
 	mov	cx,40	 	;
 	cld	    ; установить признак направления для уменьшения
 	rep	stosw	 	; записать в память
;______________________
;    ТЕСТ.10
;	  Осуществляет проверку линий интерфейса ЭЛИ
;______________________
 	pop	ax	 	; получить считанные переключатели
 	push	ax	 	; сохранить их
 	cmp	ah,30h	 	; ч/б адаптер подключен ?
 	mov	dx,03bah	; уст адрес порта состояния ч/б дисплея
 	je	e11	 	; да - переход к следующей строке
 	mov	dx,03dah	; цветной адаптер подключен
;
;	Тест строчной развертки
;
e11:
 	mov	ah,8
e12:
 	sub	cx,cx
e13:	in	al,dx	    ;считывание порта состояния контроллера СМ607
 	and	al,ah	 	; проверка строки
 	jnz	e14
 	loop	e13
 	jmp	short e17	; переход к сообщению об ошибке
e14:	sub	cx,cx
e15:	in	al,dx	  ;считывание порта состояния контроллера СМ607
 	and	al,ah
 	jz	e16
 	loop	e15
 	jmp	short e17
;
;	Следующий строчный импульс
;
e16:
 	mov	cl,3	 	; получить следующий бит для контроля
 	shr	ah,cl
 	jnz	e12
 	jmp	short e18	; отобразить курсор на экране
;
;	Сообщение об ошибке конттроллера СМ607
;
e17:
 	mov	dx,103h
 	call	err_beep
;
;	Отображение курсора на экране
;
e18:
 	pop	ax	 	; получить считанные переключатели в AH
 	mov	ah,0	 	; установить режим
 	int	10h
;______________________
;   ТЕСТ.11
;	 Дополнительный тест памяти
;______________________
 	assume	ds:data
e19:
 	mov	ax,dat
 	mov	ds,ax
 	cmp	reset_flag,1234h
 	je	e22

;   Проверка любой действительной памяти
;   на считывание и запись

 	jmp	e190

;   Печать адреса и эталона, если
;   произошла ошибка данных
 	org	0e367h


osh:
 	mov	ch,al	 	;
 	mov	al,dh	 	; получить измененный адрес
 	mov	cl,4
 	shr	al,cl	 	;
 	call	xlat_print_cod	; преобразование и печать кода
 	mov	al,dh
 	and	al,0fh
 	call	xlat_print_cod	; преобразование и печать кода
 	mov	al,ch	 	; получить следующий шаблон
 	mov	cl,4
 	shr	al,cl
 	call	xlat_print_cod	; преобразование и печать кода
 	mov	al,ch	 	;
 	and	al,0fh	 	;
 	call	xlat_print_cod	; преобразование и печать кода
 	and	si,0001
 	shl	si,1
 	shl	si,1
 	add	si,offset e1n
 	mov	cx,e1nl
 	call	pmsg
 	mov	si,offset e1	; установить адрес поля сообщения
 	 	 	 	; об ошибке
 	mov	cx,e1l	 	; получить счетчик поля сообщения об ошибке
 	call	p_msg	 	; печать ошибки
e22:
 	jmp	tst12	 	; переход к следующему тесту

;_____________________
;
;   Процедура вывода на экран сообщения об ошибке в коде ASCII
;
;_______________________

xlat_print_cod proc near
 	push	ds	 	; сохранить DS
 	push	cs
 	pop	ds
 	mov	bx,offset f4e	; адрес таблицы кодов ASCII
 	xlatb
 	mov	ah,14
 	mov	bh,0
 	int	10h
 	pop	ds
 	ret
xlat_print_cod endp
;______________________
;   Сброс системы - фаза 4
;______________________
;
;   Коды сообщений об ошибках
;_______________________

 	assume	cs:code,ds:data
f1	db	' 301'
f1l	equ	4h	 	; сообщение клавиатуры
f2	db	'131'
f2l	equ	3h	 	; сообщение кассеты
f3	db	'601'
f3l	equ	3h	 	; сообщение НГМД

f4	label	word
 	dw	378h
f4e	label	word
ascii_tbl db	'0123456789abcdef'
;______________________
;   ТЕСТ.12
;   Тест клавиатуры
;______________________
tst12:
 	mov	ax,dat
 	mov	ds,ax
 	call	kbd_reset	; Сброс клавиатуры
 	jcxz	f6	 	; печать ошибки, если нет прерывания
 	mov	al,4dh	 	; доступность клавиатуры
 	out	port_b,al
 	cmp	bl,0aah 	; код сканирования 'AA' ?
 	jne	f6	 	; нет - печать ошибки

;   Поиск "залипших" клавиш

 	mov	al,0cch       ; сброс клавиатуры, уст синхронизации
 	out	port_b,al
 	mov	al,4ch	      ; доступность клавиатуры
 	out	port_b,al
 	sub	cx,cx
;
;	Ожидание прерывания клавиатуры
;
f5:
 	loop	f5	 	; задержка
 	in	al,kbd_in	; получение кода сканирования
 	cmp	al,0	 	; код сканирования равен 0 ?
 	je	f7	 	; да - продолжение тестирования
 	mov	ch,al	 	; сохранить код сканирования
 	mov	cl,4
 	shr	al,cl
 	call	xlat_print_cod	; преобразование и печать
 	mov	al,ch	 	; восстановить код сканирования
 	and	al,0fh	 	; выделить младший байт
 	call	xlat_print_cod	; преобразование и печать
f6:	mov	si,offset f1	; получить адрес поля сообщения об
 	 	 	 	; ошибке
 	mov	cx,f1l	 	 ; длина поля сообщения об ошибке
 	call	p_msg	 	 ; вывод сообщения об ошибке на экран

;   Установка таблицы векторов прерываний

f7:
 	sub	ax,ax
 	mov	es,ax
 	mov	cx,24*2 	; получить счетчик векторов
 	push	cs
 	pop	ds
 	mov	si,offset vector_table	 ; адрес таблицы векторов
 	mov	di,offset int_ptr
 	cld
 	rep	movsw
 	test	eq_fl,08h
 	jz	alzo


 	call	disk_setup

;
;   Проверка памяти от C8000 до F6000 по 2К
;

rom_scan:
 	mov	dx,0c800h
rom_scan_1:
 	mov	ds,dx
 	sub	bx,bx
 	mov	ax,[bx]
 	push	bx
 	pop	bx
 	cmp	ax,0aa55h
 	jnz	next_rom
 	call	rom_check
 	jmp	are_we_done
next_rom:
 	add	dx,0080h
are_we_done:
 	cmp	dx,0f600h
 	jl	rom_scan_1
 	jmp	alzo

 	org	0e47dh

;______________________
;   ТЕСТ.14
;   Осуществляет проверку НГМД
;______________________
alzo:	mov	ax,dat	 	; уст. регистр DS
 	mov	ds,ax
 	mov	al,0fch  ; доступность прерываний таймера и клавиатуры
 	out	inta01,al
 	mov	al,byte ptr equip_flag	; получить состояние переклю-
 	 	 	 	 	; чателей
 	test	al,01h	 	; первоначальная загрузка с НГМД ?
 	jnz	f10	 	; да - проверка управления НГМД
 	jmp	f23
f10:
 	mov	al,0bch 	; доступность прерываний с НГМД,
 	out	inta01,al	; клавиатуры и таймера
 	mov	ah,0	 	; сброс контроллера НГМД
 	int	13h	 	; переход к сбросу НГМД
 	test	ah,0ffh 	; состояние верно ?
 	jnz	f13	 	; нет - сбой устройства

;   Включить мотор устройства 0

 	mov	dx,03f2h	; получить адрес адаптера НГМД
 	mov	al,1ch	 	; включить мотор
 	out	dx,al
 	sub	cx,cx

;    Ожидание включения мотора НГМД

f11:
 	loop	f11
f12:	 	 	 	; ожидание мотора 1
 	loop	f12
 	xor	dx,dx
 	mov	ch,1	 	; выбор первой дорожки
 	mov seek_status,dl
 	call	seek	 	; переход к рекалибровке НГМД
 	jc	f13	 	; перейти в программу ошибок
 	mov	ch,34	 	; выбор 34 дорожки
 	call	seek
 	jnc	f14	 	; выключить мотор

;    Ошибки НГМД

f13:
 	mov	si,offset f3	; получить адрес поля сообщения об
 	 	 	 	; ошибке
 	mov	cx,f3l	 	; установить счетчик
 	call	p_msg	 	; идти в программу ошибок

;   Выключить мотор устройства 0

f14:
 	mov	al,0ch	 	; выключить мотор устройства 0
 	mov	dx,03f2h	; уст адрес порта управления НГМД
 	out	dx,al

;   Установка печати и базового адреса
;   адаптера стыка С2, если устройства подключены

f15:
 	mov	buffer_head,offset kb_buffer  ; уст параметров
 	 	 	 	 	      ; клавиатуры
 	mov	buffer_tail,offset kb_buffer
 	mov	buffer_end,offset kb_buffer_end
 	mov	buffer_start,offset kb_buffer
 	cmp	bp,0000h
 	jz	dal
 	mov	dx,3
 	call	err_beep
 	mov	si,offset f39
 	mov	cx,32
 	call	p_msg
err_wait:
 	mov	ah,0
 	int	16h
 	cmp	ah,3bh
 	jnz	err_wait
dal:	sub	ah,ah
 	mov	al,crt_mode
 	int	10h
 	mov	bp,offset f4	; таблица PRT_SRC
 	mov	si,0
f16:
 	mov	dx,cs:[bp]	; получить базовый адрес печати
 	mov	al,0aah 	; записать данные в порт А
 	out	dx,al
 	sub	al,al
 	in	al,dx	 	; считывание порта А
 	cmp	al,0aah 	; шаблон данных тот же
 	jne	f17	    ; нет - проверка следующего устройства печати
 	mov	word ptr printer_base[si],dx  ;да-уст базовый адрес
 	inc	si	 	; вычисление следующего слова
 	inc	si
f17:
 	inc	bp	 	; указать следующий базовый адрес
 	inc	bp
 	cmp	bp,offset f4e	; все возможные адреса проверены ?
 	jne	f16	 	; нет, к проверке следующего адреса печати
 	mov	bx,0
 	mov	dx,3ffh 	; проверка подключения адаптера 1 стыка С2
 	mov	al,8ah
 	out	dx,al
 	mov	dx,2ffh
 	out	dx,al
 	mov	dx,3fch
 	mov	al,0aah
 	out	dx,al
 	inc	dx
 	in	al,dx
 	cmp	al,0aah
 	jnz	f18
 	mov  word ptr rs232_base[bx],3f8h  ; уст адрес адаптера 1
 	inc	bx
 	inc	bx
f18:	mov	dx,2fch 	; проверка подключения адаптера 2 стыка С2
 	mov	al,0aah
 	out	dx,al
 	inc	dx
 	in	al,dx
 	cmp	al,0aah
 	jnz	f19
 	mov  word ptr rs232_base[bx],2f8h   ; уст адрес адаптера 2
 	inc	bx
 	inc	bx



;_____Установка EQUIP_FLAG для инди-
;     кации номера печати

f19:

 	inc	dx	 	;
 	mov	al,8	 	; сброс низкого уровня IRQ3
 	OUT	DX,AL
 	mov	dx,3feh
 	out	dx,al	 	;сброс низкого уровня IRQ4
 	mov	al,0a4h
 	out	21h,al	 	; разрешить прерывания адаптера С2

 	mov	ax,si
 	mov	cl,3
 	ror	al,cl
 	or	al,bl
 	mov	byte ptr equip_flag+1,al
 	mov	dx,201h
 	in	al,dx
 	test	al,0fh
 	jnz	f20	 	 	   ; проверка адаптера игр
 	or	byte ptr equip_flag+1,16
f20:

;   Разрешить прерывания NMI,закрыть маски адаптера стыка С2

 	mov	al,0bch
 	out	21h,al


 	in	al,port_b
 	or	al,30h
 	out	port_b,al	; сброс ошибки паритета
 	and	al,0cfh
 	out	port_b,al
 	mov	al,80h	 	; разрешение прерываний NMI
 	out	0a0h,al
 	mov	dx,1
 	call	err_beep	; переход к подпрограмме звукового сигнала
f21:
 	int	19h	 	; переход к программе первоначальной загрузки
f23:
 	jmp	f15

;    Установка длительности звукового сигнала

 	assume	cs:code,ds:data
err_beep proc	near
 	pushf	 	 	; сохранить признаки
 	cli	 	 	; сброс признака разрешения прерывания
 	push	ds	 	; сохранить DS
 	mov	ax,dat	 	; DS - сегмент данных
 	mov	ds,ax
 	or	dh,dh
 	jz	g3
g1:	 	 	 	 ; длинный звуковой сигнал
 	mov	bl,6	 	 ; счетчик для звуковых сигналов
 	call	beep	 	 ; выполнить звуковой сигнал
g2:	loop	g2	 	 ; задержка между звуковыми сигналами
 	dec	dh
 	jnz	g1
g3:	 	 	 	 ; короткий звуковой сигнал
 	mov	bl,1   ; счетчик для короткого звукового сигнала
 	call	beep	 	; выполнить звуковой сигнал
g4:	loop	g4	 	; задержка между звуковыми сигналами
 	dec	dl	 	;
 	jnz	g3	 	; выполнить
g5:	loop	g5	 	; длинная задержка перед возвратом
g6:	loop	g6
 	pop	ds	 	; восстановление DS
 	popf	 	   ; восстановление первоначальных признаков
 	ret	 	 	; возврат к программе
err_beep	endp

;   Подпрограмма звукового сигнала

beep	proc	near
 	mov	al,10110110b	; таймер 2,младший и старший счет-
 	 	 	 	; чики, двоичный счет
 	out	timer+3,al	; записать в регистр режима
 	mov	ax,45eh 	; делитель
 	out	timer+2,al	; записать младший счетчик
 	mov	al,ah
 	out	timer+2,al	; записать старший счетчик
 	in	al,port_b	; получить текущее состояние порта
 	mov	ah,al	 	; сохранить это состояние
 	or	al,03	 	; включить звук
 	out	port_b,al
 	sub	cx,cx	 	; установить счетчик ожидания
g7:	loop	g7	 	; задержка перед выключением
 	dec	bl	 	; задержка счетчика закончена ?
 	jnz	g7	; нет - продолжение подачи звукового сигнала
 	mov	al,ah	 	; восстановить значение порта
 	out	port_b,al
 	ret	 	 	; возврат к программе
beep	endp
;_____________________
;   Эта процедура вызывает программный
;   сброс клавиатуры
;_____________________
kbd_reset proc	near
 	mov	al,0ch	   ; установить низкий уровень синхронизации
 	out	port_b,al	; записать порт B
 	mov	cx,30000	; время длительности низкого уровня
g8:	loop	g8
 	mov	al,0cch 	; уст CLK
 	out	port_b,al
sp_test:
 	mov	al,4ch	 	; уст высокий уровень синхронизации
 	out	port_b,al
 	mov	al,0fdh 	; разрешить прерывания клавиатуры
 	out	inta01,al	; записать регистр масок
 	sti	 	 	; уст признака разрешения прерывания
 	mov	ah,0
 	sub	cx,cx	 	; уст счетчика ожидания прерываний
g9:	test	ah,0ffh 	; прерывание клавиатуры возникло ?
 	jnz	g10   ;  да - считывание возвращенного кода сканирования
 	loop	g9	 	; нет - цикл ожидания
g10:	in	al,port_a   ; считать код сканирования клавиатуры
 	mov	bl,al	 	; сохранить этот код
 	mov	al,0cch 	; очистка клавиатуры
 	out	port_b,al
 	ret	 	 	; возврат к программе
kbd_reset	endp
;_____________________
;   Эта программа выводит на экран дисплея
;   сообщения об ошибках
;
;     Необходимые условия:
;   SI = адрес поля сообщения об ошибке
;   CX = длина поля сообщения об ошибке
;   Максимальный размер передаваемой
;   информации - 36 знаков
;
;______________________
p_msg	proc	near
 	mov	ax,dat
 	mov	ds,ax
 	mov	bp,si
g12:
 	mov	al,cs:[si]	; поместить знак в AL
 	inc	si	 	; указать следующий знак
 	mov	bh,0	 	; установить страницу
 	mov	ah,14	 	; уст функцию записи знака
 	int	10h	 	; и записать знак
 	loop	g12	; продолжать до записи всего сообщения
 	mov	ax,0e0dh   ; переместить курсор в начало строки
 	int	10h
 	mov	ax,0e0ah  ; переместить курсор на следующую строку
 	int	10h
 	ret
p_msg	endp

;   Таблица кодов русских больших букв (заглавных)

rust2	label	byte
 	db	1bh,'!@#$',37,05eh,'&*()_+'
 	db	08h,0
 	db	0b9h,0c6h,0c3h,0bah,0b5h,0bdh,0b3h,0c8h
 	db	0c9h,0b7h,0b6h,0cdh,0dh,-1,0c4h,0cbh
 	db	0b2h,0b0h,0bfh,0c0h,0beh,0bbh,0b4h,27h
 	db	'"',0b1h,0ceh,7ch,0cfh,0c7h,0c1h,0bch,0b8h
 	db	0c2h,0cch,'<>?',0c5h,000,-1,' ',0cah



;___int 19_____________
;   Программа загрузки системы с НГМД
;
; Программа считывает содержимое дорожки 0 сектора 1 в
; ячейку boot_locn (адрес 7C00,сегмент 0)
;   Если НГМД отсутствует или произошла аппаратная ошибка,
; устанавливается прерывание типа INT 18H, которое вызывает
; выполнение программ тестирования и инициализации
; системы
;
;_________________________
 	assume	cs:code,ds:data
boot_strap proc near

 	sti	 	      ; установить признак разрешения прерывания
 	mov	ax,dat	      ; установить адресацию
 	mov	ds,ax
 	mov	ax,equip_flag ; получить состояние переключателей
 	test	al,1	      ; опрос первоначальной загрузки
 	jz	h3

;   Система загружается с НГМД
;   CX содержит счетчик повторений

 	mov	cx,4	 	; установить счетчик повторений
h1:	 	 	 	; первоначальная загрузка
 	push	cx	 	; сохранить счетчик повторений
 	mov	ah,0	 	; сброс НГМД
 	int	13h
 	jc	h2	 	; если ошибка,повторить
 	mov	ah,2	 	; считать сектор 1
 	mov	bx,0	 	;
 	mov	es,bx
 	mov	bx,offset boot_locn
 	mov	dx,0	 	;
 	mov	cx,1	 	; сектор 1 , дорожка 0
 	mov	al,1	 	; считывание первого сектора
 	int	13h
h2:	pop	cx	 	; восстановить счетчик повторений
 	jnc	h4	 	; уст CF при безуспешном считывании
 	loop	h1	 	; цикл повторения

;   Загрузка с НГМД недоступна

h3:	 	 	 	; кассета
 	jmp	err01	; отсутствует дискет загрузки

;   Загрузка завершилась успешно

h4:
 	db	0eah,00h,7ch,00h,00h
boot_strap	endp
;--------------------
;   Эта программа посылает байт в контроллер адаптера НГМД
; после проверки корректности управления и готовности
; контроллера.
;   Программа ожидает байт состояния определенное время
; и проверяет готовность НГМД к работе.
;
;   ВВОД   (AH) - выводимый байт
;
;   ВЫВОД  CY=0 - успешно,
;	   CY=1 - не успешно.Состояние
;	   НГМД анализируется.
;-----------------------
nec_output proc near
 	push	dx	 	; сохранить регистры
 	push	cx
 	mov	dx,03f4h	; состояние порта
 	xor	cx,cx	 	; счетчик времени вывода
j23:
 	in	al,dx	 	; получить состояние
 	test	al,040h 	; проверка управляющих бит
 	jz	j25	 	; биты управления нормальные
 	loop	j23
j24:
 	or	diskette_status,time_out
 	pop	cx
 	pop	dx	; установить код ошибки и восстановить регистры
 	pop	ax	 	; адрес возврата
 	stc	 	 	;
 	ret

j25:
 	xor	cx,cx	 	; обнуление счетчика
j26:
 	in	al,dx	 	; получить состояние
 	test	al,080h 	; проверка готовности
 	jnz	j27	 	; да - идти на выход
 	loop	j26	 	; повторить
 	jmp	short j24	; ошибка состояния
j27:	 	 	 	; выход
 	mov	al,ah	 	; получить байт
 	mov	dx,03f5h	; переслать байт данных в порт
 	out	dx,al
 	pop	cx	 	; восстановить регистры
 	pop	dx
 	ret	 	 	;
nec_output	endp

;___int 16_________________
;
;   Программа поддержки клавиатуры
;
;   Эта программа считывает в регистр
; AX код сканирования клавиши и код
; ASCII из буфера клавиатуры.
;
;   Программа выполняет три функции, код
; которых задается в регистре AH:
;
;    AH=0 - считать следующий символ
;	     из буфера.При выходе код
;	     сканирования в AH,код
;	     ASCII в AL.
;   AH=1 - установить ZF, если код
;	     ASCII прочитан:
;
;	     ZF=0 - буфер заполнен,
;	     ZF=1 - буфер пустой.
;   При выходе в AX помещен адрес вершины буфера клавиатуры.
;   AH=2 - возврат текущего состояния в регистр AL
;	      из постоянно распределенной области памяти с
;	   адресом 00417H.
;
;   При выполнении программ клавиатуры используются флажки,
; которые устанавливаются в постоянно распределенной области
; памяти по адресам 00417H и 00418H и имеют значение:
;   00417H
;	  0 - правое переключение регистра;
;	  1 - левое переключение регистра;
;	     2 - УПР;
;	  3 - ДОП;
;	  4 - ФСД;
;	  5 - ЦИФ;
;	  6 - ФПБ;
;	  7 - ВСТ;
;   00418H
;	  0 - состояние клавиши ЛАТ между нажатием и отжатием;
;	  1 - ЛАТ;
;	  2 - Р/Л;
;	  3 - пауза;
;	  4 - ФСД;
;	  5 - ЦИФ;
;	  6 - ФПБ;
;	  7 - ВСТ.
;
;   Флажки, соответствующие разрядам 4-7 постоянно распределенной
; области памяти с адресом 00417H, устанавливаются по нажатию
; клавиш ВСТ, ФПБ, ЦИФ, ФСД и сохраняют свои значения до сле-
; дующего нажатия соответствующей клавиши.
; Одноименные флажки, соответствующие разрядам 4-7 постоянно
; распределенной области памяти с адресом 00418H, и флажки
; ДОП, УПР, левое переключение регистра, правое переключение
; регистра, Р/Л устанавливаются по нажатию клавиш и сбрасываются
; по отжатию.
;
;------------------------------
 	assume	cs:code,ds:data


k4	proc	near
 	add	bx,2
 	cmp  bx,buffer_end	 	 ; конец буфера ?
 	jne	k5	 	 	 ; нет - продолжить
 	mov	bx,buffer_start 	 ; да - уст начала буфера
k5:
 	ret
k4	endp

error_beep proc near
 	push	ax
 	push	bx
 	push	cx
 	mov	bx,0c0h
 	in	al,kb_ctl
 	push	ax
k65:
 	and	al,0fch
 	out	kb_ctl,al
 	mov	cx,48h
k66:	loop	k66
 	or	al,2
 	out	kb_ctl,al
 	mov	cx,48h
k67:	loop	k67
 	dec	bx
 	jnz	k65
 	pop	ax
 	out	kb_ctl,al
 	pop	cx
 	pop	bx
 	pop	ax
 	ret
error_beep	endp

;---

k54:
 	cmp	al,59
 	jb	k55
 	mov	al,0
 	jmp	 k57

k55:	mov	bx,offset k10
 	test	kb_flag_1,lat
 	jz	k99

;---

k56:
 	dec	al
 	xlat	cs:k11

;---

k57:
 	cmp	al,-1
 	je	k59
 	cmp	ah,-1
 	je	k59
;---

k58:
 	test	kb_flag,caps_state
 	jz	k61

;---
 	test	kb_flag_1,lat
 	jnz	k88
 	jmp	k89
k88:
 	test	kb_flag,left_shift+right_shift
 	jz	k60

;----------

 	cmp	al,'A'
 	jb	k61
 	cmp	al,'Z'
 	ja	k61
 	add	al,'a'-'A'
 	jmp	 k61

k59:
 	jmp	k26


k60:
 	cmp	al,'a'
 	jb	k61
 	cmp	al,'z'
 	ja	k61
 	sub	al,'a'-'A'

k61:
 	mov	bx,buffer_tail
 	mov	si,bx
 	call   k4
 	cmp	bx,buffer_head
 	je	k62
 	mov	word ptr [si],ax
 	mov	buffer_tail,bx
 	jmp	k26
k99:	mov	bx,offset rust
 	jmp k56

;---

k62:
 	call	error_beep
 	jmp	k26

;---

k63:
 	sub	al,59
k64:
 	xlat	cs:k9
 	mov	ah,al
 	mov	al,0
 	jmp	 k57


;---
 	org	0e82eh
keyboard_io proc	far
 	sti	 	 	;
 	push	ds
 	push	bx
 	mov	bx,dat
 	mov	ds,bx	 	; установить сегмент данных
 	or	ah,ah	 	; AH=0
 	jz	k1	     ; переход к считыванию следующего символа
 	dec	ah	 	; AH=1
 	jz	k2	     ; переход к считыванию кода ASCII
 	dec	ah	 	     ; AH=2
 	jz	k3	     ; переход к получению байта состояния
 	pop	bx	 	     ; восстановить регистр
 	pop	ds
 	iret

;   Считывание кода сканирования и кода ASCII из буфера клавиатуры
;
k1:
 	sti	 	; уст признака разрешения прерывания
 	nop	 	 	; задержка
 	cli	 	; сброс признака разрешения прерывания
 	mov	bx,buffer_head	; уст вершину буфера по чтению
 	cmp	bx,buffer_tail	; сравнить с вершиной буфера по записи
 	jz	k1
 	mov	ax,word ptr [bx] ; получить код сканирования и код ASCII
 	call	k4
 	mov	buffer_head,bx	; запомнить вершину буфера по чтению
 	pop	bx	 	; восстановить регистр
 	pop	ds	 	; восстановить сегмент
 	iret	 	 	; возврат к программе

;   Считать код ASCII

k2:
 	cli	 	; Сброс признака разрешения прерывания
 	mov	bx,buffer_head	; получить указатель вершины буфера
 	 	 	 	; по чтению
 	cmp	bx,buffer_tail	; сравнить с вершиной буфера по записи
 	mov	ax,word ptr [bx]
 	sti	 	 	; уст признак разрешения прерывания
 	pop	bx	 	; восстановить регистр
 	pop	ds	 	; восстановить сегмент
 	ret	2

;   Получение младшего байта состояния (флажков)

k3:
 	mov	al,kb_flag	; получить младший байт состояния     на
 	pop	bx	 	; восстановить регистр
 	pop	ds	 	; восстановить сегмент
 	iret	 	 	; возврат к программе
keyboard_io	endp

;   Таблица кодов сканирования управляющих клавиш

k6	label	byte
 	db	ins_key
 	db	caps_key,num_key,scroll_key,alt_key,ctl_key
 	db	left_key,right_key
 	db	inv_key_l
 	db	inv_key_r,lat_key,rus_key
k6l	equ	0ch

;   Таблица масок нажатых управляющих клавиш

k7	label	byte
 	db	ins_shift
 	db	caps_shift,num_shift,scroll_shift,alt_shift,ctl_shift
 	db	left_shift,right_shift


;   Таблица кодов сканирования при нажатой клавише УПР для
; кодов сканирования клавиш меньше 59

k8	db	27,-1,0,-1,-1,-1,30,-1
 	db	-1,-1,-1,31,-1,127,-1,17
 	db	23,5,18,20,25,21,9,15
 	db	16,27,29,10,-1,1,19
 	db	4,6,7,8,10,11,12,-1,-1
 	db	-1,-1,28,26,24,3,22,2
 	db	14,13,-1,-1,-1,-1,-1,-1
 	db	' ',-1

;   Таблица кодов сканирования при нажатой клавише УПР для
; кодов сканирования клавиш больше 59
k9	label	byte
 	db	94,95,96,97,98,99,100,101
 	db	102,103,-1,-1,119,-1,132,-1
 	db	115,-1,116,-1,117,-1,118,-1
 	db	-1

;   Таблица кодов ASCII нижнего регистра клавиатуры

k10	label	byte
 	db	27,'1234567890-='
 	db	08h,09h
 	db	'qwertyuiop[]',0dh,-1,'asdfghjkl;:',60h,7eh
 	db	05ch,'zxcvbnm',',./{'
 	db	'*',-1,' }'

;   Таблица кодов ASCII верхнего регистра клавиатуры

k11	label	byte
 	db	27,'!@#$',37,05eh,'&*()_+'
 	db	08h,0
 	db	'QWERTYUIOP',-1,-1,0dh,-1
 	db	'ASDFGHJKL'
 	db	027h,'"',-1,-1,7ch
 	db	'ZXCVBNM'
 	db	'<>?',-1,0,-1,' ',-1

;   Таблица кодов сканирования клавиш Ф11 - Ф20 (на верхнем
; регистре Ф1 - Ф10)

k12	label	byte
 	db	84,85,86,87,88,89,90
 	db	91,92,93

;   Таблица кодов сканирования одновременно нажатых клавиш
; ДОП и Ф1 - Ф10

k13	label byte
 	db	104,105,106,107,108
 	db	109,110,111,112,113

;   Таблица кодов правого пятнадцатиклавишного поля на верхнем
; регистре

k14	label	byte
 	db	'789-456+1230.'

;   Таблица кодов правого пятнадцатиклавишного поля на нижнем
; регистре

k15	label byte
 	db	71,72,73,-1,75,-1,77
 	db	-1,79,80,81,82,83

 	org	0e987h

;----INT 9--------------------------
;
;    Программа обработки прерывания клавиатуры
;
; Программа считывает код сканирования клавиши в регистр AL.
; Единичное состояние разряда 7 в коде сканирования означает,
; что клавиша отжата.
;   В результате выполнения программы в регистре AX формируется
; слово, старший байт которого (AH) содержит код сканирования,
; а младший (AL) - код ASCII. Эта информация помещается в буфер
; клавиатуры. После заполнения буфера подается звуковой сигнал.
;
;-----------------------------------

kb_int proc far
 	sti	 	   ; установка признака разрешения прерывания
 	push	ax
 	push	bx
 	push	cx
 	push	dx
 	push	si
 	push	di
 	push	ds
 	push	es
 	cld	 	       ; установить признак направления вперед
 	mov	ax,dat	       ; установить адресацию
 	mov	ds,ax
 	in	al,kb_dat      ; считать код сканирования
 	push	ax
 	in	al,kb_ctl      ; считать значение порта 61
 	mov	ah,al	       ; сохранить считанное значение
 	or	al,80h	       ; установить бит 7 порта 61
 	out	kb_ctl,al      ; для работы с клавиатурой
 	xchg	ah,al	       ; восстановить значение порта 61
 	out	kb_ctl,al
 	pop	ax	       ; восстановить код сканирования
 	mov	ah,al	       ; и сохранить его в AH

;---

 	cmp	al,0ffh  ; сравнение с кодом заполнения буфера
 	 	 	 ; клавиатуры
 	jnz	k16	 	; продолжить
 	jmp	k62	; переход на звуковой сигнал по заполнению
 	 	 	; буфера клавиатуры

k16:
 	and	al,07fh 	; сброс бита отжатия клавиши
 	push	cs
 	pop	es
 	mov	di,offset k6  ; установить адрес таблицы сканирования
 	 	 	      ; управляющих клавиш
 	mov	cx,k6l
 	db  0f2h,0aeh	; repne scasb, сравнение полученного кода ска-
 	 	 	; нирования с содержимым таблицы
 	mov	al,ah	 	; запомнить код сканирования
 	je	k17	 	; переход по совпадению
 	jmp	k25	 	; переход по несовпадению
k406:
 	test	kb_flag_1,lat
 	jnz	k26a
 	test	kb_flag,left_shift+right_shift
 	mov	ax,5cf1h
 	jz	k407
 	mov	ax,5cf0h

;   Получение маски нажатой управляющей клавиши

k407:
 	jmp	k57

k17:	sub	di,offset k6+1
 	cmp	di,8
 	jb	k300
 	mov	ah,6
 	cmp	di,0ah
 	jb	k301
 	test	al,80h
 	jz	k26a
 	and	kb_flag_1,not lat+lat_shift
 	cmp	di,0bh
 	je	k401
 	test	kb_flag_1,inv_shift
 	jz	k400
 	or	kb_flag_1,lat_shift
 	jmp	k26a
k400:	or	kb_flag_1,lat+lat_shift
 	jmp	k26a
k401:	test	kb_flag_1,inv_shift
 	jz	k26a
 	or	kb_flag_1,lat
 	jmp	k26a
k300:	mov	ah,cs:k7[di]
k301:
 	test	al,80h	 	; клавиша отжата ?
 	jnz	k23	; переход, если клавиша отжата

;   Управляющая клавиша нажата

 	cmp	ah,scroll_shift ; нажата управляющая клавиша с
 	 	 	 	;  запоминанием ?
 	jae	k18	 	; переход, если да

;---
 	cmp	ah,6
 	je	k302

 	or	kb_flag,ah	; установка масок управляющих клавиш
 	 	 	 	; без запоминания
 	jmp	k26	 	; к выходу из прерывания
k302:	or	kb_flag_1,inv_shift+lat
 	test	kb_flag_1,lat_shift
 	jz	k26a
 	and	kb_flag_1,not lat
k26a:
 	jmp	k26

;   Опрос нажатия клавиши с запоминанием

k18:
 	test	kb_flag,ctl_shift	  ; опрос клавиши УПР
 	jnz	k25
 	cmp	al,ins_key	 	  ; опрос клавиши ВСТ
 	jnz	k22
 	test	kb_flag,alt_shift	  ; опрос клавиши ДОП
 	jz	k19
 	jmp	k25
k19:	test	kb_flag,num_state  ; опрос клавиши ЦИФ
 	jnz	k21
 	test	kb_flag,left_shift+right_shift ; опрос клавиш левого
 	 	 	     ; и правого переключения регистров
 	jz	k22

k20:
 	mov	ax,5230h
 	jmp	k57	      ; установка кода нуля
k21:
 	test	kb_flag,left_shift+right_shift
 	jz	k20

k22:
 	test	ah,kb_flag_1
 	jnz	k26
 	or	kb_flag_1,ah
 	xor	kb_flag,ah
 	cmp	al,ins_key
 	jne	k26
 	mov	ax,ins_key*256
 	jmp	k57

k303:
 	and	kb_flag_1,not inv_shift
 	xor	kb_flag_1,lat
 	jmp	short k304

;   Управляющая клавиша отжата

k23:

 	cmp	ah,scroll_shift
 	jae	k24
 	not	ah
 	cmp	ah,0f9h
 	je	k303
 	and	kb_flag,ah
k304:
 	cmp	al,alt_key+80h
 	jne	k26

;---

 	mov	al,alt_input
 	mov	ah,0
 	mov	alt_input,ah
 	cmp	al,0
 	je	k26
 	jmp	k58

k24:
 	not	ah
 	and	kb_flag_1,ah
 	jmp	 k26
;---

k25:
 	cmp	al,80h
 	jae	k26
 	cmp	al,inf_key
 	je	k307
 	cmp	al,92
 	jne	k406b
 	jmp	k406
k406b:
 	test	kb_flag_1,hold_state
 	jz	k28
 	cmp	al,num_key
 	je	k26
 	and	kb_flag_1,not hold_state

k26:
 	cli
 	mov	al,eoi
 	out	020h,al
k27:
 	pop	es
 	pop	ds
 	pop	di
 	pop	si
 	pop	dx
 	pop	cx
 	pop	bx
 	pop	ax
 	iret

k307:	mov	ax,0a000h
 	jmp	k57


;---

k28:
 	test	kb_flag,alt_shift
 	jnz	k29
 	jmp	k38

;---

k29:
 	test	kb_flag,ctl_shift
 	jz	k31
 	cmp	al,del_key
 	jne	k31

;---
k306:
 	mov	reset_flag,1234h
 	db	0eah,5bh,0e0h,00h,0f0h
;---




k31:
 	cmp	al,57
 	jne	k32
 	mov	al,' '
 	jmp	k57

;---

k32:
 	mov	di,offset k30
 	mov	cx,10
 	db	0f2h,0aeh
 	jne	k33
 	sub	di,offset k30+1
 	mov	al,alt_input
 	mov	ah,10
 	mul	ah
 	add	ax,di
 	mov	alt_input,al
 	jmp	 k26

;---

k33:
 	mov	alt_input,00h
 	mov	cx,0026
 	db  0f2h,0aeh
 	jne	k34
 	mov	al,0
 	jmp	k57

;---

k34:
 	cmp	al,2
 	jb	k35
 	cmp	al,14
 	jae	k35
 	add	ah,118
 	mov	al,0
 	jmp	k57

;---

k35:
 	cmp	al,59
 	jae	k37
k36:
 	jmp	k26
k37:
 	cmp	al,71
 	jae	k36
 	mov	bx,offset k13
 	jmp	k63

;---

k38:
 	test	kb_flag,ctl_shift
 	jz	k44

;---
;---

 	cmp	al,scroll_key
 	jne	k39
 	mov	bx,offset kb_buffer
 	mov	buffer_head,bx
 	mov	buffer_tail,bx
 	mov	bios_break,80h
 	int	1bh
 	mov	ax,0
 	jmp	k57

k39:
 	cmp	al,num_key
 	jne	k41
 	or	kb_flag_1,hold_state
 	mov	al,eoi
 	out	020h,al

;---

 	cmp	crt_mode,7
 	je	k40
 	mov	dx,03d8h
 	mov	al,crt_mode_set
 	out	dx,al
k40:
 	test	kb_flag_1,hold_state
 	jnz	k40
 	jmp	k27
k41:

;---

 	cmp	al,55
 	jne	k42
 	mov	ax,114*256
 	jmp	k57

;---

k42:
 	mov	bx,offset k8
 	cmp	al,59
 	jae	k43
 	jmp	k56
k43:
 	mov	bx,offset k9
 	jmp	k63

;---

k44:

 	cmp	al,71
 	jae	k48
 	test	kb_flag,left_shift+right_shift
 	jz	k54a

;---

 	cmp	al,15
 	jne	k45
 	mov	ax,15*256
 	jmp	k57

k54a:
 	jmp k54

k45:
 	cmp	al,55
 	jne	k46

;---

 	mov	al,eoi
 	out	020h,al
 	int	5h
 	jmp	k27

k46:
 	cmp	al,59
 	jb	k47
 	mov	bx,offset k12
 	jmp	k63

k47:
 	test	kb_flag_1,lat
 	jz	k98
 	mov	bx,offset k11
 	jmp	 k56
k98:	mov	bx,offset rust2
 	jmp	k56

;---

k48:
 	test	kb_flag,num_state
 	jnz	k52
 	test	kb_flag,left_shift+right_shift
 	jnz	k53

;---

k49:

 	cmp	al,74
 	je	k50
 	cmp	al,78
 	je	k51
 	sub	al,71
 	mov	bx,offset k15
 	jmp	  k64

k50:	mov	ax,74*256+'-'
 	jmp	 k57

k51:	mov	ax,78*256+'+'
 	jmp	 k57

;---

k52:
 	test	kb_flag,left_shift+right_shift
 	jnz	k49

k53:
 	sub	al,70
 	mov	bx,offset k14
 	jmp	 k56
kb_int	endp

;--- int 40H---------
;   Программа обслуживания накопителя на гибком магнитном
; диске выполняет шесть функций, код которых задается
; в регистре AH:
;   AH=0 - сбросить  НГМД;
;   AH=1 - считать байт состояния НГМД. Состояние соответствует
; последней выполняемой операции и передается в регистр AL из
; постоянно распределенной области оперативной памяти с адресом
; 00441H;
;    AH=2H - считать указанный сектор в память;
;    AH=3H - записать указанный сектор из памяти;
;    AH=4H - верификация;
;    AH=5H - форматизация.
;    Для выполнения функций записи, считывания, верификации,
; форматизации в регистрах задается следующая информация:
;    DL - номер устройства (0-3, контролируемое значение);
;    DH - номер головки (0-1, неконтролируемое значение);
;    CH - номер дорожки (0-39, неконтролируемое значение);
;    CL - номер сектора (1-8, неконтролируемое значение);
;    AL - количество секторов (1-8, неконтролируемое значение).
;
;    Для выполнения форматизации необходимо сформировать в
; памяти четырехбайтную таблицу для каждого сектора, содержащую
; следующую информацию:
;    номер дорожки;
;    номер головки;
;    номер сектора;
;    количество байт в секторе (00 - 128 байт, 01 - 256 байт,
; 02 - 512 байт, 03 - 1024 байта).
;    Адрес таблицы задается в регистрах ES:BX.
;
;    После выполнения программы в регистре AH находится
; байт состояния НГМД.
;
;    Байт состояния НГМД имеет следующее значение:
;    80 - тайм-аут;
;    40 - сбой позиционирования;
;    20 - сбой контроллера;
;    10 - ошибка кода циклического контроля при считывании;
;    09 - переход адреса через сегмент (64К байт);
;    08 - переполнение;
;    04 - сектор не найден;
;    03 - защита записи;
;    02 - не обнаружен маркер идентификатора сектора;
;    01 - команда отвергнута.
;    При успешном завершении программы признак CF=0,  в про-
; тивном случае - признак CF=1 (регистр AH содержит код ошибки).
;    Регистр AL содержит количество реально считанных секторов.
;    Адрес программы обслуживания накопителя на гибком магнитном
; диске записывается в вектор 40H в процедуре сброса по включению
; питания.
;-------------------------
 	assume	cs:code,ds:data,es:data
 	org	0ec59h
diskette_io proc	far
 	sti	 	 	; установить признак прерывания
 	push	bx	 	; сохранить адрес
 	push	cx
 	push	ds	   ; сохранить сегментное значение регистра
 	push	si	   ; сохранить все регистры во время операции
 	push	di
 	push	bp
 	push	dx
 	mov	bp,sp	   ; установить указатель вершины стека
 	mov	si,dat
 	mov	ds,si	 	; установить область данных
 	call	j1	 	;
 	mov	bx,4	 	; получить параметры ожидания мотора
 	call	get_parm
 	mov	motor_count,ah	; уст время отсчета для мотора
 	mov	ah,diskette_status  ; получить состояние операции
 	cmp	ah,1	 	; уст признак CF для индикации
 	cmc	 	 	; успешной операции
 	pop	dx	 	; восстановить все регистры
 	pop	bp
 	pop	di
 	pop	si
 	pop	ds
 	pop	cx
 	pop	bx
 	ret	2
diskette_io	endp
j1	proc	near
 	mov	dh,al	 	; сохранить количество секторов
 	and	motor_status,07fh   ; указать операцию считывания
 	or	ah,ah	 	; AH=0
 	jz	disk_reset
 	dec	ah	 	; AH=1
 	jz	disk_status
 	mov	diskette_status,0   ; сброс состояния
 	cmp	dl,4	 	; проверка количества устройств
 	jae	j3	 	; переход по ошибке
 	dec	ah	 	; AH=2
 	jz	disk_read
 	dec	ah	 	; AH=3
 	jnz	j2
 	jmp	disk_write
j2:
 	dec	ah	 	; AH=4
 	jz	disk_verf
 	dec	ah	 	; AH=5
 	jz	disk_format
j3:
 	mov	diskette_status,bad_cmd   ; неверная команда

 	ret	 	 	; операция не определена
j1	endp

;   Сбросить НГМД

disk_reset proc near
 	mov	dx,03f2h
 	cli	 	 	; сброс признака разрешения прерывания
 	mov	al,motor_status  ; какой мотор включен
 	mov	cl,4	 	; счетчик сдвига
 	sal	al,cl
 	test	al,20h	 	; выбрать соответствующее устройство
 	jnz	j5	 	; переход, если включен мотор первого
 	 	 	 	; устройства
 	test	al,40h
 	jnz	j4	 	; переход, если включен мотор второго
 	 	 	 	; устройства
 	test	al,80h
 	jz	j6	 	; переход, если включен мотор нулевого
 	 	 	 	; устройства
 	inc	al
j4:	inc	al
j5:	inc	al
j6:	or	al,8	 	; включить доступность прерывания
 	out	dx,al	 	; сброс адаптера
 	mov	seek_status,0
 	mov	diskette_status,0  ; уст нормальное состояние НГМД
 	or	al,4	 	; выключить сброс
 	out	dx,al
 	sti	 	 	; установить бит разрешения прерывания
 	call	chk_stat_2	; выполнить прерывание после сброса
 	mov	al,nec_status
 	cmp	al,0c0h    ; проверка готовности устройства для передачи
 	jz	j7	 	; устройство готово
 	or	diskette_status,bad_nec  ; уст код ошибки
 	jmp	short j8

;   Послать команду в контроллер

j7:
 	mov	ah,03h	 	; установить команду
 	call	nec_output	; передать команду
 	mov	bx,1	 	; передача первого байта параметров
 	call	get_parm	; в контроллер
 	mov	bx,3	 	; передача второго байта параметров
 	call	get_parm	; в контроллер
j8:
 	ret	 	 	; возврат к прерванной программе
disk_reset	endp

;
; Считать байт состояния НГМД (AH=1)
;

disk_status proc near
 	mov	al,diskette_status
 	ret
disk_status	endp

;   Считать указанный сектор в память (AH=2)

disk_read proc near
 	mov	al,046h 	; установить команду
j9:
 	call	dma_setup	; установить ПДП
 	mov	ah,0e6h     ; уст команду считывания  контроллера
 	jmp	short rw_opn	; переход к выполнению операции
disk_read	endp

;   Верификация (AH=4)

disk_verf proc near
 	mov	al,042h 	; установить команду
 	jmp	short j9
disk_verf	endp

;   Форматизация (AH=5)

disk_format proc near
 	or	motor_status,80h  ; индикация операции записи
 	mov	al,04ah 	  ; установить команду
 	call	dma_setup	  ; установить ПДП
 	mov	ah,04dh 	  ; установить команду
 	jmp	short rw_opn
j10:
 	mov	bx,7	 	  ; получить значение сектора
 	call	get_parm
 	mov	bx,9	 	; получить значение дорожки на секторе
 	call	get_parm
 	mov	bx,15	 	; получить значение длины интервала
 	call	get_parm	; для контроллера
 	mov	bx,17	 	; получить полный байт
 	jmp	j16
disk_format	endp

;   Записать указанный сектор из памяти (AH=3)

disk_write proc near
 	or	motor_status,80h	; индикация операции записи
 	mov	al,04ah 	 	; уст код операции записи
 	call	dma_setup
 	mov	ah,0c5h 	 	; команда записи на НГМД
disk_write	endp

;______________________
; rw_opn
;   Программа выполнения операций
;   считывания, записи, верификации
;----------------------
rw_opn	proc	near
 	jnc	j11	 	; проверка ошибки ПДП
 	mov	diskette_status,dma_boundary   ; установить ошибку
 	mov	al,0	 	;
 	ret	 	 	; возврат к основной программе
j11:
 	push	ax	 	; сохранить команду

;   Включить мотор и выбрать устройство

 	push	cx
 	mov	cl,dl	 	; уст номер устройства, как счетчик сдвига
 	mov	al,1	 	; маска для определения мотора устройства
 	sal	al,cl	 	; сдвиг
 	cli	 	 	; сбросить бит разрешения прерывания
 	mov	motor_count,0ffh  ; установить счетчик
 	test	al,motor_status
 	jnz	j14
 	and	motor_status,0f0h  ; выключить все биты мотора
 	or	motor_status,al    ; включить мотор
 	sti	 	 	; установить бит разрешения прерывания
 	mov	al,10h	 	; бит маски
 	sal	al,cl	 	; уст бит маски для доступности мотора
 	or	al,dl	 	; включить бит выбора устройства
 	or	al,0ch	 	; нет сброса, доступность прерывания ПДП
 	push	dx
 	mov	dx,03f2h	; установить адрес порта
 	out	dx,al
 	pop	dx	 	; восстановить регистры
 	push	cx	 	;задержка для включения мотора устройства
 	mov	cx,3
x2:	push	cx
 	mov	cx,0
x1:	loop	x1
 	pop	cx
 	loop	x2
 	pop	cx

;   Ожидание включения мотора для операции записи

 	test	motor_status,80h  ; запись ?
 	jz	j14	; нет - продолжать без ожидания
 	mov	bx,20	 	; установить ожидание включения мотора
 	call	get_parm	; получить параметры
 	or	ah,ah
j12:
 	jz	j14	 	; выход по окончании времени ожидания
 	sub	cx,cx	 	; установить счетчик
j13:	loop	j13	 	; ожидать требуемое время
 	dec	ah	 	; уменьшеть значение времени
 	jmp	short j12	; повторить цикл

j14:
 	sti	 	 	; уст признак разрешения прерывания
 	pop	cx

;   Выполнить операцию поиска

 	call	seek	 	; установить дорожку
 	pop	ax	 	; восстановить команду
 	mov	bh,ah	 	; сохранить команду в BH
 	mov	dh,0	 	; уст 0 сектор в случае ошибки
 	jc	j17	 	; выход, если ошибка
 	mov	si,offset j17

 	push	si

;   Послать параметры в контроллер

 	call	nec_output	; передача команды
 	mov	ah,byte ptr [bp+1]  ; уст номер головки
 	sal	ah,1	 	; сдвиг на 2
 	sal	ah,1
 	and	ah,4	 	; выделить бит
 	or	ah,dl	 	; операция OR с номером устройства
 	call	nec_output

;   Проверка операции форматизации

 	cmp	bh,04dh 	; форматизация ?
 	jne	j15    ; нет - продолжать запись/считывание/верификацию
 	jmp	j10

j15:	mov	ah,ch	 	; номер цилиндра
 	call	nec_output
 	mov	ah,byte ptr [bp+1]  ; номер головки
 	call	nec_output
 	mov	ah,cl	 	; номер сектора
 	call	nec_output
 	mov	bx,7
 	call	get_parm
 	mov	bx,9
 	call	get_parm
 	mov	bx,11
 	call	get_parm
 	mov	bx,13
j16:
 	call	get_parm
 	pop	si

;   Операция запущена

 	call	wait_int	; ожидание прерывания
j17:
 	jc	j21	 	; поиск ошибки
 	call	results 	; получить состояние контроллера
 	jc	j20	 	; поиск ошибки

;   Проверка  состояния, полученного из контроллера

 	cld	 	 	; установить направление коррекции
 	mov	si,offset nec_status
 	lods	nec_status
 	and	al,0c0h 	; проверить нормальное окончание
 	jz	j22
 	cmp	al,040h 	; проверить неверное окончание
 	jnz	j18

;   Обнаруженно неверное окончание

 	lods	nec_status
 	sal	al,1
 	mov	ah,record_not_fnd
 	jc	j19
 	sal	al,1
 	sal	al,1
 	mov	ah,bad_crc
 	jc	j19
 	sal	al,1
 	mov	ah,bad_dma
 	jc	j19
 	sal	al,1
 	sal	al,1
 	mov	ah,record_not_fnd
 	jc	j19
 	sal	al,1
 	mov	ah,write_protect  ; проверка защиты записи
 	jc	j19
 	sal	al,1
 	mov	ah,bad_addr_mark
 	jc	j19

;   Контроллер вышел из строя

j18:
 	mov	ah,bad_nec
j19:
 	or	diskette_status,ah
 	call	num_trans
j20:
 	ret	 	; возврат к программе, вызвавшей прерывание

j21:
 	call	results 	; вызов результатов в буфер
 	ret

;   Операция была успешной

j22:
 	call	num_trans
 	xor	ah,ah	 	; нет ошибок
 	ret
rw_opn	endp
;------------------------
;get_parm
;
;   ВХОД   BX - индекс байта,деленный
;	 	на 2,который будет
;	 	выбран,если младший
;	 	бит BX установлен,то
;	 	байт немедленно пере-
;	 	дается контроллеру.
;
;   ВЫХОД  AH - байт из блока.
;-------------------------
get_parm proc	near
 	push	ds	 	; сохранить сегмент
 	sub	ax,ax	 	; AX=0
 	mov	ds,ax
 	assume	ds:abs0
 	lds	si,disk_pointer
 	shr	bx,1	 	; делить BX на 2, уст флаг для выхода
 	mov	ah,zb[si+bx]	; получить слово
 	pop	ds	 	; восстановить сегмент
 	assume	ds:data
 	jc	nec_op	 	 ;если флаг установлен, выход
 	ret	 	; возврат к программе, вызвавшей прерывание
nec_op: jmp	nec_output
get_parm endp
;----------------------------
;   Позиционирование
;
;   Эта программа позиционирует голов-
; ку обозначенного устройства на нуж-
; ную дорожку. Если устройство не
; было выбрано до тех пор, пока не
; была сброшена команда,то устройство
; будет рекалибровано.
;
;   ВВОД
;	(DL) - номер усройства для
;	       позиционирования,
;	(CH) - номер дорожки.
;
;   ВЫВОД
;	 CY=0 - успешно,
;	 CY=1 - сбой (состояние НГМД установить
;	 	согласно  AX).
;----------------------------
seek	proc	near
 	mov	al,1	 	; уст маску
 	push	cx
 	mov	cl,dl	 	; установить номер устройства
 	rol	al,cl	 	; циклический сдвиг влево
 	pop	cx
 	test	al,seek_status
 	jnz	j28
 	or	seek_status,al
 	mov	ah,07h
 	call	nec_output
 	mov	ah,dl
 	call	nec_output
 	call	chk_stat_2   ; получить и обработать прерывание
 	mov	ah,07h	 	; команда рекалибровки
 	call	nec_output
 	mov	ah,dl
 	call	nec_output
 	call	chk_stat_2
 	jc	j32	 	; сбой позиционирования


j28:
 	mov	ah,0fh
 	call	nec_output
 	mov	ah,dl	 	; номер устройства
 	call	nec_output
 	mov	ah,ch	 	; номер дорожки
 	test	byte ptr equip_flag,4
 	jnz	j300
 	add	ah,ah	 	; удвоение номера дорожки
j300:
 	call	nec_output
 	call	chk_stat_2	; получить конечное прерывание и
 	 	 	 	; считать состояние


 	pushf	 	 	; сохранить значение флажков
 	mov	bx,18
 	call	get_parm
 	push	cx	 	; сохранить регистр
j29:
 	mov	cx,550	 	; организовать цикл = 1 ms
 	or	ah,ah	 	; проверка окончания времени
 	jz	j31
j30:	loop	j30	 	; задержка 1ms
 	dec	ah	 	; вычитание из счетчика
 	jmp	short j29	; возврат к началу цикла
j31:
 	pop	cx	 	; восстановить состояние
 	popf
j32:	 	 	 	; ошибка позиционирования
 	ret	 	; возврат к программе, вызвавшей прерывание
seek	endp
;-----------------------
; dma_setup
;   Программа установки ПДП для операций записи,считывания,верифи-
; кации.
;
;   ВВОД
;
;	(AL) - байт режима для ПДП,
;	(ES:BX) - адрес считывания/записи информации.
;
;------------------------
dma_setup proc	near
 	push	cx	 	; сохранить регистр
 	out	dma+12,al
 	out	dma+11,al	; вывод байта состояния
 	mov	ax,es	 	; получить значение ES
 	mov	cl,4	 	; счетчик для сдвига
 	rol ax,cl	 	; циклический сдвиг влево
 	mov	ch,al	 	;
 	and	al,0f0h 	;
 	add	ax,bx
 	jnc	j33
 	inc	ch	 	; перенос означает, что старшие 4 бита
 	 	 	 	; должны быть прибавлены
j33:
 	push	ax	 	; сохранить начальный адрес
 	out	dma+4,al	; вывод младшей половины адреса
 	mov	al,ah
 	out	dma+4,al	; вывод старшей половины адреса
 	mov	al,ch	 	; получить 4 старших бита
 	and	al,0fh
 	out	081h,al   ; вывод 4 старших бит на регистр страниц

;   Определение счетчика

 	mov	ah,dh	 	; номер сектора
 	sub	al,al	 	;
 	shr	ax,1	 	;
 	push	ax
 	mov	bx,6	 	; получить параметры байт/сектор
 	call	get_parm
 	mov	cl,ah	 	; счетчик сдига (0=128, 1=256 и т.д)
 	pop	ax
 	shl	ax,cl	 	; сдвиг
 	dec	ax	 	; -1
 	push	ax	 	; сохранить значение счетчика
 	out	dma+5,al	; вывести младший байт счетчика
 	mov	al,ah
 	out	dma+5,al	; вывести старший байт счетчика
 	pop	cx	 	; восстановить значение счетчика
 	pop	ax	 	; восстановить значение адреса
 	add	ax,cx	 	; проверка заполнения 64K
 	pop	cx	 	; восстановить регистр
 	mov	al,2	 	; режим для 8237
 	out	dma+10,al	; инициализация канала НГМД
 	ret	 	; возврат к программе, вызвавшей прерывание
dma_setup	endp
;-----------------------
;chk_stat_2
;   Эта программа обрабатывает прерывания ,полученные после
; рекалибровки, позиционирования или сброса адаптера. Прерывание
; ожидается, принимается, обрабатывается и результат выдается программе,
; вызвавшей прерывание.
;
;   ВЫВОД
;	  CY=0 - успешно,
;	  CY=1 - сбой (ошибка в состоянии НГМД),
;--------------------------
chk_stat_2 proc near
 	call	wait_int	; ожидание прерывания
 	jc	j34	 	; если ошибка, то возврат
 	mov	ah,08h	 	; команда получения состояния
 	call	nec_output
 	call	results 	; считать результаты
 	jc	j34
 	mov	al,nec_status	; получить первый байт состояния
 	and	al,060h 	; выделить биты
 	cmp	al,060h 	; проверка
 	jz	j35	   ; если ошибка, то идти на метку
 	clc	 	 	; возврат
j34:
 	ret	 	; возврат к программе, вызвавшей прерывание
j35:
 	or	diskette_status,bad_seek
 	stc	 	 	; ошибка в возвращенном коде
 	ret
chk_stat_2	endp
;---------------------------------
; wait_int
;   Эта программа ожидает прерывание, которое возникает во время
; программы вывода. Если устройство не готово, ошибка может быть
; возвращена.
;
;
;   ВЫВОД
;	      CY=0 - успешно,
;	      CY=1 - сбой(состояние НГМД устанавливается),
;-----------------------------------
wait_int proc	near
 	sti	 	 	; установить признак разрешения прерывания
 	push	bx
 	push	cx	 	; сохранить регистр
 	mov	bl,2	 	; количество циклов
 	xor	cx,cx	 	; длителность одного цикла ожидания
j36:
 	test	seek_status,int_flag  ; опрос наличия прерывания
 	jnz	j37
 	loop	j36	 	; возврат к началу цикла
 	dec	bl
 	jnz	j36
 	or	diskette_status,time_out
 	stc	 	 	; возврат при ошибке
j37:
 	pushf	 	 	; сохранить текущие признаки
 	and	seek_status,not int_flag
 	popf	 	 	; восстановить признаки
 	pop	cx
 	pop	bx	 	; восстановить регистр
 	ret	 	; возврат к программе, вызвавшей прерывание
wait_int	endp
;---------------------------
;disk_int
;   Эта программа обрабатывает прерывания НГМД
;
;   ВЫВОД  - признак прерывания устанавливается в SEEK_STATUS.
;---------------------------
 	org	0ef57h
disk_int proc	far
 	sti	 	 	; установить признак разрешения прерывания
 	push	ds
 	push	ax
 	mov	ax,dat
 	mov	ds,ax
 	or	seek_status,int_flag
 	mov	al,20h	 	; установить конец прерывания
 	out	20h,al	 	; послать конец прерывания в порт
 	pop	ax
 	pop	ds
 	iret	 	 	; возврат из прерывания
disk_int	endp
;----------------------------
;
;   Эта программа считывет все, что контроллер адаптера НГМД указывает
; программе, следующей за прерыванием.
;
;
;   ВЫВОД
;	   CF=0 - успешно,
;	   CF=1 - сбой
;----------------------------
results proc	near
 	cld
 	mov	di,offset nec_status
 	push	cx	 	; сохранить счетчик
 	push	dx
 	push	bx
 	mov	bl,7	 	; установить длину области состояния


j38:
 	xor	cx,cx	 	; длительность одного цикла
 	mov	dx,03f4h	; адрес порта
j39:
 	in	al,dx	 	; получить состояние
 	test	al,080h 	; готово ?
 	jnz	j40a
 	loop	j39
 	or	diskette_status,time_out
j40:	 	 	 	; ошибка
 	stc	 	 	; возврат по ошибке
 	pop	bx
 	pop	dx
 	pop	cx
 	ret

;   Проверка признака направления

j40a:	in	al,dx	 	; получить регистр состояния
 	test	al,040h 	; сбой позиционирования
 	jnz	j42	; если все нормально, считать состояние
j41:
 	or	diskette_status,bad_nec
 	jmp	short j40	; ошибка

;   Считывание состояния

j42:
 	inc	dx	 	; указать порт
 	in	al,dx	 	; ввести данные
 	mov    byte ptr [di],al  ; сохранить байт
 	inc	di	 	; увеличить адрес
 	mov	cx,000ah	; счетчик
j43:	loop	j43
 	dec	dx
 	in	al,dx	 	; получить состояние
 	test	al,010h
 	jz	j44
 	dec	bl	 	; -1 из количества циклов
 	jnz	j38
 	jmp	short j41	; сигнал неверен

j44:
 	pop	bx	 	; восстановить регистры
 	pop	dx
 	pop	cx
 	ret	 	 	; возврат из прерывания
results endp
;-----------------------------
; num_trans
;   Эта программа вычисляет количество секторов, которое действительно
; было записано или считано с НГМД
;
;   ВВОД
;	 (CH) - цилиндр,
;	 (CL) - сектор.
;
;   ВЫВОД
;	 (AL) - количество действительно переданных секторов.
;
;------------------------------
num_trans proc	near
 	mov	al,nec_status+3  ; получить последний цилиндр
 	cmp	al,ch	 	; сравнить со стартовым
 	mov	al,nec_status+5  ; получить последний сектор
 	jz	j45
 	mov	bx,8
 	call	get_parm	; получить значение EOT
 	mov	al,ah	 	; AH в AL
 	inc	al	 	; EOT+1
j45:	sub	al,cl	    ; вычисление стартового номера из конечного
 	ret
num_trans endp

;-------------------------------
; disk_base
;   Эта программа устанавливает параметры,требуемые для операций
; НГМД.
;--------------------------------

disk_base label byte
 	db	11001111b	;
 	db	2	 	;
 	db	motor_wait	;
 	db	2	 	;
 	db	8	 	;
 	db	02ah	 	;
 	db	0ffh	 	;
 	db	050h	 	;
 	db	0f6h	 	;
 	db	25	 	;
 	db	4	 	;
;--- int 17-------------------
;   Программа связи с печатающим устройством
;
;   Эта программа выполняет три функции, код которых задается
; в регистре AH:
;   AH=0 - печать знака, заданного в регистре AL. Если в
; результате выполнения функции знак не напечатается, то в регистре
; AL устанавливается "1" (тайм-аут);
;   AH=1 - инициализация порта печати. После выполнения функции
; в регистре AH находится байт состояния печатающего устройства;
;   AH=2H - считывание байта состояния печатающего устройства.
;   В регистре DX необходимо задать ноль.
;   Значение разрядов байта состояния печатающего устройства:
;   0 - тайм-аут;
;   3 - ошибка ввода-вывода;
;   4 - выбран (SLCT);
;   5 - конец бумаги (PE);
;   6 - подтверждение;
;   7 - занято.
;------------------------------

 	assume	cs:code,ds:data
printer_io proc far
 	sti	 	 	; установить признак разрешения прерывания
 	push	ds	 	; сохранить сегмент
 	push	dx
 	push	si
 	push	cx
 	push	bx
 	mov	si,dat
 	mov	ds,si	 	; установить сегмент
 	mov	si,dx
 	shl	si,1
 	mov	dx,printer_base[si]  ; получить базовый адрес
 	 	 	 	     ; печатающего устройства
 	or	dx,dx	 	   ; печать подключена ?
 	jz	b1	 	   ; нет, возврат
 	or	ah,ah	 	   ; AH=0 ?
 	jz	b2	 	   ; да, переход к печати знака
 	dec	ah	 	   ; AH=1 ?
 	jz	b8	 	   ; да, переход к инициализации
 	dec	ah	 	   ; AH=2 ?
 	jz	b5	   ; да, переход к считыванию байта состояния

;    Выход из программы

b1:
 	pop	bx	 	; восстановить регистры
 	pop	cx
 	pop	si
 	pop	dx
 	pop	ds
 	iret

;   Печать знака, заданного в AL

b2:
 	push	ax
 	mov	bl,10	 	; количество циклов ожидания
 	xor	cx,cx	 	; длительность одного цикла
 	out	dx,al	 	; вывести символ в порт
 	inc	dx	 	; -1 из адреса порта
b3:	 	 	 	; ожидание BUSY
 	in	al,dx	 	; получить состояние
 	mov	ah,al	 	; переслать состояние в AH
 	test	al,80h	 	; печать занята ?
 	jnz	b4	 	; переход, если да
 	loop	b3	 	; цикл ожидания закончился ?
 	dec	bl	 	; да, -1 из количества циклов
 	jnz	b3	 	; время ожидания истекло ?
 	or	ah,1	 	; да, уст бит "тайм-аут"
 	and	ah,0f9h 	;
 	jmp	short b7
b4:	 	 	 	; OUT_STROBE
 	mov	al,0dh	 	; установить высокий строб
 	inc	dx	; стробирование битом 0 порта C для 8255
 	out	dx,al
 	mov	al,0ch	 	; установить низкий строб
 	out	dx,al
 	pop	ax	 	;

;   Считывание байта состояния печатающего устройства

b5:
 	push	ax	 	; сохранить регистр
b6:
 	mov	dx,printer_base[si]  ; получить адрес печати
 	inc	dx
 	in	al,dx	 	; получить состояние печати
 	mov	ah,al
 	and	ah,0f8h
b7:
 	pop	dx
 	mov	al,dl
 	xor	ah,48h
 	jmp	short b1	; к выходу из программы

;   Инициализация порта печатающего устройства

b8:
 	push	ax
 	add	dx,2	 	; указать порт
 	mov	al,8
 	out	dx,al
 	mov	ax,1000 	 ; время задержки
b9:
 	dec	ax	 	 ; цикл задержки
 	jnz	b9
 	mov	al,0ch
 	out	dx,al
 	jmp	short b6    ; переход к считыванию байта состояния
printer_io	endp
;--- int 10------------------
;
;   Программа обработки прерывания ЭЛИ
;
;   Эта программа обеспечивает выполнение функций обслуживания
; адаптера ЭЛИ, код которых задается в регистре AH:
;
;    AH=0   - установить режим работы адаптера ЭЛИ. В результате
; выполнения функции в регистре AL могут устанавливаться следу-
; ющие режимы:
;    0 - 40х25, черно-белый, алфавитно-цифровой;
;    1 - 40х25, цветной, алфавитно-цифровой;
;    2 - 80х25, черно-белый, алфавитно-цифровой;
;    3 - 80х25, цветной, алфавитно-цифровой;
;    4 - 320х200, цветной, графический;
;    5 - 320х200, черно-белый, графический;
;    6 - 640х200, черно-белый, графический;
;    7 - 80х25, черно-белый, алфавитно-цифровой.
;    Режимы 0 - 6 используются для ЭМ адаптера ЭЛИ, режим 7
; используется для монохромного черно-белого 80х25 адаптера.
;
;    AH=1   - установить размер курсора. Функция задает размер кур-
; сора и управление им.
;   Разряды 0 - 4 регистра CL определяют конечную границу курсора,
; разряды 0 - 4 регистра CH - начальную границу курсора.
;    Разряды 6 и 5 задают управление курсором:
;    00 - курсор мерцает с частотой, задаваемой аппаратурно;
;    01 - курсор отсутствует.
;    Аппаратурно всегда вызывается мерцание курсора с частотой,
; равной 1/16 частоты кадровой развертки.
;
;    AH=2   - установить текущую позицию курсора. Для выполнения
; функции необходимо задать следующие координаты курсора:
;    BH - страница;
;    DX - строка и колонка.
; При графическом режиме регистр BH=0.
;
;    AH=3   - считать текущее положение курсора. Функция вос-
; станавливает текущее положение курсора. Перед выполнением
; функции в регистре BH необходимо задать страницу.
;    После выполнения программы регистры содержат следующую
; информацию:
;    DH - строка;
;    DL - колонка;
;    CX - размер курсора и управление им.
;
;    AH=5  - установить активную страницу буфера адаптера.
; Функция используется только в алфавитно-цифровом режиме.
; Для ее выполнения необходимо в регистре AL задать страницу:
;    0-7 - для режимов 0 и 1;
;    0-3 - для режимов 2 и 3.
;    Значения режимов те же, что и для функции AH=0.
;
;    AH=6   - переместить блок символов вверх по экрану.
; Функция перемещает символы в пределах заданной области вверх
; по экрану, заполняя нижние строки пробелами с заданным атрибу-
; том.
;    Для выполнения функции необходимо задать следующие пара-
; метры;
;    AL - количество перемещаемых строк. Для очистки блока AL=0;
;    CX - координаты левого верхнего угла блока (строка,колонка);
;    DX - координаты правого нижнего угла блока;
;    BH - атрибут символа пробела.
;
;    AH=7   - переместить блок символов вниз. Функция перемещает
; символы в пределах заданной области вниз по экрану, заполняя
; верхние строки пробелами с заданным атрибутом.
;    Для выполнения функции необходимо задать те же параметры,
; что и для функции AH=6H.
;
;    AH=8   - считать атрибут и код символа, находящегося в теку-
; щей позиции курсора. Функция считывает атрибут и код символа
; и помещает их в регистр AX (AL - код символа, AH - атрибут
; символа).
;    Для выполнения функции необходимо в регистре BH задать
; страницу (только для алфавитно-цифрового режима).
;
;    AH=9   - записать атрибут и код символа в текущую позицию
; курсора. Функция помещает код символа и его атрибут в текущую
; позицию курсора.
;    Для выполнения функции необходимо задать следующие параметры:
;    BH - отображаемая страница (только для алфавитно-цифрового
; режима;
;    CX - количество записываемых символов;
;    AL - код символа;
;    BL - атрибут символа для алфавитно-цифрового режима или
; цвет знака для графики. При записи точки разряд 7 регистра BL=1.    =1
;
;    AH=10 - записать символ в текущую позицию курсора. Атрибут
; не изменяется.
;    Для выполнения функции необходимо задать следующие параметры:
;    BH - отображаемая страница (только для алфавитно-цифрового
; режима);
;    CX - количество повторений символа;
;    AL - код записываемого символа.	 	 	 	      ся
;	 	 	 	 	 	 	 	      -
;    AH=11 - установить цветовую палитру.	 	 	      ь
;    При выполнении функции используются два варианта.
;    Для первого варианта в регистре BH задается ноль,а в регистре
; BL - значения пяти младших разрядов, используемых для выбора
; цветовой палитры (цвет заднего плана для цветного графического
; режима 320х200 или цвет каймы для цветного графического режима
; 40х25).
;    Для второго варианта в регистре BH задается "1", а в регистре
; BL - номер цветовой палитры (0 или 1).
;    Палитра 0 состоит из зеленого (1), красного (2) и желтого (3)
; цветов, палитра 1 - из голубого (1), фиолетового (2) и белого (3).
; При работе с видеомонитором цвета палитры заменяются соответству-
; ющими градациями цвета.
;    Результатом выполнения функции является установка цветовой       )
; палитры в регистре выбора цвета (3D9).
;
;    AH=12  - записать точку. Функция определяет относительный
; адрес байта внутри буфера ЭЛИ, по которому должна быть записана
; точка с заданными координатами.
;    Для выполнения функции необходимо задать следующие параметры:    ,
;    DX - строка;
;    CX - колонка;
;    AL - цвет выводимой точки. Если разряд 7 регистра AL уста-       3)
; новлен в "1", то выполняется операция XOR над значением точки
; из буфера и значением точки из регистра AL.
;
;    AH=13 - считать точку. Функция определяет относительный
; адрес байта внутри буфера ЭЛИ, по которому должна быть считана
; точка с заданными координатами.
;    Перед выполнением программы в регистрах задаются те же парамет-
; ры, что и для функции AH=12.
;   После выполнения программы в регистре AL находится значение
; считанной точки.
;
;    AH=14 - записать телетайп. Функция выводит символ в буфер
; ЭЛИ с одновременной установкой позиции курсора и передвижением
; курсора на экране.
;    После записи символа в последнюю позицию строки выполняется
; автоматический переход на новую строку. Если страница экрана
; заполнена, выполняется перемещение на одну строку вверх. Осво-
; бодившаяся строка заполняется значением атрибута символа для
; алфавитно-цифрового режима или нулями - для графики.
;    После записи очередного символа курсор устанавливается
; в следующую позицию.
;    Для выполнения программы необходимо задать следующие параметры:
;    AL - код выводимого символа;
;    BL - цвет переднего плана (для графического режима).
;    Программа обрабатывает следующие служебные символы:
;    0BH - сдвиг курсора на одну позицию (без очистки);
;    0DH - перемещение курсора в начало строки;
;    0AH - перемещение курсора на следующую строку;
;    07H - звуковой сигнал.
;
;    AH=15 - получить текущее состояние ЭЛИ. Функция считывает
; текущее состояние ЭЛИ из памяти и размещает его в следующих
; регистрах;
;    AH - количество колонок (40 или 80);
;    AL - текущий режим (0-7). Значения режимов те же, что и для
; функции AH=0;
;    BH - номер активной страницы.
;
;   AH=17 - загрузить знакогенератор пользователя. Функция дает
; возможность пользователю загружать знакогенератор любым, необ-
; ходимым ему алфавитом.
;    Для выполнения программы необходимо задать следующие параметры:
;    ES:BP - адрес таблицы, сформированной пользователем;
;    CX    - количество передаваемых символов;
;    BL    - код символа, начиная с которого загружается таблица
; пользователя;
;    BH - количество байт на знакоместо;
;    DL - идентификатор таблицы пользователя;
;    AL - режим:
;	 	  AL=0	 -  загрузить знакогенератор
;	 	  AL=1	 -  выдать идентификатор таблицы
;	 	  AL=3	 -  загрузить вторую половину знакогенератора:
;	 	 	    BL=0 - загрузить вторую половину знакогене
;	 	 	    ратора из ПЗУ кодовой таблицы с русским
;	 	 	    алфавитом,
;	 	 	    BL=1 - загрузить вторую половину знакогене
;	 	 	    ратора из ПЗУ стандартной кодовой таблицей
;	 	 	    ASCII (USA)
;   На выходе:
;	AH   -	количество байт на знакоместо
;	AL   -	идентификатор таблицы пользователя
;	CF=1   -   операция завершена успешно
;
;    AH=19 - переслать цепочку символов. Функция позволяет пере-
; сылать символы четырьмя способами, тип которых задается в
; регистре AL:
;    AL=0 - символ, символ, символ, ...
; В регистре BL задается атрибут, курсор не движется;
;    AL=1 - символ, символ, символ, ...
; В регистре BL задается атрибут, курсор движется;
;    AL=2H - символ, атрибут, символ, атрибут, ...
; Курсор не движется;
;    AL=3H - символ, атрибут, символ, атрибут, ...
; Курсор движется.
;     Кроме того необходимо задать в регистрах:
;    ES:BP - начальный адрес цепочки символов;
;    CX    - количество символов;
;    DH,DL - строку и колонку для начала записи;
;    BH    - номер страницы.
;-----------------------------------------------------------

 	assume cs:code,ds:data,es:video_ram

m1	label	word	 	; таблица функций адаптера ЭЛИ
 	dw	offset	set_mode
 	dw	offset	set_ctype
 	dw	offset	set_cpos
 	dw	offset	read_cursor
 	dw	offset	read_lpen1
 	dw	offset	act_disp_page
 	dw	offset	scroll_up
 	dw	offset	scroll_down
 	dw	offset	read_ac_current
 	dw	offset	write_ac_current
 	dw	offset	write_c_current
 	dw	offset	set_color
 	dw	offset	write_dot
 	dw	offset	read_dot
 	dw	offset	write_tty
 	dw	offset	video_state
 	dw	video_return
 	dw	offset ah12
 	dw	offset video_return
 	dw	ah13
m1l	equ	28h

video_io proc	near
 	sti	 	    ; установить признак разрешения прерывания
 	cld
 	push	es
 	push	ds
 	push	dx
 	push	cx
 	push	bx
 	push	si
 	push	di
 	push	bp
 	push	ax	 	; сохранить значение AX
 	mov	al,ah	 	; переслать AH в AL
 	xor	ah,ah	 	; обнулить старший байт
 	sal	ax,1	 	; умножить на 2
 	mov	si,ax	 	; поместить в SI
 	cmp	ax,m1l	 	; проверка длины таблицы функций
 	jb	m2	 	; адаптера ЭЛИ
 	pop	ax	 	; восстановить AX
 	jmp	video_return	; выход, если AX неверно
m2:	mov	ax,dat
 	mov	ds,ax
 	mov	ax,0b800h	; сегмент для цветного адаптера
 	mov	di,equip_flag	; получить тип адаптера
 	and	di,30h	 	; выделить биты режима
 	cmp	di,30h	 	; есть установка ч/б адаптера ?
 	jne	m3
 	mov	ax,0b000h	; уст адреса буфера для ч/б адаптера
m3:	mov	es,ax
 	pop	ax	 	; восстановить значение
 	cmp	ah,10h
 	jb	mm3
 	push	bp
 	mov	bp,sp
 	mov	es,[bp+10h]
 	pop	bp
mm3:
 	mov	ah,crt_mode	; получить текущий режим в AH
 	jmp   cs:[si+offset m1]
video_io	endp
;-------------------------
; set mode

;   Эта программа устанавливает режим работы адаптера ЭЛИ
;
;   ВХОД
;	   (AL) - содержит значение режима.
;
;--------------------------

;   Таблицы параметров ЭЛИ

video_parms label	byte

;   Таблица инициализации

 	db	38h,28h,2dh,0ah,1fh,6,19h   ; уст для 40х25
 	db	1ch,2,7,6,7
 	db	0,0,0,0
m4	equ	10h

 	db	71h,50h,5ah,0ah,1fh,6,19h   ; уст для 80х25
 	db	1ch,2,7,6,7
 	db	0,0,0,0

 	db	38h,28h,2dh,0ah,7fh,6,64h   ; уст для графики
 	db	70h,2,1,6,7
 	db	0,0,0,0

 	db	62h,50h,50h,0fh,19h,6,19h   ; уст для 80х25 ч/б адаптера
 	db	19h,2,0dh,0bh,0ch
 	db	0,0,0,0

m5	label	word	 	; таблица для восстановления длины
 	dw	2048
 	dw	4096
 	dw	16384
 	dw	16384

;   Колонки
m6	label	byte
 	db	40,40,80,80,40,40,80,80

;--- c_reg_tab
m7	label	byte	 	; таблица установки режима
 	db	2ch,28h,2dh,29h,2ah,2eh,1eh,29h

set_mode proc	near
 	mov	dx,03d4h	; адрес цветного адаптера
 	mov	bl,0	 ; уст значение для цветного адаптера
 	cmp	di,30h	 	; установлен ч/б адаптер ?
 	jne	m8	 	; переход, если указан цветной
 	mov	al,7	 	; указать ч/б режим
 	mov	dx,03b4h	; адрес для ч/б адаптера
 	inc	bl	 	; установить режим для ч/б адаптера
m8:	mov	ah,al	 	; сохранить режим в AH
 	mov	crt_mode,al
 	mov	addr_6845,dx	; сохранить адрес управляющего порта
 	 	 	 	; для активного дисплея
 	push	ds
 	push	ax	 	; сохранить режим
 	push	dx	 	; сохранить значение порта вывода
 	add	dx,4	 	; указать адрес регистра управления
 	mov	al,bl	 	; получить режим для адаптера
 	out	dx,al	 	; сброс экрана
 	pop	dx	 	; восстановить DX
 	sub	ax,ax
 	mov	ds,ax	 	; установить адрес таблицы векторов
 	assume	ds:abs0
 	lds	bx,parm_ptr ; получить значение параметров адаптера ЭЛИ
 	pop	ax	 	; восстановить AX
 	assume	ds:code
 	mov	cx,m4	   ; установить длину таблицы параметров
 	cmp	ah,2	 	; определение режима
 	jc	m9	 	; режим 0 или 1 ?
 	add	bx,cx	 	; уст начало таблицы параметров
 	cmp	ah,4
 	jc	m9	 	; режим 2 или 3
 	add	bx,cx	 	; начало таблицы для графики
 	cmp	ah,7
 	jc	m9	 	; режимы 4, 5 или 6 ?
 	add	bx,cx	 	; уст начало таблицы для ч/б адаптера

;   BX указывает на строку таблицы инициализации

m9:	 	 	 	; OUT_INIT
 	push	ax	 	; сохранить режим в AH
 	xor	ah,ah	 	;

;   Цикл таблицы, устанавливающий адреса регистров и выводящий значения
; из таблицы

m10:
 	mov	al,ah	 	;
 	out	dx,al
 	inc	dx	 	; указать адрес порта
 	inc	ah	 	;
 	mov	al,byte ptr [bx]   ; получить значение таблицы
 	out	dx,al	 	; послать строку из таблицы в порт
 	inc	bx	 	; +1 к адресу таблицы
 	dec	dx	 	; -1 из адреса порта
 	loop	m10	 	; передана вся таблица ?
 	pop	ax	 	; вернуть режимы
 	pop	ds	 	; вернуть сегмент
 	assume	ds:data

;   Инициализация буфера дисплея

 	xor	di,di	 	; DI=0
 	mov	crt_start,di	; сохранить начальный адрес
 	mov	active_page,0	; установить активную страницу
 	mov	cx,8192 	; количество слов в цветном адаптере
 	cmp	ah,4	 	; опрос графики
 	jc	m12	 	; нет инициализации графики
 	cmp	ah,7	 	; опрос ч/б адаптера
 	je	m11	 	; инициализация ч/б адаптера
 	xor	ax,ax	 	; для графического режима
 	jmp	short m13	; очистить буфер
m11:	 	 	 	; инициализация ч/б адаптера
 	mov	cx,2048 	; об'ем буфера ч/б адаптера
m12:
 	mov	ax,' '+7*256    ; заполнить характеристики для альфа
m13:	 	 	 	; очистить буфер
 	rep	stosw	 	; заполнить область буфера пробелами

;   Формирование порта управления режимом

 	mov	cursor_mode,607h   ; установить режим текущего курсора
 	mov	al,crt_mode	; получить режим в регистре AX
 	xor	ah,ah
 	mov	si,ax	 	; таблица указателей режима
 	mov	dx,addr_6845	; подготовить адрес порта для вывода
 	add	dx,4
 	mov al,cs:[si+offset m7]
 	out	dx,al
 	mov	crt_mode_set,al

;   Форморование количества колонок

 	mov al,cs:[si+offset m6]
 	xor	ah,ah
 	mov	crt_cols,ax	; коичество колонок на экране

;   Установить позицию курсора

 	and	si,0eh	 	;
 	mov cx,cs:[si+offset m5]  ; длина для очистки
 	mov	crt_len,cx
 	mov	cx,8	 	; очистить все позиции курсора
 	mov	di,offset cursor_posn
 	push	ds	 	; восстановить сегмент
 	pop	es
 	xor	ax,ax
 	rep	stosw	 	; заполнить нулями

;   Установка регистра сканирования

 	inc	dx	 	; уст порт сканирования по умолчанию
 	mov	al,30h	 	; значение 30H для всех режимов,
 	 	 	 	; исключая 640х200
 	cmp	crt_mode,6	; режим ч/б 640х200
 	jnz	m14	 	; если не 640х200
 	mov	al,3fh	 	; если 640х200, то поместить в 3FH
m14:	out	dx,al	 	; вывод правильного значения в порт 3D9
 	mov	crt_pallette,al   ; сохранить значение для использования

;   Нормальный возврат

video_return:
 	pop	bp
 	pop	di
 	pop	si
 	pop	bx
m15:
 	pop	cx	 	; восстановление регистров
 	pop	dx
 	pop	ds
 	pop	es
 	iret	 	 	; возврат из прерывания
set_mode	endp
;--------------------
; set_ctype
;
;   Эта программа устанавливает размер курсора и управление им
;
;   ВХОД
;	   (CX) - содержит размер курсора. (CH - начальная граница,
;	 	  CL - конечная граница)
;
;--------------------
set_ctype proc	near
 	mov	ah,10	 	; установить регистр 6845 для курсора
 	mov	cursor_mode,cx	 ; сохранить в области данных
 	call	m16	 	; вывод регистра CX
 	jmp	short video_return

m16:
 	mov	dx,addr_6845	; адрес регистра
 	mov	al,ah	 	; получить значение
 	out	dx,al	 	; установить регистр
 	inc	dx	 	; регистр данных
 	mov	al,ch	 	; данные
 	out	dx,al
 	dec	dx
 	mov	al,ah
 	inc	al	 	; указать другой регистр данных
 	out	dx,al	 	; установить второй регистр
 	inc	dx
 	mov	al,cl	 	; второе значение данных
 	out	dx,al
 	ret	 	 	; возврат
set_ctype	endp
;----------------------------
; set_cpos
;
;   Установить текущую позицию курсора
;
;   ВХОД
;	   DX - строка, колонка,
;	   BH - номер страницы.
;
;-----------------------------
set_cpos proc	near
 	mov	cl,bh
 	xor	ch,ch	 	; установить счетчик
 	sal	cx,1	 	; сдвиг слова
 	mov	si,cx
 	mov word ptr [si + offset cursor_posn],dx  ;сохранить указатель
 	cmp	active_page,bh
 	jnz	m17
 	mov	ax,dx	 	; получить строку/колонку в AX
 	call	m18	 	; установить курсор
m17:
 	jmp	short video_return  ; возврат
set_cpos	endp

;   Установить позицию курсора, AX содержит  строку/колонку

m18	proc	near
 	call	position
 	mov	cx,ax
 	add	cx,crt_start	; сложить с начальным адресом страницы
 	sar	cx,1	 	; делить на 2
 	mov	ah,14
 	call	m16
 	ret
m18	endp
;---------------------------
; read_cursor
;
;   Считать текущее положение курсора
;
;   Эта программа восстанавливает текущее положение курсора
;
;   ВХОД
;	   BH - номер страницы
;
;   ВЫХОД
;	   DX - строка/колонка текущей позиции курсора,
;	   CX - размер курсора и управление им
;
;---------------------------
read_cursor proc near
 	mov	bl,bh
 	xor	bh,bh
 	sal	bx,1
 	mov dx,word ptr [bx+offset cursor_posn]
 	mov	cx,cursor_mode
 	pop	bp
 	pop	di	 	; восстановить регистры
 	pop	si
 	pop	bx
 	pop	ax
 	pop	ax
 	pop	ds
 	pop	es
 	iret
read_cursor	endp
;-----------------------------
; act_disp_page
;
;    Эта программа устанавливает активную страницу буфера адаптера ЭЛИ
;
;   ВХОД
;	   AL - страница.
;
;   ВЫХОД
;	   Выполняется сброс контроллера для установки новой страницы.
;
;-----------------------------
act_disp_page proc	near
 	mov	active_page,al	; сохранить значение активной страницы
 	mov	cx,crt_len	; получить длину области буфера
 	cbw	 	 	; преобразовать AL
 	push	ax	 	; сохранить значение страницы
 	mul	cx
 	mov	crt_start,ax	; сохранить начальный адрес
 	 	 	 	; для следующего требования
 	mov	cx,ax	 	; переслать начальный адрес в CX
 	sar	cx,1	 	; делить на 2
 	mov	ah,12
 	call	m16
 	pop	bx	 	; восстановить значение страницы
 	sal	bx,1
 	mov ax,word ptr [bx+offset cursor_posn]   ; получить курсор
 	call	m18	 	; установить позицию курсора
 	jmp	video_return
act_disp_page	endp
;------------------------------
; set color
;
;   Эта программа устанавливает цветовую палитру.
;
;   ВХОД
;	   BH=0
;	 	BL - значение пяти младших бит, используемых для выбора
;	 	     цветовой палитры (цвет заднего плана для цветной
;	 	     графики 320х200 или цвет каймы для цветного 40х25)
;	   BH=1
;	 	BL - номер цветовой палитры
;	 	     BL=0 - зеленый(1), красный(2), желтый(3),
;	 	     BL=1 - голубой(1), фиолетовый(2), белый (3)
;
;   ВЫХОД
;	   Установленная цветовая палитра в порту 3D9.
;------------------------------
set_color proc	near
 	mov	dx,addr_6845	; порт для палитры
 	add	dx,5	 	; установить порт
 	mov	al,crt_pallette   ; получить текущее значение палитры
 	or	bh,bh	 	; цвет 0 ?
 	jnz	m20	 	; вывод цвета 1

;   Обработка цветовой палитры 0

 	and	al,0e0h 	; сбросить 5 младших бит
 	and	bl,01fh 	; сбросить 3 старших бита
 	or	al,bl
m19:
 	out	dx,al	 	 ; вывод выбранного цвета в порт 3D9
 	mov	crt_pallette,al  ; сохранить значение цвета
 	jmp	video_return

;   Обработка цветовой палитры 1

m20:
 	and	al,0dfh 	;
 	shr	bl,1	 	; проверить младший бит BL
 	jnc	m19
 	or	al,20h	 	;
 	jmp	short m19	; переход
set_color	endp
;--------------------------
; video state
;
;   Эта программа получает текущее состояние ЭЛИ в AX.
;
;	   AH - количество колонок,
;	   AL - текущий режим,
;	   BH - номер активной страницы.
;
;---------------------------
video_state proc	near
 	mov	ah,byte ptr crt_cols   ; получить количество колонок
 	mov	al,crt_mode	 	; текущий режим
 	mov	bh,active_page	; получить текущую активную страницу
 	pop	bp
 	pop	di	 	; восстановить регистры
 	pop	si
 	pop	cx
 	jmp	m15	 	; возврат к программе
video_state	endp
;---------------------------
; position
;
;   Эта программа вычисляет адрес буфера символа в режиме альфа.
;
;   ВХОД
;	   AX - номер строки, номер колонки,
;
;   ВЫХОД
;	   AX - смещение символа с координатами (AH, AL) относительно
;	 	начала страницы. Смещение измеряется в байтах.
;
;----------------------------
position proc	near
 	push	bx	 	; сохранить регистр
 	mov	bx,ax
 	mov	al,ah	 	; строки в AL
 	mul	byte ptr crt_cols
 	xor	bh,bh
 	add	ax,bx	 	; добавить к значению колонки
 	sal	ax,1	 	; * 2 для байтов атрибута
 	pop	bx
 	ret
position	endp
;-------------------------------
;scroll up
;
;   Эта программа перемещает блок символов вверх по экрану.
;
;   ВХОД
;	   AH - текуший режим,
;	   AL - количество перемещаемых строк
;	   CX - координаты левого верхнего угла блока
;	 	(строка, колонка),
;	   DX - координаты правого нижнего угла
;	   BH - атрибут символа пробела (для опробеливания освобожда-
;	 	емых строк),
;
;   ВЫХОД
;	   Модифицированный буфер дисплея.
;
;-----------------------------------
 	assume cs:code,ds:data,es:data
scroll_up proc	near
 	mov	bl,al	    ; сохранить количество перемещаемых строк
 	cmp	ah,4	 	; проверка графического режима
 	jc	n1
 	cmp	ah,7	 	; проверка ч/б адаптера
 	je	n1
 	jmp	graphics_up
n1:
 	push	bx	 	; сохранить полный атрибут в BH
 	mov	ax,cx	 	; координаты левого верхнего угла
 	call	scroll_position
 	jz	n7
 	add	si,ax
 	mov	ah,dh	 	; строка
 	sub	ah,bl
n2:
 	call	n10	 	; сдвинуть одну строку
 	add	si,bp
 	add	di,bp	 	; указать на следующую строку в блоке
 	dec	ah	 	; счетчик строк для сдвига
 	jnz	n2	 	; цикл строки
n3:	 	 	 	; очистка входа
 	pop	ax	 	; восстановить атрибут в AH
 	mov	al,' '          ; заполнить пробелами
n4:	 	 	 	; очистка счетчика
 	call	n11	 	; очистка строки
 	add	di,bp	 	; указать следующую строку
 	dec	bl	 	; счетчик строк для сдвига
 	jnz	n4	 	; очистка счетчика
n5:	 	 	 	; конец сдвига
 	mov	ax,dat
 	mov	ds,ax
 	cmp	crt_mode,7	; ч/б адаптер ?
 	je	n6	 	; если да - пропуск режима сброса
 	mov	al,crt_mode_set
 	mov	dx,03d8h	; установить порт цветного адаптера
 	out	dx,al
n6:
 	jmp	video_return
n7:
 	mov	bl,dh
 	jmp	short n3	; очистить
scroll_up	endp

;   Обработка сдвига

scroll_position proc	near
 	cmp	crt_mode,2
 	jb	n9	 	; обработать 80х25 отдельно
 	cmp	crt_mode,3
 	ja	n9

;   Сдиг для цветного адаптера в режиме 80х25

 	push	dx
 	mov	dx,3dah 	; обработка цветного адаптера
 	push	ax
n8:	 	 	 	; ожидание доступности дисплея
 	in	al,dx
 	test	al,8
 	jz	n8	 	; ожидание доступности дисплея
 	mov	al,25h
 	mov	dx,03d8h
 	out	dx,al	 	; выключить ЭЛИ
 	pop	ax
 	pop	dx
n9:	call	position
 	add	ax,crt_start	; смещение активной страницы
 	mov	di,ax	 	; для адреса сдвига
 	mov	si,ax
 	sub	dx,cx	 	; DX=строка
 	inc	dh
 	inc	dl	 	; прибавление к началу
 	xor	ch,ch	 	; установить старший байт счетчика в 0
 	mov	bp,crt_cols	; получить число колонок дисплея
 	add	bp,bp	 	; увеличить на 2 байт атрибута
 	mov	al,bl	 	; получить счетчик строки
 	mul	byte ptr crt_cols   ; определить смещение из адреса,
 	add	ax,ax	  ; умноженного на 2, для байта атрибута
 	push	es	; установить адресацию для области буфера
 	pop	ds
 	cmp	bl,0	 	; 0 означает очистку блока
 	ret	 	 	; возврат с установкой флажков
scroll_position endp

;   Перемещение строки

n10	proc	near
 	mov	cl,dl	 	; получить колонки для передачи
 	push	si
 	push	di	 	; сохранить начальный адрес
 	rep	movsw	 	; передать эту строку на экран
 	pop	di
 	pop	si	 	; восстановить адресацию
 	ret
n10	endp

;   очистка строки

n11	proc	near
 	mov	cl,dl	 	; получить колонки для очистки
 	push	di
 	rep	stosw	 	; запомнить полный знак
 	pop	di
 	ret
n11	endp
;------------------------
; scroll_down
;
;   Эта программа перемещает блок символов вниз по
; экрану, заполняя верхние строки пробелом с заданным атрибутом
;
;   ВХОД
;	   AH - текущий режим,
;	   AL - количество строк,
;	   CX - верхний левый угол блока,
;	   DX - правый нижний угол блока,
;	   BH - атрибут символа-заполнителя (пробела),
;
;-------------------------
scroll_down proc near
 	std	 	 	; уст направление сдвига вниз
 	mov	bl,al	 	; количество строк в BL
 	cmp	ah,4	 	; проверка графики
 	jc	n12
 	cmp	ah,7	 	; проверка ч/б адаптера
 	je	n12
 	jmp	graphics_down
n12:
 	push	bx	 	; сохранить атрибут в BH
 	mov	ax,dx	 	; нижний правый угол
 	call	scroll_position
 	jz	n16
 	sub	si,ax	 	; SI для адресации
 	mov	ah,dh
 	sub	ah,bl	 	; передать количество строк
n13:
 	call	n10	 	; передать одну строку
 	sub	si,bp
 	sub	di,bp
 	dec	ah
 	jnz	n13
n14:
 	pop	ax	 	; восстановить атрибут в AH
 	mov	al,' '
n15:
 	call	n11	 	; очистка одной строки
 	sub	di,bp	 	; перейти к следующей строке
 	dec	bl
 	jnz	n15
 	jmp	n5	 	; конец сдвига
n16:
 	mov	bl,dh
 	jmp	short n14
scroll_down  endp
;--------------------
; read_ac_current
;
;   Эта программа считывает атрибут и код символа, находящегося в теку-
; щем положении курсора
;
;   ВХОД
;	   AH - текущий режим,
;	   BH - номер страницы (только для режима альфа),
;
;   ВЫХОД
;	   AL - код символа,
;	   AH - атрибут символа.
;
;---------------------
 	assume cs:code,ds:data,es:data
read_ac_current proc near
 	cmp	ah,4	 	; это графика ?
 	jc	p1
 	cmp	ah,7	 	; ч/б адаптер ?
 	je	p1
 	jmp	graphics_read
p1:	 	 	 	;
 	call	find_position
 	mov	si,bx	 	; установить адресацию в SI


 	mov	dx,addr_6845	; получить базовый адрес
 	add	dx,6	 	; порт состояния
 	push	es
 	pop	ds	 	; получить сегмент
p2:
 	in	al,dx	 	; получить состояние
 	test	al,1
 	jnz	p2	 	; ожидание
 	cli	 	   ; сброс признака разрешения прерывания
p3:
 	in	al,dx	 	; получить состояние
 	test	al,1
 	jz	p3	 	; ожидание
 	lodsw	 	 	; получить символ/атрибут
 	jmp	video_return
read_ac_current endp

find_position proc near
 	mov	cl,bh	 	; поместить страницу в CX
 	xor	ch,ch
 	mov	si,cx	 	; передать в SI индекс, умноженный на 2
 	sal	si,1	 	; для слова смещения
 	mov ax,word ptr [si+offset cursor_posn]   ; получить строку/ко-
 	 	 	 	; лонку этой страницы
 	xor	bx,bx	 	; установить начальный адрес в 0
 	jcxz	p5
p4:
 	add	bx,crt_len	; длина буфера
 	loop	p4
p5:
 	call	position
 	add	bx,ax
 	ret
find_position	endp
;---------------------
;write_ac_current
;
;   Эта программа записывает атрибут и код символа в текущую позицию
; курсора
;
;   ВХОД
;	   AH - текущий режим,
;	   BH - номер страницы,
;	   CX - счетчик (количество повторений символов),
;	   AL - код символа,
;	   BL - атрибут символа (для режимов альфа) или цвет символа
;	 	для графики.
;
;----------------------
write_ac_current proc near
 	cmp	ah,4	 	; это графика ?
 	jc	p6
 	cmp	ah,7	 	; это ч/б адаптер ?
 	je	p6
 	jmp	graphics_write
p6:
 	mov	ah,bl	 	; получить атрибут в AH
 	push	ax	 	; хранить
 	push	cx	 	; хранить счетчик
 	call	find_position
 	mov	di,bx	 	; адрес в DI
 	pop	cx	 	; вернуть счетчик
 	pop	bx	 	; и символ
p7:	 	 	 	; цикл записи


 	mov	dx,addr_6845	; получить базовый адрес
 	add	dx,6	 	; указать порт состояния
p8:
 	in	al,dx	 	; получить состояние
 	test	al,1
 	jnz	p8	 	; ожидать
 	cli	 	     ; сброс признака разрешения прерывания
p9:
 	in	al,dx	 	; получить состояние
 	test	al,1
 	jz	p9	 	; ожидать
 	mov	ax,bx
 	stosw	 	 	; записать символ и атрибут
 	sti	 	 	; уст признак разрешения прерывания
 	loop	p7
 	jmp	video_return
write_ac_current  endp
;---------------------
;write_c_current
;
;   Эта программа записывает символ в текущую позицию курсора.
;
;   ВХОД
;	   BH - номер страницы (только для альфа режимов),
;	   CX - счетчик (количество повторений символа),
;	   AL - код символа,
;
;-----------------------
write_c_current proc near
 	cmp	ah,4	 	; это графика ?
 	jc	p10
 	cmp	ah,7	 	; это ч/б адаптер ?
 	je	p10
 	jmp	graphics_write
p10:
 	push	ax	 	; сохранить в стеке
 	push	cx	 	; сохранить количество повторений
 	call	find_position
 	mov	di,bx	 	; адрес в DI
 	pop	cx	 	; вернуть количество повторений
 	pop	bx	 	; BL - код символа
p11:


 	mov	dx,addr_6845	; получить базовый адрес
 	add	dx,6	 	; указать порт состояния
p12:
 	in	al,dx	 	; получить состояние
 	test	al,1
 	jnz	p12	 	; ожидать
 	cli	 	 	; сброс признака разрешения прерывания
p13:
 	in	al,dx	 	; получить состояние
 	test	al,1
 	jz	p13	 	; ожидание
 	mov	al,bl	 	; восстановить символ
 	stosb	 	 	; записать символ
 	inc	di
 	loop	p11	 	; цикл
 	jmp	video_return
write_c_current endp
;---------------------
; read dot - write dot
;
;   Эта программа считывает/записывает точку.
;
;   ВХОД
;	   DX - строка (0-199),
;	   CX - колонка (0-639),
;	   AL - цвет выводимой точки.
;	 	Если бит 7=1, то выполняется операция
;	 	XOR над значением точки из буфера дисплея и значением
;	 	точки из регистра AL (при записи точки).
;
;   ВЫХОД
;	   AL - значение считанной точки
;
;----------------------
 	assume cs:code,ds:data,es:data
read_dot proc	near
 	call	r3	 	; определить положение точки
 	mov	al,es:[si]	; получить байт
 	and	al,ah	 	; размаскировать другие биты в байте
 	shl	al,cl	 	;
 	mov	cl,dh	 	; получить число бит результата
 	rol	al,cl
 	jmp	video_return	; выход из прерывания
read_dot	endp

write_dot proc	near
 	push	ax	 	; сохранить значение точки
 	push	ax	 	; еще раз
 	call	r3	 	; определить положение точки
 	shr	al,cl	 	; сдвиг для установки бит при выводе
 	and	al,ah	 	; сбросить другие биты
 	mov	cl,es:[si]	; получить текущий байт
 	pop	bx
 	test	bl,80h
 	jnz	r2
 	not	ah	  ; установить маску для передачи указанных бит
 	and	cl,ah
 	or	al,cl
r1:
 	mov es:[si],al	 	; восстановить байт в памяти
 	pop	ax
 	jmp	video_return	; к выходу из программы
r2:
 	xor	al,cl	 	; исключающее ИЛИ над значениями точки
 	jmp	short r1	; конец записи
write_dot	endp

;-------------------------------------
;
;   Эта программа определяет относительный адрес байта (внутри буфера
; дисплея), из которого должна быть считана/записана точка,с заданными
; координатами.
;
;   ВХОД
;	   DX - строка (0-199),
;	   CX - колонка (0-639).
;
;   ВЫХОД
;	   SI - относительный адрес байта, содержащего точку внутри
;	 	буфера дисплея,
;	   AH - маска для выделения значения заданной точки внутри байта
;	   CL - константа сдвига маски в AH в крайнюю левую позицию,
;	   DH - число бит, определяющих значение точки.
;
;--------------------------------------

r3	proc	near
 	push	bx	 	; сохранить BX
 	push	ax	 	; сохранить AL

;   Вычисление первого байта указанной строки умножением на 40.
; Наименьший бит строки определяет четно/нечетную 80-байтовую строку.

 	mov	al,40
 	push	dx	 	; сохранить значение строки
 	and	dl,0feh 	; сброс четно/нечетного бита
 	mul	dl   ; AX содержит адрес первого байта указанной строки
 	pop	dx	 	; восстановить его
 	test	dl,1	 	; проверить четность/нечетность
 	jz	r4	 	; переход,если строка четная
 	add	ax,2000h	; смещение для нахождения нечетных строк
r4:	 	 	 	; четная строка
 	mov	si,ax	 	; передать указатель в SI
 	pop	ax	 	; восстановить значение AL
 	mov	dx,cx	 	; значение колонки в DX

;   Определение действительных графических режимов
;
;   Установка регистров согласно режимaм
;
;	  BH - количество бит, определяющее точку,
;	  BL - константа выделения точки из левых бит байта,
;	  CH - константа для выделения из номера колонки номера позиции
;	       первого бита, определяющего точку в байте, т.е. получение
;	       остатка от деления номера на 8 (для режима 640х200) или
;	       номера на 4 (для режима 320х200),
;	  CL - константа сдвига (для выполнения деления на 8 или на 4).

 	mov	bx,2c0h
 	mov	cx,302h 	; установка параметров
 	cmp	crt_mode,6
 	jc	r5	 	;
 	mov	bx,180h
 	mov	cx,703h 	; уст параметры для старшего регистра

;   Определение бита смещения в байте по маске
r5:
 	and	ch,dl	 	;

;   Определение байта смещения в колонке

 	shr	dx,cl	 	; сдвиг для коррекции
 	add	si,dx	 	; получить указатель
 	mov	dh,bh	; получить указатель битов результата в DH

;   Умножение BH (количество бит в байте) на CH (бит смещения)

 	sub	cl,cl
r6:
 	ror	al,1	; левое крайнее значение в AL для записи
 	add	cl,ch	 	; прибавить значение бита смещения
 	dec	bh	 	; счетчик контроля
 	jnz	r6	; на выходе CL содержит счетчик сдвига для
 	 	 	 	; восстановления
 	mov	ah,bl	 	; получить маску в AH
 	shr	ah,cl	 	; передать маску в ячейку
 	pop	bx	 	; восстановить регистр
 	ret	 	 	; возврат с восстановлением
r3	endp

;----------------------------------------
;
;
;    Программа перемещает блок символов вверх в режиме графики
;
;-----------------------------------------

graphics_up proc near
 	mov	bl,al	 	; сохранить количество символов
 	mov	ax,cx	 	; получить верхний левый угол в AX


 	call	graph_posn
 	mov	di,ax	 	; сохранить результат

;   Определить размеры блока

 	sub	dx,cx
 	add	dx,101h
 	sal	dh,1
 	sal	dh,1

 	cmp	crt_mode,6
 	jnc	r7

 	sal	dl,1
 	sal	di,1	 	;

;   Определение адреса источника в буфере
r7:
 	push	es
 	pop	ds
 	sub	ch,ch	 	; обнулить старший байт счетчика
 	sal	bl,1	 	; умножение числа строк на 4
 	sal	bl,1
 	jz	r11	 	; если 0, занести пробелы
 	mov	al,bl	 	; получить число строк в AL
 	mov	ah,80	 	; 80 байт/строк
 	mul	ah	 	; определить смещение источника
 	mov	si,di	 	; установить источник
 	add	si,ax	 	; сложить источник с ним
 	mov	ah,dh	 	; количество строк
 	sub	ah,bl	 	; определить число перемещений

r8:
 	call	r17	 	; перемещение одной строки
 	sub	si,2000h-80	; перемещение в следующую строку
 	sub	di,2000h-80
 	dec	ah	 	; количество строк для перемещения
 	jnz	r8	; продолжать, пока все строки не переместятся

;   Заполнение освобожденных строк
r9:
 	mov	al,bh
r10:
 	call	r18	 	; очистить эту строку
 	sub	di,2000h-80	; указать на следующую
 	dec	bl	 	; количество строк для заполнения
 	jnz	r10	 	; цикл очистки
 	jmp	video_return	; к выходу из программы

r11:
 	mov	bl,dh	 	; установить количество пробелов
 	jmp	short r9	; очистить
graphics_up	endp

;---------------------------------
;
;   Программа перемещает блок символов вниз в режиме графики
;
;----------------------------------

graphics_down proc	near
 	std	 	 	; установить направление
 	mov	bl,al	 	; сохранить количество строк
 	mov	ax,dx	 	; получить нижнюю правую позицию в AX


 	call	graph_posn
 	mov	di,ax	 	; сохранить результат

;   Определение размера блока

 	sub	dx,cx
 	add	dx,101h
 	sal	dh,1
 	sal	dh,1


 	cmp	crt_mode,6
 	jnc	r12

 	sal	dl,1
 	sal	di,1
 	inc	di

;   Определение адреса источника в буфере
r12:
 	push	es
 	pop	ds
 	sub	ch,ch	 	; обнулить старший байт счетчика
 	add	di,240	 	; указать последнюю строку
 	sal	bl,1	 	; умножить количество строк на 4
 	sal	bl,1
 	jz	r16	 	; если 0, заполнить пробелом
 	mov	al,bl	 	; получить количество строк в AL
 	mov	ah,80	 	; 80 байт/строк
 	mul	ah	 	; определить смещение источника
 	mov	si,di	 	; установить источник
 	sub	si,ax	 	; вычесть смещение
 	mov	ah,dh	 	; количество строк
 	sub	ah,bl	 	; определить число для перемещения

r13:
 	call	r17	 	; переместить одну строку
 	sub	si,2000h+80	; установить следующую строку
 	sub	di,2000h+80
 	dec	ah	 	; количество строк для перемещения
 	jnz	r13	 	; продолжать, пока все не переместятся

;   Заполнение освобожденных строк
r14:
 	mov	al,bh	 	; атрибут заполнения
r15:
 	call	r18	 	; очистить строку
 	sub	di,2000h+80	; указать следующую строку
 	dec	bl	 	; число строк для заполнения
 	jnz	r15
 	cld	 	 	; сброс признака направления
 	jmp	video_return	; к выходу из программы

r16:
 	mov	bl,dh
 	jmp	short r14	; очистить
graphics_down endp

;   Программа перемещения одной строки

r17	proc	near
 	mov	cl,dl	 	; число байт в строке
 	push	si
 	push	di	 	; хранить указатели
 	rep	movsb	 	; переместить четное поле
 	pop	di
 	pop	si
 	add	si,2000h
 	add	di,2000h	; указать нечетное поле
 	push	si
 	push	di	 	; сохранить указатели
 	mov	cl,dl	 	; возврат счвтчика
 	rep	movsb	 	; передать нечетное поле
 	pop	di
 	pop	si	 	; возврат указателей
 	ret	 	 	; возврат к программе
r17	endp

;   Заполнение пробелами строки

r18	proc	near
 	mov	cl,dl	 	; число байт в поле
 	push	di	 	; хранить указатель
 	rep	stosb	 	; запомнить новое значение
 	pop	di	 	; вернуть указатель
 	add	di,2000h	; указать нечетное поле
 	push	di
 	mov	cl,dl
 	rep	stosb	 	; заполнить нечетное поле
 	pop	di
 	ret	 	 	; возврат к программе
r18	endp

;--------------------------------------
;
;  graphics_write
;
;   Эта программа записывает символ в режиме графики
;
;   ВХОД
;	   AL - код символа,
;	   BL - атрибут цвета, который используется в качестве цвета
;	 	переднего плана (цвет символа). Если бит 7 BL=1, то
;	 	выполняется операция XOR над байтом в буфере и байтом
;	 	в генераторе символов,
;	   CX - счетчик повторений символа
;
;----------------------------------------

 	assume cs:code,ds:data,es:data
graphics_write proc near
 	mov	ah,0	 	; AH=0
 	push	ax	 	; сохранить значение кода символа

;   Определение позиции в области буфера засылкой туда кода точек

 	call	s26	 	; найти ячейку в области буфера
 	mov	di,ax	 	; указатель области в DI

;   Определение области для получения кода точки

 	pop	ax	 	; восстановить код точки
 	cmp	al,80h	 	; во второй половине ?
 	jae	s1	 	; да

;   Изображение есть в первой половине памяти

 	mov	si, offset crt_char_gen  ; смещение изображения
 	push	cs	 	; хранить сегмент в стеке
 	jmp	short s2	; определить режим

;   Изображение есть во второй части памяти

s1:
 	sub	al,80h	 	; 0 во вторую половину
 	push	ds	 	; хранить указатель данных
 	sub	si,si
 	mov	ds,si	 	; установить адресацию
 	assume	ds:abs0
 	lds	si,ext_ptr	; получить смещение
 	mov	dx,ds	 	; получить сегмент
 	assume	ds:data
 	pop	ds	 	; восстановить сегмент данных
 	push	dx	 	; хранить сегмент в стеке

;   Опеделение графического режима операции

s2:	 	 	 	; определение режима
 	sal	ax,1	 	; умножить указатель кода на 8
 	sal	ax,1
 	sal	ax,1
 	add	si,ax	 	; SI содержит смещение
 	cmp	crt_mode,6
 	pop	ds	 	; восстановить указатель таблицы
 	jc	s7	; проверка для средней разрешающей способности

;   Высокая разрешающая способность
s3:
 	push	di	 	; сохранить указатель области
 	push	si	 	; сохранить указатель кода
 	mov	dh,4	 	; количество циклов
s4:
 	lodsb	 	 	; выборка четного байта
 	test	bl,80h
 	jnz	s6
 	stosb
 	lodsb
s5:
 	mov es:[di+1fffh],al	; запомнить во второй части
 	add	di,79	 	; передать следующую строку
 	dec	dh	 	; выполнить цикл
 	jnz	s4
 	pop	si
 	pop	di	 	; восстановить указатель области
 	inc	di	; указать на следующую позицию символа
 	loop	s3	 	; записать последующие символы
 	jmp	video_return

s6:
 	xor al,es:[di]
 	stosb	 	 	; запомнить код
 	lodsb	 	 	; выборка нечетного символа
 	xor  al,es:[di+1fffh]
 	jmp	s5	 	; повторить

;   Средняя разрешающая способность записи
s7:
 	mov	dl,bl	 	; сохранить старший бит цвета
 	sal	di,1	; умножить на 2, т.к. два байта/символа
 	call	s19	 	; расширение BL до полного слова цвета
s8:
 	push	di
 	push	si
 	mov	dh,4	 	; число циклов
s9:
 	lodsb	 	 	; получить код точки
 	call	s21	 	; продублировать
 	and	ax,bx	 	; окрашивание в заданный цвет
 	test	dl,80h
 	jz	s10
 	xor	ah,es:[di]	; выполнить функцию XOR со "старым"
 	xor	al,es:[di+1]	; и "новым" цветами
s10:	mov  es:[di],ah 	; запомнить первый байт
 	mov es:[di+1],al	; запомнить второй байт
 	lodsb	 	 	; получить код точки
 	call	s21
 	and	ax,bx	 	; окрашивание нечетного байта
 	test	dl,80h
 	jz  s11
 	xor	ah,es:[di+2000h]   ; из первой половины
 	xor	al,es:[di+2001h]   ; и из второй половины
s11:	mov	es:[di+2000h],ah
 	mov	es:[di+2001h],al   ; запомнить вторую часть буфера
 	add	di,80	 	; указать следующую ячейку
 	dec	dh
 	jnz	s9	 	; повторить
 	pop	si
 	pop	di
 	add	di,2	 	; переход к следующему символу
 	loop	s8	 	; режим записи
 	jmp	video_return
graphics_write	endp
;-------------------------------------
;graphics_read
;
;   Программа считывает символ в режиме графики
;
;-------------------------------------
graphics_read	proc	near
 	call	s26
 	mov	si,ax	 	; сохранить в SI
 	sub	sp,8	 	; зарезервировать в стеке 8 байт для
 	 	 	 	; записи символа из буфера дисплея
 	mov	bp,sp	 	; указатель для хранения области

;   Определение режима графики

 	cmp	crt_mode,6
 	push	es
 	pop	ds	 	; указать сегмент
 	jc	s13	 	; средняя разрешающая способность

;  Высокая разрешающая способность для считавания

 	mov	dh,4
s12:
 	mov	al,byte ptr [si]   ; получить первый байт
 	mov byte ptr [bp],al	   ; запомнить в памяти
 	inc	bp
 	mov al,byte ptr [si+2000h]   ; получить младший байт
 	mov byte ptr [bp],al
 	inc	bp
 	add	si,80	 	; переход на следующую четную строку
 	dec	dh
 	jnz	s12	 	; повторить
 	jmp	s15	 	; переход к хранению кодов точек

;   Средняя разрешающая способность для считывания
s13:
 	sal	si,1	  ; смещение умножить на 2, т.к. 2 байта/символа
 	mov	dh,4
s14:
 	call	s23
 	add	si,2000h
 	call	s23
 	sub	si,2000h-80
 	dec	dh
 	jnz	s14	 	; повторить

;   Сохранить
s15:
 	mov	di,offset crt_char_gen	 ; смещение
 	push	cs
 	pop	es
 	sub	bp,8	 	; восстановить начальный адрес
 	mov	si,bp
 	cld	 	 	; установить направление
 	mov	al,0
s16:
 	push	ss
 	pop	ds
 	mov	dx,128	 	; количество символов
s17:
 	push	si
 	push	di
 	mov	cx,8	 	; количество байт в символе
 	repe	cmpsb	 	; сравнить
 	pop	di
 	pop	si
 	jz	s18	 	; если признак = 0,символы сравнились
 	inc	al	 	; не сравнились
 	add	di,8	 	; следующий код точки
 	dec	dx	 	; - 1 из счетчика
 	jnz	s17	 	; повторить


 	cmp	al,0
 	je	s18    ; переход, если все сканировано, но символ
 	 	       ; не найден
 	sub	ax,ax
 	mov	ds,ax	 	; установить адресацию вектора
 	assume	ds:abs0
 	les	di,ext_ptr
 	mov	ax,es
 	or	ax,di
 	jz	s18
 	mov	al,128	 	; начало второй части
 	jmp	short s16	; вернуться и повторить
 	assume	ds:data

s18:
 	add	sp,8
 	jmp	video_return
graphics_read	endp

;---------------------------------
;
;   Эта программа заполняет регистр BX двумя младшими битами
; регистра BL.
;
;   ВХОД
;	   BL - используемый цвет (младшие два бита).
;
;   ВЫХОД
;	   BX - используемый цвет (восемь повторений двух битов цвета).
;
;---------------------------------
s19	proc	near
 	and	bl,3	 	; выделить биты цвета
 	mov	al,bl	 	; переписать в AL
 	push	cx	 	; сохранить регистр
 	mov	cx,3	 	; количество повторений
s20:
 	sal	al,1
 	sal	al,1	 	; сдвиг влево на 2
 	or	bl,al	 	; в BL накапливается результат
 	loop	s20	 	; цикл
 	mov	bh,bl	 	; заполнить
 	pop	cx
 	ret	 	 	; все выполнено
s19	endp
;--------------------------------------
;
;   Эта программа берет байт в AL и удваивает все биты, превращая
; 8 бит в 16 бит. Результат помещается в AX.
;--------------------------------------
s21	proc	near
 	push	dx	 	; сохранить регистры
 	push	cx
 	push	bx
 	mov	dx,0	 	; результат удвоения
 	mov	cx,1	 	; маска
s22:
 	mov	bx,ax
 	and	bx,cx	 	; выделение бита
 	or	dx,bx	 	; накапливание результата
 	shl	ax,1
 	shl	cx,1	 	; сдвинуть базу и маску на 1
 	mov	bx,ax
 	and	bx,cx
 	or	dx,bx
 	shl	cx,1	; сдиг маски, для выделения следующего бита
 	jnc	s22
 	mov	ax,dx
 	pop	bx	 	; восстановить регистры
 	pop	cx
 	pop	dx
 	ret	 	 	; к выходу из прерывания
s21	endp

;----------------------------------
;
;   Эта программа преобразовывает двух-битовое представление точки
; (C1,C0) в однобитовое
; (C1,C0) к однобитовому.
;
;----------------------------------
s23	proc	near
 	mov	ah,byte ptr [si]   ; получить первый байт
 	mov	al,byte ptr [si+1]   ; получить второй байт
 	mov	cx,0c000h	; 2 бита маски
 	mov	dl,0	 	; регистр результата
s24:
 	test	ax,cx	 	; проверка 2 младших бит AX на 0
 	clc	 	 	; сбросить признак переноса CF
 	jz	s25	 	; переход если 0
 	stc	 	 	; нет - установить CF
s25:	rcl	dl,1	 	; циклический сдвиг
 	shr	cx,1
 	shr	cx,1
 	jnc	s24	 	; повторить, если CF=1
 	mov byte ptr [bp],dl	; запомнить результат
 	inc	bp
 	ret	 	 	; к выходу из прерывания
s23	endp

;---------------------------------------
;
;   Эта программа определает положение курсора относительно	 мяти и
; начала буфера в режиме графики	 	 	 	 /символ
;
;   ВЫХОД
;	   AX  содержит смещение курсора
;
;-----------------------------------------
s26	proc	near
 	mov	ax,cursor_posn	; получить текущее положение курсора
graph_posn	label	near
 	push	bx	 	; сохранить регистр
 	mov	bx,ax	 	; сохранить текущее положение курсора
 	mov	al,ah	 	; строка
 	mul	byte ptr crt_cols   ; умножить на байт/колонку
 	shl	ax,1	 	; умножить на 4
 	shl	ax,1
 	sub	bh,bh	 	; выделить значение колонки
 	add	ax,bx	 	; определить смещение
 	pop	bx
 	ret	 	 	; к выходу из прерывания
s26	endp

;
;----------------------------------------
;
;   Эта программа считывает положение светового пера.
; Проверяется переключатель и триггер светового пера. Если бит 1 ре-
; гистра состояния (порт 3DA)=1, то триггер установлен. Если бит 2 порта
; 3DA=0, то установлен переключатель.
;   Порты 3BD и 3DC используются для установки и сброса триггера и пере-
; ключателя светового пера.
;   В регистрах R16 и R17 контроллера содержится адрес координат пера
; относительно начала буфера дисплея.
;   Если триггер и переключатель установлены, то программа определяет
; положение светового пера, в противном случае, возврат без выдачи
; информации.
;
;   В ППЭВМ ЕС1841 функция не поддерживается
;-------------------------------------------------



 	org	0f7aeh


 	assume	cs:code,ds:data

;   Таблица поправок для получения фактических координат светового пера

v1	label	byte
 	db	3,3,5,5,3,3,3,4
read_lpen	proc	near


 	mov	ah,0	 	; код возврата, если перо не включено
 	mov	dx,addr_6845	; получить базовый адрес 6845
 	add	dx,6	 	; указать регистр состояния
 	in	al,dx	 	; получить регистр состояния
 	test	al,4	 	; проверить переключатель светового пера
 	jnz	v6	 	; не установлено, возврат

;   Проверка триггера светового пера

 	test	al,2	 	; проверить триггер светового пера
 	jz	v7	 	; возврат без сброса триггера

;   Триггер был установлен, считать значение в AH

 	mov	ah,16	 	; уст регистры светового пера 6845

;   Ввод регистров, указанных AH и преобразование в строки колонки в DX

 	mov	dx,addr_6845
 	mov	al,ah
 	out	dx,al	 	; вывести в порт
 	inc	dx
 	in	al,dx	 	; получить значение из порта
 	mov	ch,al	 	; сохранить его в CX
 	dec	dx	 	; регистр адреса
 	inc	ah
 	mov	al,ah	 	; второй регистр данных
 	out	dx,al
 	inc	dx
 	in	al,dx	 	; получить второе значение данных
 	mov	ah,ch	 	; AX содержит координаты светового пера


 	mov	bl,crt_mode
 	sub	bh,bh	 	; выделить значение режима в BX
 	mov	bl,cs:v1[bx]	; значение поправки
 	sub	ax,bx
 	sub	ax,crt_start

 	jns	v2
 	mov	ax,0	 	; поместить 0

;   Определить режим

v2:
 	mov	cl,3	 	; установить счетчик
 	cmp	crt_mode,4	; определить, режим графики или
 	 	 	 	; альфа
 	jb	v4	 	; альфа-перо
 	cmp	crt_mode,7
 	je	v4	 	; альфа-перо

;   Графический режим

 	mov	dl,40	 	; делитель для графики
 	div	dl	; определение строки (AL) и колонки (AH)
 	 	 	 	; пределы AL 0-99, AH 0-39

;   Определение положения строки для графики

 	mov	ch,al	 	; сохранить значение строки в CH
 	add	ch,ch	 	; умножить на 2 четно/нечетное поле
 	mov	bl,ah	 	; значение колонки в BX
 	sub	bh,bh	 	; умножить на 8 для среднего результата
 	cmp	crt_mode,6	; определить среднюю или наивысшую
 	 	 	 	; разрешающую способность
 	jne	v3	 	; не наивысшая разрешающая способность
 	mov	cl,4	 ; сдвинуть значение наивысшей разрешающей
 	 	 	 ; способности
 	sal	ah,1	; сдвиг на 1 разряд влево значения колонки
v3:	 	 	 	; не наивысшая разрешающая способность
 	shl	bx,cl	; умножить на 16 для наивысшей разрешающей
 	 	 	; способности

;   Определение положения символа для альфа

 	mov	dl,ah	 	; значение колонки для возврата
 	mov	dh,al	 	; значение строки
 	shr	dh,1	 	; делить на 4
 	shr	dh,1	 	; для значения в пределах 0-24
 	jmp	short v5	; возврат светового пера

;   Режим альфа светового пера

v4:	 	 	 	; альфа светового пера
 	div	byte ptr crt_cols  ; строка, колонка
 	mov	dh,al	 	; строка в DH
 	mov	dl,ah	 	; колонка в DL
 	sal	al,cl	 	; умножение строк на 8
 	mov	ch,al
 	mov	bl,ah
 	xor	bh,bh
 	sal	bx,cl
v5:
 	mov	ah,1	 	; указать, что все установлено
v6:
 	push	dx	 	; сохранить значение возврата
 	mov	dx,addr_6845	; получить базовый адрес
 	add	dx,7
 	out	dx,al	 	; вывод
 	pop	dx	 	; восстановить значение
v7:
 	pop	di	 	 ; восстановить регистры
 	pop	si
 	pop	ds
 	pop	ds
 	pop	ds
 	pop	ds
 	pop	es
 	iret
read_lpen	endp

;--- int 12 ------------------------------------
;
;    Программа определения размера памяти.
;
;    Эта программа передает в регистр AX об'ем памяти в Кбайтах.
;
;-----------------------------------------

 	assume	cs:code,ds:data
memory_size_determine	proc	far
 	sti	 	 	; установить бит разрешения прерывания
 	push	ds	 	; сохранить сегмент
 	mov	ax,dat	 	; установить адресацию
 	mov	ds,ax
 	mov	ax,memory_size	; получить значение размера памяти
 	pop	ds	 	; восстановить сегмент
 	iret	 	 	; возврат из прерывания
memory_size_determine	endp

;--- int 11-------------------------------
;
;    Программа определения состава оборудования.
;
;   Эта программа передает в регистр AX конфигурацию системы.
;
;   Разряды регистра AX имеют следующее значение:
;   0	    - загрузка системы с НГМД;
;   5,4     - тип подключенного ЭЛИ и режим его работы:
;	      00 - не используется;
;	      01 - 40х25, черно-белый режим цветного графического
;	 	   ЭЛИ;
;	      10 - 80х25, черно-белый режим цветного графического
;	 	   ЭЛИ;
;	      11 - 80х25, черно-белый режим монохромного ЭЛИ.
;   7,6     - количество НГМД;
;   11,10,9 - количество адаптеров стыка С2;
;   12	    - адаптер игр;
;   15,14   - количество печатающих устройств.
;   Разряды 6 и 7 устанавливаются только в том случае, если
; разряд 0 установлен в "1".
;
;----------------------------------------------

 	assume	cs:code,ds:data
equipment	proc	far
 	sti	 	 	; установить признак разрешения прерывания
 	push	ds	 	; сохранить сегмент
 	mov	ax,dat	 	; установить адресацию
 	mov	ds,ax
 	mov	ax,equip_flag	; получить конфигурацию системы
 	pop	ds	 	; восстановить сегмент
 	iret	 	 	; возврат из прерывания
equipment	endp

;****************************************
;
;   Загрузка знакогенератора
;
;****************************************

bct	proc	near
 	mov	ax,0dc00h
 	mov	es,ax
 	mov	cx,1000h
 	mov	dx,3b8h
 	xor	ax,ax
 	out	dx,al
 	xor	di,di
 	cld
 	rep	stosw
bct3:	mov	si,offset crt_char_gen
 	xor	di,di
 	xor	ax,ax
 	mov	cx,256
bct1:
 	mov	bl,8
bct2:	mov	al,cs:[si]
 	inc	si
 	mov	word ptr es:[di],ax
 	inc	di
 	inc	di
 	dec	bl
 	jnz	bct2
 	add	di,10h
 	dec	cx
 	jnz	pr128
 	jmp	zagrcw
pr128:	cmp	cx,128
 	jne	bct1
 	mov	si,offset crt_char_rus
 	jmp	bct1
kzagr:	ret
bct	endp

;
;   Таблица кодов русских маленьких букв (строчных)
;
rust	label	byte
 	db	1bh,'1234567890-='
 	db	08h,09h
 	db	0d9h,0e6h,0e3h,0dah,0d5h,0ddh,0d3h,0e8h
 	db	0e9h,0d7h,0d6h,0edh,0dh,-1,0e4h,0ebh
 	db	0d2h,0d0h,0dfh,0e0h,0deh,0dbh,0d4h,';:'
 	db	0d1h,0eeh,5ch,0efh,0e7h,0e1h,0dch,0d8h
 	db	0e2h,0ech,',./',0e5h,'*'
 	db	-1,' ',0eah


k30	label	byte
 	db	82,79,80,81,75,76,77
 	db	71,72,73
;---
 	db	16,17,18,19,20,21,22,23
 	db	24,25,30,31,32,33,34,35
 	db	36,37,38,44,45,46,47,48
 	db	49,50

;---
k89:	test	kb_flag,left_shift+right_shift
 	jz	k80
 	cmp	al,0f0h
 	je	k89a
 	cmp	al,0b0h
 	jb	k81
 	cmp	al,0cfh
 	ja	k81
 	add	al,20h
k81:	jmp	k61
k80:	cmp	al,0f1h
 	je	k89b
 	cmp	al,0d0h
 	jb	k81
 	cmp	al,0feh
 	ja	k81
 	sub	al,20h
 	jmp	k61
k89b:	sub	al,01h
 	jmp	k61
k89a:	add	al,01h
 	jmp	k61



;	Временный обработчик прерываний стыка С2
;
;
dummm_return:	push	ax
 	 	mov	al,20h
 	 	out	20h,al
 	 	pop	ax
 	 	iret
read_lpen1:	pop	bp
 	 	 	jmp	read_lpen


;**************************************
;
;   Знакогенератор графический 320х200 и 640х200
;
;***************************************

 	org	0fa6eh


crt_char_gen  label  byte
 	db	000h,000h,000h,000h,000h,000h,000h,000h ;d_00
 	db	07eh,081h,0a5h,081h,0bdh,099h,081h,07eh ;d_01
 	db	07eh,0ffh,0dbh,0ffh,0c3h,0e7h,0ffh,07eh ;d_02
 	db	06ch,0feh,0feh,0feh,07ch,038h,010h,000h ;d_03
 	db	010h,038h,07ch,0feh,07ch,038h,010h,008h ;d_04
 	db	038h,07ch,038h,0feh,0feh,07ch,038h,07ch ;d_05
 	db	010h,010h,038h,07ch,0feh,07ch,038h,07ch ;d_06
 	db	000h,000h,018h,03ch,03ch,018h,000h,000h ;d_07
 	db	0ffh,0ffh,0e7h,0c3h,0c3h,0e7h,0ffh,0ffh ;d_08
 	db	000h,03ch,066h,042h,042h,066h,03ch,000h ;d_09
 	db	0ffh,0c3h,099h,0bdh,0bdh,099h,0c3h,0ffh ;d_0a
 	db	00fh,007h,00fh,07dh,0cch,0cch,0cch,078h ;d_0b
 	db	03ch,066h,066h,066h,03ch,018h,07eh,018h ;d_0c
 	db	03fh,033h,03fh,030h,030h,070h,0f0h,0e0h ;d_0d
 	db	07fh,063h,07fh,063h,063h,067h,0e6h,0c0h ;d_0e
 	db	099h,05ah,03ch,0e7h,0e7h,03ch,05ah,099h ;d_0f

 	db	080h,0e0h,0f8h,0feh,0f8h,0e0h,080h,000h ;d_10
 	db	002h,00eh,03eh,0feh,03eh,00eh,002h,000h ;d_11
 	db	018h,03ch,07eh,018h,018h,07eh,03ch,018h ;d_12
 	db	066h,066h,066h,066h,066h,000h,066h,000h ;d_13
 	db	07fh,0dbh,0dbh,07bh,01bh,01bh,01bh,000h ;d_14
 	db	03eh,063h,038h,06ch,06ch,038h,0cch,078h ;d_15
 	db	000h,000h,000h,000h,07eh,07eh,07eh,000h ;d_16
 	db	018h,03ch,07eh,018h,07eh,03ch,018h,0ffh ;d_17
 	db	018h,03ch,07eh,018h,018h,018h,018h,000h ;d_18
 	db	018h,018h,018h,018h,07eh,03ch,018h,000h ;d_19
 	db	000h,018h,00ch,0feh,00ch,018h,000h,000h ;d_1a
 	db	000h,030h,060h,0feh,060h,030h,000h,000h ;d_1b
 	db	000h,000h,0c0h,0c0h,0c0h,0feh,000h,000h ;d_1c
 	db	000h,024h,066h,0ffh,066h,024h,000h,000h ;d_1d
 	db	000h,018h,03ch,07eh,0ffh,0ffh,000h,000h ;d_1e
 	db	000h,0ffh,0ffh,07eh,03ch,018h,000h,000h ;d_1f

 	db	000h,000h,000h,000h,000h,000h,000h,000h ;sp d_20
 	db	030h,078h,078h,030h,030h,000h,030h,000h ;! d_21
 	db	06ch,06ch,06ch,000h,000h,000h,000h,000h ;"d_22
 	db	06ch,06ch,0feh,06ch,0feh,06ch,06ch,000h ;# d_23
 	db	030h,07ch,0c0h,078h,00ch,0f8h,030h,000h ;$ d_24
 	db	000h,0c6h,0cch,018h,030h,066h,0c6h,000h ;per cent d_25
 	db	038h,06ch,038h,076h,0dch,0cch,076h,000h ;& d_26
 	db	060h,060h,0c0h,000h,000h,000h,000h,000h ;' d_27
 	db	018h,030h,060h,060h,060h,030h,018h,000h ;( d_28
 	db	060h,030h,018h,018h,018h,030h,060h,000h ;) d_29
 	db	000h,066h,03ch,0ffh,03ch,066h,000h,000h ;* d_2a
 	db	000h,030h,030h,0fch,030h,030h,000h,000h ;+ d_2b
 	db	000h,000h,000h,000h,000h,030h,030h,060h ;, d_2c
 	db	000h,000h,000h,0fch,000h,000h,000h,000h ;- d_2d
 	db	000h,000h,000h,000h,000h,030h,030h,000h ;. d_2e
 	db	006h,00ch,018h,030h,060h,0c0h,080h,000h ;/ d_2f

 	db	07ch,0c6h,0ceh,0deh,0f6h,0e6h,07ch,000h ;0 d_30
 	db	030h,070h,030h,030h,030h,030h,0fch,000h ;1 d_31
 	db	078h,0cch,00ch,038h,060h,0cch,0fch,000h ;2 d_32
 	db	078h,0cch,00ch,038h,00ch,0cch,078h,000h ;3 d_33
 	db	01ch,03ch,06ch,0cch,0feh,00ch,01eh,000h ;4 d_34
 	db	0fch,0c0h,0f8h,00ch,00ch,0cch,078h,000h ;5 d_35
 	db	038h,060h,0c0h,0f8h,0cch,0cch,078h,000h ;6 d_36
 	db	0fch,0cch,00ch,018h,030h,030h,030h,000h ;7 d_37
 	db	078h,0cch,0cch,078h,0cch,0cch,078h,000h ;8 d_38
 	db	078h,0cch,0cch,07ch,00ch,018h,070h,000h ;9 d_39
 	db	000h,030h,030h,000h,000h,030h,030h,000h ;: d_3a
 	db	000h,030h,030h,000h,000h,030h,030h,060h ;; d_3b
 	db	018h,030h,060h,0c0h,060h,030h,018h,000h ;< d_3c
 	db	000h,000h,0fch,000h,000h,0fch,000h,000h ;= d_3d
 	db	060h,030h,018h,00ch,018h,030h,060h,000h ;> d_3e
 	db	078h,0cch,00ch,018h,030h,000h,030h,000h ;? d_3f

 	db	07ch,0c6h,0deh,0deh,0deh,0c0h,078h,000h ;@ d_40
 	db	030h,078h,0cch,0cch,0fch,0cch,0cch,000h ;A d_41
 	db	0fch,066h,066h,07ch,066h,066h,0fch,000h ;B d_42
 	db	03ch,066h,0c0h,0c0h,0c0h,066h,03ch,000h ;C d_43
 	db	0f8h,06ch,066h,066h,066h,06ch,0f8h,000h ;D d_44
 	db	0feh,062h,068h,078h,068h,062h,0feh,000h ;E d_45
 	db	0feh,062h,068h,078h,068h,060h,0f0h,000h ;F d_46
 	db	03ch,066h,0c0h,0c0h,0ceh,066h,03eh,000h ;G d_47
 	db	0cch,0cch,0cch,0fch,0cch,0cch,0cch,000h ;H d_48
 	db	078h,030h,030h,030h,030h,030h,078h,000h ;I d_49
 	db	01eh,00ch,00ch,00ch,0cch,0cch,078h,000h ;J d_4a
 	db	0e6h,066h,06ch,078h,06ch,066h,0e6h,000h ;K d_4b
 	db	0f0h,060h,060h,060h,062h,066h,0feh,000h ;L d_4c
 	db	0c6h,0eeh,0feh,0feh,0d6h,0c6h,0c6h,000h ;M d_4d
 	db	0c6h,0e6h,0f6h,0deh,0ceh,0c6h,0c6h,000h ;N d_4e
 	db	038h,06ch,0c6h,0c6h,0c6h,06ch,038h,000h ;O d_4f

 	db	0fch,066h,066h,07ch,060h,060h,0f0h,000h ;P d_50
 	db	078h,0cch,0cch,0cch,0dch,078h,01ch,000h ;Q d_51
 	db	0fch,066h,066h,07ch,06ch,066h,0e6h,000h ;R d_52
 	db	078h,0cch,0e0h,070h,01ch,0cch,078h,000h ;S d_53
 	db	0fch,0b4h,030h,030h,030h,030h,078h,000h ;T d_54
 	db	0cch,0cch,0cch,0cch,0cch,0cch,0fch,000h ;U d_55
 	db	0cch,0cch,0cch,0cch,0cch,078h,030h,000h ;V d_56
 	db	0c6h,0c6h,0c6h,0d6h,0feh,0eeh,0c6h,000h ;W d_57
 	db	0c6h,0c6h,06ch,038h,038h,06ch,0c6h,000h ;X d_58
 	db	0cch,0cch,0cch,078h,030h,030h,078h,000h ;Y d_59
 	db	0feh,0c6h,08ch,018h,032h,066h,0feh,000h ;Z d_5a
 	db	078h,060h,060h,060h,060h,060h,078h,000h ;( d_5b
 	db	0c0h,060h,030h,018h,00ch,006h,002h,000h ;backslash
 	db	078h,018h,018h,018h,018h,018h,078h,000h ;) d_5d
 	db	010h,038h,06ch,0c6h,000h,000h,000h,000h ;cimpqumflex
 	db	000h,000h,000h,000h,000h,000h,000h,0ffh ;_ d_5f

 	db	030h,030h,018h,000h,000h,000h,000h,000h ;  d_60
 	db	000h,000h,078h,00ch,07ch,0cch,076h,000h ;lower case a
 	db	0e0h,060h,060h,07ch,066h,066h,0dch,000h ;b d_62
 	db	000h,000h,078h,0cch,0c0h,0cch,078h,000h ;c d_63
 	db	01ch,00ch,00ch,07ch,0cch,0cch,076h,000h ;d d_64
 	db	000h,000h,078h,0cch,0fch,0c0h,078h,000h ;e d_65
 	db	038h,06ch,060h,0f0h,060h,060h,0f0h,000h ;f d_66
 	db	000h,000h,076h,0cch,0cch,07ch,00ch,0f8h ;g d_67
 	db	0e0h,060h,06ch,076h,066h,066h,0e6h,000h ;h d_68
 	db	030h,000h,070h,030h,030h,030h,078h,000h ;i d_69
 	db	00ch,000h,00ch,00ch,00ch,0cch,0cch,078h ;j d_6a
 	db	0e0h,060h,066h,06ch,078h,06ch,0e6h,000h ;k d_6b
 	db	070h,030h,030h,030h,030h,030h,078h,000h ;l d_6c
 	db	000h,000h,0cch,0feh,0feh,0d6h,0c6h,000h ;m d_6d
 	db	000h,000h,0f8h,0cch,0cch,0cch,0cch,000h ;n d_6e
 	db	000h,000h,078h,0cch,0cch,0cch,078h,000h ;o d_6f

 	db	000h,000h,0dch,066h,066h,07ch,060h,0f0h ;p d_70
 	db	000h,000h,076h,0cch,0cch,07ch,00ch,01eh ;q d_71
 	db	000h,000h,0dch,076h,066h,060h,0f0h,000h ;r d_72
 	db	000h,000h,07ch,0c0h,078h,00ch,0f8h,000h ;s d_73
 	db	010h,030h,07ch,030h,030h,034h,018h,000h ;t d_74
 	db	000h,000h,0cch,0cch,0cch,0cch,076h,000h ;u d_75
 	db	000h,000h,0cch,0cch,0cch,078h,030h,000h ;v d_76
 	db	000h,000h,0c6h,0d6h,0feh,0feh,06ch,000h ;w d_77
 	db	000h,000h,0c6h,06ch,038h,06ch,0c6h,000h ;x d_78
 	db	000h,000h,0cch,0cch,0cch,07ch,00ch,0f8h ;y d_79
 	db	000h,000h,0fch,098h,030h,064h,0fch,000h ;z d_7a
 	db	01ch,030h,030h,0e0h,030h,030h,01ch,000h ;  d_7b
 	db	018h,018h,018h,000h,018h,018h,018h,000h ;  d_7c
 	db	0e0h,030h,030h,01ch,030h,030h,0e0h,000h ;  d_7d
 	db	076h,0dch,000h,000h,000h,000h,000h,000h ;  d_7e
 	db	000h,010h,038h,06ch,0c6h,0c6h,0feh,000h ;delta d_7f

;---int 1a-------------------------------
;
;   Программа установки-считывания времени суток
;
;   Эта программа обеспечивает выполнение двух функций, код которых
; задается в регистре AH:
;   AH=0 - считать текущее состояние часов. После выполнения коман-
; ды регистры CX и DX содержат старшую и младшую части счетчика.
;   Если регистр AL содержит "0", то счет идет в течение одних
; суток, при любом другом значении счет переходит на следующие
; сутки;
;
;   AH=1 - записать текущее состояние часов. Регистры CX и DX
; содержат старшую и младшую части счетчика.
;
;------------------------------------------
 	assume	cs:code,ds:data
time_of_day	proc	far
 	sti	 	; уст признак разрешения прерывания
 	push	ds	; сохранить сегмент
 	push	ax	; сохранить параметры
 	mov	ax,dat
 	mov	ds,ax
 	pop	ax
 	or	ah,ah	; AH=0 ?
 	jz	t2  ; да, переход к считыванию текущего состояния
 	dec	ah	; AH=1 ?
 	jz	t3  ; да, переход к установке текущего состояния

t1:	; Возврат из программы

 	sti	 	; уст признак разрешения прерывания
 	pop	ds	; возврат сегмента
 	iret	 	; возврат к программе,вызвавшей процедуру

t2:	; Считать текущее состояния часов

 	cli	 	; сбросить признак разрешения прерывания
 	mov	al,timer_ofl  ; считать в AL флажок перехода на сле-
 	mov	timer_ofl,0   ; дующие сутки и сбросить его в памяти
 	mov	cx,timer_high	 	; установить старшую и младшую
 	mov	dx,timer_low	 	; части счетчика
 	jmp	short t1

t3:	; Установить текущее состояние часов

 	cli	 	; сброс признака разрешения прерывания
 	mov	timer_low,dx	 	; установить младшую и старшую
 	mov	timer_high,cx	 	; части счетчика
 	mov	timer_ofl,0	; сброс флажка перехода через сутки
 	jmp	short t1	; возврат из программы отсчета времени
time_of_day	endp

;-------int 08-------------------
;
;   Программа обработки прерывания таймера КР580ВИ53 (INT 8H) об-
; рабатывает прерывания, аппаратурно возникающие от нулевого канала
; таймера, на вход которого подаются сигналы с частотой 1,228 МГц,
; делящиеся на 56263 для обеспечения 18,2 прерываний в секунду.
;   При обработке прерывания корректируется программный счетчик,
; хранящийся в памяти по адресу 0046CH (младшая часть счетчика) и
; адресу 0047EH (старшая часть счетчика) и используемый для уста-
; новки времени суток.
;   В функции программы входит коррекция счетчика, управляющего
; двигателем НГМД. После обнуления счетчика двигатель выключается.
;   Вектор 1CH дает возможность пользователю входить в заданную
; программу с частотой прерывания таймера (18.2 прерываний в секун-
; ду). Для этого в таблице векторов прерываний по адресу 007CH
; необходимо задать адрес пользовательской программы.
;
;---------------------------------------------------

timer_int	proc	far
 	sti	 	; уст признак разрешения прерывания
 	push	ds
 	push	ax
 	push	dx
 	mov	ax,dat
 	mov	ds,ax
 	inc	timer_low    ; +1 к старшей части счетчика
 	jnz	t4
 	inc	timer_high   ; +1 к старшей части счетчика

t4:	; Опрос счетчика = 24 часам

 	cmp	timer_high,018h
 	jnz	t5
 	cmp	timer_low,0b0h
 	jnz	t5

;   Таймер исчерпал 24 часа

 	mov	timer_high,0   ; сброс старшей и младшей частей
 	mov	timer_low,0    ; счетчика и установка флажка пере-
 	mov	timer_ofl,1    ; хода счета на следующие сутки

;   Выключение мотора НГМД, если счетчик управления мотором
; исчерпан

t5:
 	dec	motor_count
 	jnz	t6	 	; переход, если счетчик не установлен
 	and	motor_status,0f0h
 	mov	al,0ch
 	mov	dx,03f2h
 	out	dx,al	 	; выключить мотор

t6:
 	int	1ch	; передача управления программе пользователя
 	mov	al,eoi
 	out	020h,al        ; конец прерывания
 	pop	dx
 	pop	ax
 	pop	ds
 	iret	 	 	; возврат из прерывания
timer_int	endp
;---------------------------------
;
;   Эти вектора передаются в область прерывания 8086 во время
; включения питания.
;
;---------------------------------
vector_table	label	word	; таблица векторов прерываний

 	dw	offset timer_int	; прерывание 8
 	dw	cod

 	dw	offset kb_int	 	; прерывание 9
 	dw	cod

 	dw	offset dummy_return	; прерывание А
 	dw	cod
 	dw	offset dummm_return	; прерывание B
 	dw	cod
 	dw	offset dummm_return	; прерывание C
 	dw	cod
 	dw	offset dummy_return	; прерывание D
 	dw	cod
 	dw	offset disk_int 	; прерывание E
 	dw	cod

 	dw	offset dummy_return	; прерывание F
 	dw	cod
 	dw	offset video_io 	; прерывание 10H
 	dw	cod

 	dw	offset equipment	; прерывание 11H
 	dw	cod

 	dw	offset memory_size_determine	; прерывание 12H
 	dw	cod

 	dw	offset diskette_io	; прерывание 13H
 	dw	cod

 	dw	offset rs232_io 	; прерывание  14H
 	dw	cod

 	dw	offset ex_memory	; int 15h
 	dw	cod

 	dw	offset keyboard_io	; прерывание 16H
 	dw	cod

 	dw	offset printer_io	; прерывание 17H
 	dw	cod

 	dw	offset start	 	; прерывание 18H
 	dw	cod	 	 	; RESTART

 	dw	offset boot_strapt	; прерывание 19H
 	dw	cod

 	dw	time_of_day	; прерывание 1АH - время суток
 	dw	cod

 	dw	dummy_return	; прерывание 1BH - прерывание клавиатуры
 	dw	cod

 	dw	dummy_return	; прерывание 1C - прерывание таймера
 	dw	cod

 	dw	video_parms	; прерывание 1D - параметры видео
 	dw	cod

 	dw	offset	disk_base   ;прерывание 1EH - параметры НГМД
 	dw	cod

 	dw	offset crt_char_rus	; 1FH - адрес таблицы пользова-
 	dw	cod	       ; тельского дополнительного знакогенератора

dummy_return:
 	iret

;---int 5----------------------
;
;   Программа вывода на печать содержимого буфера ЭЛИ вызывается
; одновременным нажатием клавиши ПЕЧ и клавиши переключения регист-
; ров. Позиция курсора сохраняется до завершения процедуры обработки
; прерывания. Повторное нажатие названных клавиш во время обработки
; прерывания игнорируется.
;   При выполнении программы в постоянно распределенной рабочей
; области памяти по адресу 0500H устанавливается следующая
; информация:
;   0	 - содержимое буфера ЭЛИ еще не выведено на печать, либо
; вывод уже завершен;
;   1	 - в процессе вывода содержимого буфера ЭЛИ на печать;
;   255  - при печати обнаружена ошибка.
;-----------------------------------------------------

 	assume	cs:code,ds:xxdata

print_screen	proc	far
 	sti	 	     ; уст признак разрешения прерывания
 	push	ds
 	push	ax
 	push	bx
 	push	cx   ; будет использоваться заглавная буква для курсора
 	push	dx   ; будет содержать текущее положение курсора
 	mov	ax,xxdat	; адрес 50
 	mov	ds,ax
 	cmp	status_byte,1	; печать готова ?
 	jz	exit	 	; переход, если печать готова
 	mov	status_byte,1	;
 	mov	ah,15	 	; требуется текущий режим экрана
 	int	10h	 	; AL - режим, AH - число строк/колонок
 	 	 	 	; BH - страница,выведенная на экран


;*************************************8
;
;   В этом месте:
;	 	    AX - колонка, строка,
;	 	    BH - номер отображаемой страницы.
;
;   Стек содержит DS, AX, BX, CX, DX.
;
;	 	    AL - режим
;
;**************************************

 	mov	cl,ah
 	mov	ch,25
 	call	crlf
 	push	cx
 	mov	ah,3
 	int	10h
 	pop	cx
 	push	dx
 	xor	dx,dx

;**************************************
;
;    Считывание знака, находящегося в текущей позиции курсора
; и вывод на печать
;
;**************************************

pri10:	mov	ah,2
 	int	10h
 	mov	ah,8
 	int	10h
 	or	al,al
 	jnz	pri15
 	mov	al,' '
pri15:
 	push	dx
 	xor	dx,dx
 	xor	ah,ah
 	int	17h
 	pop	dx
 	test	ah,25h
 	jnz	err10
 	inc	dl
 	cmp	cl,dl
 	jnz	pri10
 	xor	dl,dl
 	mov	ah,dl
 	push	dx
 	call	crlf
 	pop	dx
 	inc	dh
 	cmp	ch,dh
 	jnz	pri10
pri20:	pop	dx
 	mov	ah,2
 	int	10h
 	mov	status_byte,0
 	jmp	short exit
err10:	pop	dx
 	mov	ah,2
 	int	10h
err20:	mov	status_byte,0ffh

exit:	pop	dx
 	pop	cx
 	pop	bx
 	pop	ax
 	pop	ds
 	iret
print_screen	endp

;   Возврат каретки

crlf	proc	near
 	xor	dx,dx
 	xor	ah,ah
 	mov	al,12q
 	int	17h
 	xor	ah,ah
 	mov	al,15q
 	int	17h
 	ret
crlf	endp
 	org	0ffe0h
 	db	'ЕС1841.(РЕД.02)'


 	org	0fff0h
;--------------------------------------
;
;   Включение питания
;
;--------------------------------------

;vector segment at 0ffffh

;   Переход по включению питания

 	db	0eah,5bh,0e0h,00h,0f0h	;    jmp reset

 	db	'12/01/86'
 	db	0ffh,0feh
;vector ends






code	ends
 	end

