.686
.model flat

extern _malloc: proc
extern round_unsigned_float_to_int: proc
extern is_there_a_tile: proc

extern _PlaySoundA@12: proc

.data
fball_x				real4	8.0
fball_y				real4	23.0
iball_x				db		8
iball_y				db		23
ball_direction		real4	0.8			; angle. 0 is right, PI/2 = up, etc
ball_step_size		real4	0.35		; step size between two frames
lose_sound			db		"lose2.wav",0
platform_sound		db		"platform.wav",0
border_sound		db		"border.wav",0
board_sound			db		"board.wav",0

; in memory, (qword)board will look like this:
; [index]    =  [ (real4)ball_x ]
; [index+4]  =  [ (real4)ball_y ]
; [index+8]  =  [ (real4)ball_direction ]
; [index+12]  =  [ (real4)ball_step_size ]
; [index+16]  =  [ (byte)new_int_x, (byte)new_int_y, (byte)old_int_x, (byte)old_int_y ]
; [index+20]  =  [(byte)char, (byte)color, (word)???? ]


.code

ball_init proc
		push		ebp
		mov			ebp, esp
		push		ebx

		push		24
		call		_malloc
		add			esp, 4

		mov			ebx, [ebp+8]				; esi = offset ball_ptr
		mov			[ebx], eax					; ball_ptr = new allocated memory

		pop			ebx
		pop			ebp
		ret
ball_init endp

reset_ball_position proc
		push		ebp
		mov			ebp, esp
		mov			eax, [ebp+8]
		mov			ebx, fball_x
		mov			[eax], ebx	
		mov			ebx, fball_y
		mov			[eax+4], ebx
		mov			ebx, ball_direction
		mov			[eax+8], ebx
		mov			ebx, ball_step_size
		mov			[eax+12], ebx
		mov			bl, iball_x			; new int_x
		mov			[eax+16], bl
		mov			bl, iball_y			; new int_y
		mov			[eax+17], bl		
		mov			bl, iball_x			; old int_x
		mov			[eax+18], bl			
		mov			bl, iball_y			; old int_y
		mov			[eax+19], bl			
		pop			ebp
		ret
reset_ball_position endp

move_ball proc
		push		ebp
		mov			ebp, esp
		sub			esp, 8
		;[ebp-4] = delta_x
		;[ebp-8] = delta_y
		;[ebp+8] = board_ptr
		;[ebp+12] = platform_ptr
		;[ebp+16] = ball_ptr
		push		ebx
		push		edx
		push		esi
		push		edi

		finit
		mov			esi, [ebp+16]	; ball ptr
		mov			edi, [ebp+8]	; board ptr

		mov			ax, [esi+16]
		mov			[esi+18], ax		; change new_x/y to old_x/y

		fld			real4 ptr [esi+8]		; ball_ptr[8] = ball direction (radians)
		fcos
		fmul		real4 ptr [esi+12]		; delta_x = cos(alpha)*ball_step_size
		fadd		real4 ptr [esi]
		fst			real4 ptr [ebp-4]		; [ebp-4] = float new_x

		fld			dword ptr [esi+8]
		fsin
		fmul		dword ptr [esi+12]		; delta_y = sin(alpha)*ball_step_size
		mov			eax, -1
		sub			esp, 4
		mov			[esp], eax
		fimul		dword ptr [esp]
		add			esp, 4					; delta_y *= -1, because here y axis grows backwards
		fadd		real4 ptr [esi+4]
		fst			dword ptr [ebp-8]		; [ebp-8] = float new_y

		mov			ebx, -1					; if ebx remains -1, then ball didn't hit anything

; check for deltaX
		push		[ebp-4]
		call		round_unsigned_float_to_int
		add			esp, 4
		mov			dl, al					; dl remembers int new_x
		cmp			al, [esi+18]
		je			didnt_change_int_x		; if ( int new_x == int old_x )

		movzx		eax, byte ptr [edi]
		sub			esp, 4
		mov			[esp], eax
		fild		dword ptr [esp]
		add			esp, 4
		fld1
		fld			real4 ptr [ebp-4]		; ST(0) = new_x, ST(1) = 1, ST(2) = board_width
		fcomi		ST(0), ST(1)
		ja			didnt_hit_left_wall
		push		esi				; push ball_ptr
		call		bounce_horisontally
		add			esp, 4
		mov			bl, 0				; ball hit left wall, ebx != -1
		push		edx
		push		1						; SND_ASYNC
		push		0						; NULL
		push		offset border_sound	; TEXT(char*)
		call		_PlaySoundA@12
		pop			edx
		jmp			check_for_deltaY
