.686
.model flat

extern round_unsigned_float_to_int: proc
extern _putchar: proc

extern _Sleep@4: proc						; to draw_all with small delay between putchar()
extern _GetStdHandle@4: proc				; STD_OUTPUT_HANDLE = (DWORD)-11
extern _SetConsoleCursorPosition@8: proc
extern _SetConsoleTextAttribute@8: proc		; not sure how to use it, but seems to work
extern _malloc: proc
.data

;	board_width			db		16
;	board_height		db		24
;	tiles_max_height	db		16
;	board_tiles			db		32 dup (0ah)	; 32 bytes, because board_width*tiles_max_height = 8*32 tiles
											; each bit represents one point in the board. 0 => empty, 1 => there is a tile

; in memory, (qword)board will look like this:
; [index]   = [ (byte)width, (byte)height, (byte)max_height, (byte)level_number ]
; [index+4] = [ (dword)offset board_tiles ]
; [index+8] = [ (byte)tile_char, (byte)tile_color, (byte)background_color, (byte)tile_count ]
; [index+12]= [ (byte)border_char, (byte)border_color, (byte)????, (byte)???? ]

;ball_color			dw		008fh
;platform_color		dw		00f0h
;border_color		dw		0007h
;tile_color			dw		0070h
;background_color	dw		0080h
		; FOREGROUND_BLUE      0x0001 // text color contains blue.			 black		=	0	darkgray	 =	8	
		; FOREGROUND_GREEN     0x0002 // text color contains green.			 blue		=	1	lightblue	 =	9
		; FOREGROUND_RED       0x0004 // text color contains red.			 green		=	2	lightgreen	 =	A
		; FOREGROUND_INTENSITY 0x0008 // text color is intensified.			 cyan		=	3	lightcyan	 =	B
		; BACKGROUND_BLUE      0x0010 // background color contains blue.	 red		=	4	lightred	 =	C
		; BACKGROUND_GREEN     0x0020 // background color contains green.	 magenta	=	5	lightmagenta =	D
		; BACKGROUND_RED       0x0040 // background color contains red.		 brown		=	6	yellow		 =	E
		; BACKGROUND_INTENSITY 0x0080 // background color is intensified.	 lightgray	=	7	white		 =	F
.code

board_init proc
		push		ebp
		mov			ebp, esp
		push		ebx

		push		16
		call		_malloc
		add			esp, 4

		mov			ebx, [ebp+8]				; ebx = offset board_ptr
		mov			[ebx], eax					; board_ptr = new allocated memory
		mov			byte ptr [eax], 16		; width
		mov			byte ptr [eax+1], 24	; height
		mov			byte ptr [eax+2], 16	; tiles max height
		mov			byte ptr [eax+3], 1		; level_number

		mov			ebx, eax				; ebx = new allocated memory

		push		32
		call		_malloc
		add			esp, 4
		mov			[ebx+4], eax			; [ebx+4] = board_tiles[]

		pop			ebx
		pop			ebp
		ret
board_init endp

is_there_a_tile proc
		push		ebp
		mov			ebp, esp
		;[ebp+8] = int x
		;[ebp+12] = int y
		;[ebp+16] = board_ptr
		push		ebx
		push		edx
		push		esi
		push		edi

		cmp			byte ptr [ebp+12], 16
		ja			ball_below_tiles

		mov			esi, [ebp+8]
		mov			eax, [ebp+12]
		mov			ebx, [ebp+16]
		mov			ebx, [ebx+4]

		dec			esi			; decrement x coordinate, because left point is at x=1, not 0
		dec			eax			; the same for y
		mov			edx, 0
		mov			ecx, 2
		mul			ecx			; multiply y by 2, because one line is two bytes, if y=1, then skip 2 first bytes

		add			ebx, eax

		btr			[ebx], esi		; tile breaks
		jc			there_is_a_tile
ball_below_tiles:
		mov			eax, 0
		jmp			end_proc
