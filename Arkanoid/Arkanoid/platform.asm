.686
.model flat

extern round_unsigned_float_to_int: proc
extern _GetAsyncKeyState@4: proc
extern _malloc: proc

.data
platform_x			real4	8.0
platform_width		db		2
platform_step_size	real4	1.0

; in memory, (qword)board will look like this:
; [index]    =  [ (real4)platform_x ]
; [index+4]  =  [ (real4)platform_step_size ]
; [index+8]  =  [ (byte)new_int_x, (byte)old_int_x, (byte)platform_width, (byte)lives ]
; [index+12] =  [ (byte)left_char, (byte)middle_char, (byte)right_char, (byte)color ]


.code

platform_init proc
		push		ebp
		mov			ebp, esp
		push		ebx

		push		16
		call		_malloc
		add			esp, 4

		mov			ebx, [ebp+8]							; ebx = offset board_ptr
		mov			[ebx], eax								; platform_ptr = new allocated memory
		mov			byte ptr [eax+11], 3					; lives

		pop			ebx
		pop			ebp
		ret
platform_init endp

reset_platform_position proc
		push		ebp
		mov			ebp, esp
		push		ebx

		mov			eax, [ebp+8]							; ebx = offset board_ptr
		mov			ebx, platform_x
		mov			[eax], ebx
		mov			ebx, platform_step_size
		mov			[eax+4], ebx
		mov			byte ptr [eax+8], 8						; new int_x - column index to put char
		mov			byte ptr [eax+9], 8						; old int_x - column index where char was in last frame
		mov			byte ptr [eax+10], 2					; width

		pop			ebx
		pop			ebp
		ret
reset_platform_position endp

move_platform proc
		push		ebp
		mov			ebp, esp
		sub			esp, 8			; board_width
		
		push		ebx
		push		edx
		push		esi
		push		edi
		; [ebp+8]  = platform_ptr
		; [ebp+12] = board_ptr
		mov			eax, [ebp+12]
		movzx		eax, byte ptr [eax]
		mov			[ebp-4], eax			; [ebp-4] = board_width

		mov			edi, [ebp+8]			; edi = platform_ptr
		movzx		eax, byte ptr [edi+10]
		mov			[ebp-8], eax
		finit
get_key:
		push		dword ptr 25h			; if eax = 0, then key wasn't pressd
		call		_GetAsyncKeyState@4		; if only last bit of eax = 1, then key was pressed before function call
											; if a bunch of bits (including last bit) are set to 1, then key was pressed when function was called
		btr			eax, 0				; reset last bit
		cmp			eax, 0				; if eax isn't 0, then key is down
		je			check_right_arrow
		mov			ebx, 1				; ebx=1 -> remember, that left key is down
check_right_arrow:
		push		dword ptr 27h
		call		_GetAsyncKeyState@4
		btr			eax, 0
		cmp			eax, 0
		je			right_not_down
;right_key_is_down
		cmp			ebx, 1
		je			dont_redraw_platform			; don't move if both keys are down
		
	; check if can move to right
		fld			dword ptr [edi]			; platform_x
		fadd		dword ptr [edi+4]		; st(0) += platform_delta_x
		fiadd		dword ptr [ebp-8]		; st(0) += platform_width

		fild		dword ptr [ebp-4]		; board_width
		fcomi		ST(0), ST(1)			; check if platform hit the border (if board_width <= platform_x)
		jbe			put_platform_to_right
	; move one step to right
		fstp		ST(0)					; in st0 was board width
		fisub		dword ptr [ebp-8]		; ST(0) was already moved + added width. now subtracting width
		jmp			platform_was_moved
put_platform_to_right:
		fild		dword ptr [ebp-4]
		fisub		dword ptr [ebp-8]
		jmp			platform_was_moved	
right_not_down:
		cmp			ebx,1
		jne			dont_redraw_platform			; don't move if no keys are down
	; left key is down
	; check if can move to left
		fld			dword ptr [edi]			; platform_x
		fsub		dword ptr [edi+4]		; shift position to left
		fisub		dword ptr [ebp-8]		; subtract width
		fld1
		fcomi		ST(0), ST(1)		; compare left side of platform with border
		jae			put_platform_to_left
	; move one step to left
		fstp		ST(0)		
		fiadd		dword ptr [ebp-8]		; ST(0) was already moved + added width. now subtracting width
		jmp			platform_was_moved
put_platform_to_left:
		fld1
		fiadd		dword ptr [ebp-8]
platform_was_moved:
		sub			esp, 4							; push ST(0)
		fstp		dword ptr [esp]
		mov			ebx, [esp]						; ebx = new_position
		call		round_unsigned_float_to_int
		mov			dl, al						; dl = new_int_x
		add			esp, 4
		mov			[edi], ebx					; update platform_x
		mov			bl, [edi+8]					; new_int_x from before calling this function is going to be old_int_x
		mov			[edi+9], bl
		mov			[edi+8], dl
		cmp			bl, dl						; compare old_int_x with new_int_x
		je			dont_redraw_platform
		mov			eax, 1							; redraw platform, because (int)position has changed
		jmp			end_proc
dont_redraw_platform:
		mov			eax, 0
end_proc:
		pop			edi
		pop			esi
		pop			edx
		pop			ebx
		add			esp, 8
		pop			ebp
		ret
move_platform endp
END