didnt_hit_left_wall:
		fcomi		ST(0), ST(2)
		jb			didnt_hit_right_wall

		push		esi
		call		bounce_horisontally
		add			esp, 4
		mov			bl, 0
		push		edx
		push		1						; SND_ASYNC
		push		0						; NULL
		push		offset border_sound	; TEXT(char*)
		call		_PlaySoundA@12
		pop			edx
		jmp			check_for_deltaY
didnt_hit_right_wall:
		; check if hit a tile
		push		edi				; board_ptr
		movzx		eax, byte ptr [esi+17]	; int old_y
		push		eax
		movzx		eax, dl			; int new_x
		push		eax
		call		is_there_a_tile
		add			esp, 12
		cmp			eax, -1
		je			ball_broke_all_tiles
		cmp			eax, 0
		je			check_for_deltaY
		mov			bl, 0				; ball hit a tile, ebx != -1
		push		esi
		call		bounce_horisontally
		add			esp, 4
		push		edx
		push		1						; SND_ASYNC
		push		0						; NULL
		push		offset board_sound	; TEXT(char*)
		call		_PlaySoundA@12
		pop			edx
		jmp			check_for_deltaY
didnt_change_int_x:
		btc			ebx, 31				; says not to check tile in the corner
check_for_deltaY:
		push		[ebp-8]
		call		round_unsigned_float_to_int
		add			esp, 4
		mov			dh, al					; dh remembers int new_y
		cmp			al, [esi+19]
		je			didnt_change_int_y		; if ( int new_y == int old_y )

		finit
		movzx		eax, byte ptr [edi+1]
		sub			esp, 4
		mov			[esp], eax
		fild		dword ptr [esp]
		fild		dword ptr [esp]
		add			esp, 4
		fld1
		fsub		ST(1), ST(0)
		fld			real4 ptr [ebp-8]		; ST(0) = new_y, ST(1) = 1, ST(2) = board_height-1, ST(3) = board_height
		fcomi		ST(0), ST(1)
		ja			didnt_hit_top_wall

		push		esi
		call		bounce_vertically
		add			esp, 4
		mov			bh, 0				; ball hit left wall, ebx != -1
		push		edx
		push		1						; SND_ASYNC
		push		0						; NULL
		push		offset border_sound	; TEXT(char*)
		call		_PlaySoundA@12
		pop			edx
		jmp			checked_all
didnt_hit_top_wall:
		fcomi		ST(0), ST(3)
		jae			ball_hits_bottom_wall
didnt_hit_bottom_wall:
		fcomi		ST(0), ST(2)
		jb			doesnt_bounce_of_platform
		finit
		fld			real4 ptr [esi+8]			; ball direction
		fldpi
		fcomi		ST(0), ST(1)			; check if direction is between pi and 2pi radians (ball faces bottom)
		ja			doesnt_bounce_of_platform

		fld			real4 ptr [ebp-4]
		mov			eax, [ebp+12]			; platform_ptr
		fld			real4 ptr [eax]				; platform_x
		movzx		ecx, byte ptr [eax+10]	; platform width
		inc			ecx						; increment platform width, if not then it looks like platform has to narrow range
		sub			esp, 4
		mov			[esp], ecx
		fisub		dword ptr [esp]				; ST(0) = platform_x-width, ST(1) = ball_x
		add			esp, 4
		fcomi		ST(0), ST(1)
		ja			doesnt_bounce_of_platform
		sub			esp, 4
		fiadd		dword ptr [esp]
		fiadd		dword ptr [esp]				; ST(0) = platform_x+width
		add			esp, 4
		fcomi		ST(0), ST(1)
		jb			doesnt_bounce_of_platform
		push		esi				;ball_ptr
		push		[ebp+12]		;platform_ptr
		call		bounce_of_platform
		add			esp, 8
		mov			bh, 0
		push		edx
		push		1						; SND_ASYNC
		push		0						; NULL
		push		offset platform_sound	; TEXT(char*)
		call		_PlaySoundA@12
		pop			edx
doesnt_bounce_of_platform:
		; check if hit a tile
		push		edi			; board_ptr
		movzx		eax, dh			; int new_y
		push		eax
		movzx		eax, byte ptr [esi+16]	; int old_x
		push		eax
		call		is_there_a_tile
		add			esp, 12
		cmp			eax, -1
		je			ball_broke_all_tiles
		cmp			eax, 0
		je			check_for_deltaXY
		mov			bh, 0				; ball hit a tile, ebx != -1
		push		esi
		call		bounce_vertically
		add			esp, 4
		push		edx
		push		1						; SND_ASYNC
		push		0						; NULL
		push		offset board_sound		; TEXT(char*)
		call		_PlaySoundA@12
		pop			edx
		jmp			checked_all