there_is_a_tile:
		sub			esp, 8

		push		0FFFFFFF5h			; STD_OUTPUT_HANDLE = (DWORD)-11
		call		_GetStdHandle@4
		mov			esi, eax			; esi = handle
		
		mov			bx, [ebp+8]		; ball_x
		mov			[esp], bx
		mov			bx, [ebp+12]	; ball_y
		mov			[esp+2], bx

		push		[esp]
		push		esi
		call		_SetConsoleCursorPosition@8

		mov			eax, [ebp+16]
		movzx		eax, byte ptr [eax+10]		; background color
		push		eax
		push		esi					;handle
		call		_SetConsoleTextAttribute@8
		push		dword ptr ' '
		call		_putchar
		add			esp, 12			; also add 8 bytes from tmp value
		
		mov			eax, 1
		
		mov			ebx, [ebp+16]			; decrease count_tiles
		mov			cl, [ebx+11]
		dec			cl
		mov			[ebx+11], cl
		cmp			cl, 0
		jne			end_proc
		mov			eax, -1
end_proc:
		pop			edi
		pop			esi
		pop			edx
		pop			ebx
		pop			ebp
		ret
is_there_a_tile endp


erase_ball proc
		;	[ebp+8] = ball_ptr
		;	[ebp+12] = board_ptr
		push		ebp
		mov			ebp, esp
		
		sub			esp, 8					; [ebp-8] = COORD
		sub			esp, 4					; [ebp-12] = HANDLE
		push		ebx
		push		esi
		push		edi

		push		0FFFFFFF5h			; STD_OUTPUT_HANDLE = (DWORD)-11
		call		_GetStdHandle@4
		mov			[ebp-12], eax

		mov			esi, [ebp+8]
		mov			edi, [ebp+12]

		movzx		bx, byte ptr [esi+16]	 ; ball_x
		mov			[ebp-8], bx
		movzx		bx, byte ptr [esi+17]	; ball_y
		mov			[ebp-6], bx

		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		movzx		eax, byte ptr [edi+10]		; background color
		push		eax
		push		[ebp-12]					;handle
		call		_SetConsoleTextAttribute@8
		push		dword ptr ' '
		call		_putchar
		add			esp, 4

		pop			edi
		pop			esi
		pop			ebx
		add			esp, 12
		pop			ebp
		ret
erase_ball endp


draw_ball proc
		;	[ebp+8] = ball_ptr
		;	[ebp+12] = board_ptr
		push		ebp
		mov			ebp, esp
		push		ebx
		push		esi
		push		edi
		
		sub			esp, 8					; [ebp-8] = COORD
		sub			esp, 4					; [ebp-12] = HANDLE

		push		0FFFFFFF5h			; STD_OUTPUT_HANDLE = (DWORD)-11
		call		_GetStdHandle@4
		mov			[ebp-12], eax

		mov			esi, [ebp+8]
		mov			edi, [ebp+12]

		
		movzx		bx, byte ptr [esi+16]	 ; ball_x
		mov			[ebp-8], bx
		movzx		bx, byte ptr [esi+17]	; ball_y
		mov			[ebp-6], bx

		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		movzx		eax, byte ptr [esi+21]		; ball color
		push		eax
		push		[ebp-12]					;handle
		call		_SetConsoleTextAttribute@8
		movzx		eax, byte ptr [esi+20]		; ball char
		push		eax
		call		_putchar
		add			esp, 4

		pop			edi
		pop			esi
		pop			ebx
		add			esp, 12
		pop			ebp
		ret
draw_ball endp

redraw_platform proc
		;	[ebp+8] = platform_ptr
		;	[ebp+12] = board_ptr
		push		ebp
		mov			ebp, esp
		
		sub			esp, 8					; [ebp-8] = COORD
		sub			esp, 4					; [ebp-12] = HANDLE

		push		ebx
		push		edx
		push		esi
		push		edi

		mov			eax, [ebp+12]			; board_ptr
		movzx		ax, byte ptr [eax+1]	; board height
		mov			[ebp-6], ax				; COORD.Y = board height

		push		0FFFFFFF5h			; STD_OUTPUT_HANDLE = (DWORD)-11
		call		_GetStdHandle@4
		mov			[ebp-12], eax
		
		mov			edi, [ebp+8]				; edi = platform_ptr
		mov			esi, [ebp+12]				; esi = board_ptr
		movzx		ebx, byte ptr [edi+9]		; ebx = (int) old_position
		movzx		eax, byte ptr [edi+8]		; eax = (int) new_position

		movzx		dx, byte ptr [edi+10]		; dx = platform width
		cmp			dx, 0
		jne			platform_has_width

;platform_width=0
		movzx		ax,  byte ptr [edi+9]		; erase old position
		mov			[ebp-8], ax
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		movzx		eax, byte ptr [esi+10]		; background color
		push		eax
		push		[ebp-12]					;handle
		call		_SetConsoleTextAttribute@8
		push		dword ptr ' '
		call		_putchar
		add			esp, 4
		
		movzx		ax, byte ptr [edi+8]				; puthchar in new position
		mov			[ebp-8], ax
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		movzx		eax, byte ptr [edi+15]				; platform color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		movzx		eax, byte ptr [edi+13]
		push		eax
		call		_putchar
		add			esp, 4
		jmp			end_proc

platform_has_width:
		cmp			eax, ebx
		ja			platform_was_moved_to_right
;platform_was_moved_to_left:
		movzx		bx, byte ptr [edi+8]
		sub			bx, dx					; bx = left side of position where platform moved
		mov			[ebp-8], bx
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		movzx		eax, byte ptr [edi+15]		; platform color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		movzx		eax, byte ptr [edi+12]		; left char
		push		eax
		call		_putchar
		add			esp, 4
		movzx		eax, byte ptr [edi+13]		; middle char
		push		eax
		call		_putchar
		add			esp, 4
		
		movzx		dx, byte ptr [edi+10]		; dx = platform width
		movzx		bx, byte ptr [edi+8]
		add			bx, dx					; bx = right side of position where platform moved
		mov			[ebp-8], bx
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		movzx		eax, byte ptr [edi+14]		; right char
		push		eax
		call		_putchar
		add			esp, 4
		movzx		eax, byte ptr [esi+10]		; background color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		push		dword ptr ' '				; erase
		call		_putchar
		add			esp, 4
		jmp			end_proc

platform_was_moved_to_right:
		movzx		bx, byte ptr [edi+9]
		sub			bx, dx					; bx = left side of position where platform was before
		mov			[ebp-8], bx
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		movzx		eax, byte ptr [esi+10]		; background color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		push		dword ptr ' '				; erase
		call		_putchar
		add			esp, 4
		movzx		eax, byte ptr [edi+15]		; platform color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		movzx		eax, byte ptr [edi+12]		; left char
		push		eax
		call		_putchar
		add			esp, 4
		
		movzx		dx, byte ptr [edi+10]		; dx = platform width
		movzx		bx, byte ptr [edi+9]
		add			bx, dx					; bx = right side of position where platform moved
		mov			[ebp-8], bx
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8
		
		movzx		eax, byte ptr [edi+13]		; middle char
		push		eax
		call		_putchar
		add			esp, 4
		movzx		eax, byte ptr [edi+14]		; right char
		push		eax
		call		_putchar
		add			esp, 4
		jmp			end_proc
end_proc:
		pop			edi
		pop			esi
		pop			edx
		pop			ebx
		add			esp, 12
		pop			ebp
		ret
redraw_platform endp

draw_all proc
		; [ebp+8]  = board_ptr
		; [ebp+12] = platform_ptr
		; [ebp+16] = ball_ptr
		push		ebp
		mov			ebp, esp

		sub			esp, 8			; [ebp-8] = COORD
		sub			esp, 4			; [ebp-12] = HANDLE

		push		ebx
		push		edx
		push		edi
		push		esi

		push		0FFFFFFF5h			; STD_OUTPUT_HANDLE = (DWORD)-11
		call		_GetStdHandle@4
		mov			[ebp-12], eax

		mov			ax, 0			; COORD = [(word)x, (word)y]:[(dword)margin?]
		mov			[ebp-8], ax
		mov			[ebp-6], ax

		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		mov			esi, [ebp+8]
		movzx		eax, byte ptr [esi+13]		; border color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8

		mov			bl, [esi]				; top border has size = board_width+2
		add			bl, 2