didnt_change_int_y:
		jmp			checked_all
check_for_deltaXY:
		cmp			ebx, -1
		jne			checked_all		; if didn't hit anything, check if ball hit a corner of a tile
		; check if hit a tile
		push		edi				; board_ptr
		movzx		eax, dh			; int new_y
		push		eax
		movzx		eax, dl			; int new_x
		push		eax
		call		is_there_a_tile
		add			esp, 12
		cmp			eax, -1
		je			ball_broke_all_tiles
		cmp			eax, 0
		je			checked_all
		mov			ebx, 0				; ball hit a tile, ebx != -1
		push		esi
		call		bounce_horisontally
		add			esp, 4
		push		esi
		call		bounce_vertically
		add			esp, 4
		push		edx
		push		1						; SND_ASYNC
		push		0						; NULL
		push		offset board_sound	; TEXT(char*)
		call		_PlaySoundA@12
		pop			edx
checked_all:
		cmp			bl, 0
		je			dont_change_ball_x
		mov			eax, [ebp-4]
		mov			[esi], eax
		mov			[esi+16], dl
dont_change_ball_x:
		cmp			bh, 0
		je			dont_change_ball_y
		mov			eax, [ebp-8]
		mov			[esi+4], eax
		mov			[esi+17], dh
dont_change_ball_y:
		mov			eax, 0
		jmp			end_proc
ball_hits_bottom_wall:
		push		1						; SND_ASYNC
		push		0						; NULL
		push		offset lose_sound		; TEXT(char*)
		call		_PlaySoundA@12
		mov			eax, 1
		jmp			end_proc
ball_broke_all_tiles:
		mov			eax, 2
end_proc:
		pop			edi
		pop			esi
		pop			edx
		pop			ebx
		add			esp, 8
		pop			ebp
		ret
move_ball endp

bounce_horisontally proc
		push		ebp
		mov			ebp, esp
		;[ebp+8] = ball ptr
		; alpha = (pi/2 - alpha)*2 + alpha
		finit
		fldz
		fld1
		fld1
		faddp			; = fld  2.0
		fldpi
		fdiv		ST(0), ST(1)		; st0 = pi/2
		mov			eax, [ebp+8]
		fsub		real4 ptr [eax+8]
		fmul		ST(0), ST(1)
		fadd		real4 ptr [eax+8]
		fcomi		ST(0), ST(2)			; cmp new_alpha, 0
		ja			update_direction_x
		fldpi
		fmul		ST(0), ST(2)
		faddp				; alpha += 2pi
update_direction_x:
		mov			eax, [ebp+8]
		fst			real4 ptr [eax+8]				; ball_direction = ST(0)
end_proc:
		pop			ebp
		ret
bounce_horisontally endp

bounce_vertically proc
		push		ebp
		mov			ebp, esp
		;[ebp+8] = ball ptr
		; alpha = 2pi - alpha
		finit
		;fldz
		fld1
		fld1
		faddp			; = fld  2.0
		fldpi
		fmul		ST(0), ST(1)		; st0 = 2pi
		mov			eax, [ebp+8]
		fsub		real4 ptr [eax+8]
		fst			real4 ptr [eax+8]				; ball_direction = ST(0)
end_proc:
		pop			ebp
		ret
bounce_vertically endp

bounce_of_platform proc
		; alpha = -pi/(3*width) * (ball_x - platform_x) + pi/2
		push		ebp
		mov			ebp, esp
		;[ebp+8] = platform ptr
		;[ebp+12] = ball ptr
		sub			esp, 4
		mov			eax, [ebp+8]
		movzx		eax, byte ptr [eax+10]	; ball width
		mov			[esp], eax

		finit
		fldz
		fld1
		fld1
		fld1
		fld1
		fsubp		ST(4), ST(0)
		fsubp		ST(3), ST(0)
		fsubp		ST(2), ST(0)
		fsubp				; fld -3.0
		fild		dword ptr [esp]
		fmul
		fldpi
		fdivr

		mov			eax, [ebp+12]
		fld			real4 ptr [eax]
		mov			eax, [ebp+8]
		fld			real4 ptr [eax]
		fsubp					; ST(0) = ball_x - platform_x
		fmulp
		fldpi
		fld1
		fld1
		faddp
		fdivp
		faddp


		mov			eax, [ebp+12]
		fst			real4 ptr [eax+8]

end_proc:
		add			esp, 4
		pop			ebp
		ret
bounce_of_platform endp
END