drawing_top_border:
		movzx		edx, byte ptr [esi+12]		;border char
		push		edx
		call		_putchar
		add			esp, 4
		push		5
		call		_Sleep@4
		dec			bl
		cmp			bl, 0
		jne			drawing_top_border

		mov			bh, [esi+2]					; drawing 'tiles_max_height' lines
		mov			esi, [esi+4]				; index for board_tiles byte
		mov			edi, 0						; index for board_tiles bytes bit
drawing_board_tiles:
		mov			ax, [ebp-6]
		inc			ax
		mov			word ptr [ebp-6], ax		; set cursor position to next line
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8
	; drawing a char of left border
		mov			edx, [ebp+8]				; edx = border_ptr
		movzx		eax, byte ptr [edx+13]		; border color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		mov			edx, [ebp+8]
		movzx		eax, byte ptr [edx+12]		; border char
		push		eax		
		call		_putchar
		add			esp, 4
		push		5
		call		_Sleep@4

		mov			edx, [ebp+8]
		mov			bl, [edx]					; drawing 'border_width' characters as a line
drawing_line:
		bt			[esi], edi
		mov			edx, [ebp+8]				; board ptr
		jc			draw_tile
;draw space:
		movzx		eax, byte ptr [edx+10]			; background color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		push		dword ptr ' '
		call		_putchar
		add			esp, 4
		jmp			drawing_line_loop_tail
draw_tile:
		movzx		eax, byte ptr [edx+9]			; tile color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		mov			edx, [ebp+8]
		movzx		eax, byte ptr [edx+8]			; tile char
		push		eax
		call		_putchar
		add			esp, 4
drawing_line_loop_tail:
		push		5
		call		_Sleep@4
		inc			edi
		cmp			edi, 8
		jne			dont_switch_to_next_byte
		mov			edi, 0
		inc			esi
dont_switch_to_next_byte:
		dec			bl	
		cmp			bl, 0
		jne			drawing_line
										; after 16 characters, right border
		mov			edx, [ebp+8]
		movzx		eax, byte ptr [edx+13]			; border color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		mov			edx, [ebp+8]
		movzx		eax, byte ptr [edx+12]			; border char
		push		eax
		call		_putchar
		add			esp, 4
		push		5
		call		_Sleep@4

		dec			bh
		cmp			bh, 0
		jne			drawing_board_tiles
										; drew 16 lines of board_tiles
		mov			bh, 8				; 8 more lines of empty space between platform and tiles
		mov			edx, [ebp+8]
		movzx		esi, byte ptr [edx+10]		; background_color
		movzx		edi, byte ptr [edx+13]		; border_color
drawing_bottom_lines:
		mov			ax, [ebp-6]
		inc			ax
		mov			word ptr [ebp-6], ax		; set cursor position to next line
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		push		edi					; border color
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		mov			edx, [ebp+8]
		movzx		eax, byte ptr [edx+12]
		push		eax					; border char
		call		_putchar
		add			esp, 4
		push		5
		call		_Sleep@4
		mov			bl, 16			; 16 characters for line

		push		esi
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
drawing_a_bottom_line:
		push		dword ptr ' '
		call		_putchar
		add			esp, 4
		push		5
		call		_Sleep@4
		dec			bl
		cmp			bl, 0
		jne			drawing_a_bottom_line

		push		edi					; border color
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		mov			edx, [ebp+8]
		movzx		eax, byte ptr [edx+12]
		push		eax					; border char
		call		_putchar
		add			esp, 4
		push		5
		call		_Sleep@4

		dec			bh
		cmp			bh, 0
		jne			drawing_bottom_lines
								
	; there are ball and paddle left to draw
		
		mov			esi, [ebp+16]		; ball ptr
		movzx		bx, byte ptr [esi+16]		; int ball x
		movzx		ax, byte ptr [esi+17]		; int ball y

		mov			[ebp-8], bx
		mov			[ebp-6], ax						; set COORD X & Y
		
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8
		movzx		eax, byte ptr [esi+21]			; ball color
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8
		movzx		eax, byte ptr [esi+20]			; ball char
		push		eax
		call		_putchar
		add			esp, 4
		push		5
		call		_Sleep@4

		mov			esi, [ebp+12]			; platform ptr
		movzx		ebx, byte ptr [esi+8]			; ebx = (int)platfrom_x
		mov			edi, ebx
		movzx		ecx, byte ptr [esi+10]
		sub			ebx, ecx			; ebx = platfrom_x - platform_width/2, ebx = left border
		add			edi, ecx			; edi = platfrom_x + platform_width/2, edi = right border
		dec			edi						; dec loop length because platform corners are drawn outside loop
		
		mov			word ptr [ebp-8], bx
		mov			word ptr [ebp-6], 24
		
		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8			; cursor is in position of left side of platform

		movzx		eax, byte ptr [esi+15]
		push		eax
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8

		movzx		eax, byte ptr [esi+12]
		push		eax					;platform left char
		call		_putchar
		add			esp, 4
		
		inc			ebx
draw_platform:
		movzx		eax, byte ptr [esi+13]
		push		eax					; platform middle char
		call		_putchar
		add			esp, 4
		inc			ebx
		cmp			ebx, edi
		jbe			draw_platform

		movzx		eax, byte ptr [esi+14]
		push		eax					;platform right char
		call		_putchar
		add			esp, 4

		pop			esi
		pop			edi
		pop			edx
		pop			ebx
		add			esp, 12					; local variables
		pop			ebp
		ret
draw_all endp

end_animation proc
		push		ebp
		mov			ebp, esp
		sub			esp, 12
		push		ebx
		push		esi
		push		edi
		;[ebp+8] = board ptr
		mov			ebx, [ebp+8]
		movzx		esi, byte ptr [ebx]		; esi = width
		movzx		edi, byte ptr [ebx+1]	; edi = height

		inc			esi

		push		0FFFFFFF5h			; STD_OUTPUT_HANDLE = (DWORD)-11
		call		_GetStdHandle@4
		mov			[ebp-12], eax

		push		0
		push		[ebp-12]
		call		_SetConsoleTextAttribute@8

drawing:
		mov			[ebp-8], si
		mov			[ebp-6], di

		push		[ebp-8]
		push		[ebp-12]
		call		_SetConsoleCursorPosition@8

		push		' '
		call		_putchar
		add			esp, 4

		push		5
		call		_Sleep@4

		dec			esi
		cmp			esi, -1
		jne			drawing
		movzx		esi, byte ptr [ebx]
		inc			esi
		dec			edi
		cmp			edi, -1
		jne			drawing

		pop			edi
		pop			esi
		pop			ebx
		add			esp, 12
		pop			ebp
		ret
end_animation endp

		; FOREGROUND_BLUE      0x0001 // text color contains blue.
		; FOREGROUND_GREEN     0x0002 // text color contains green.
		; FOREGROUND_RED       0x0004 // text color contains red.
		; FOREGROUND_INTENSITY 0x0008 // text color is intensified.
		; BACKGROUND_BLUE      0x0010 // background color contains blue.
		; BACKGROUND_GREEN     0x0020 // background color contains green.
		; BACKGROUND_RED       0x0040 // background color contains red.
		; BACKGROUND_INTENSITY 0x0080 // background color is intensified.

		; black =		0	darkgray =		8	
		; blue =		1	lightblue =		9
		; green =		2	lightgreen =	10
		; cyan =		3	lightcyan  =	11
		; red =			4	lightred =		12
		; magenta =		5	lightmagenta =	13
		; brown =		6	yellow =		14
		; lightgray =	7	white =			15

END