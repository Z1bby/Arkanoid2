.686
.model flat

extern _fopen: proc
extern _fread: proc
extern _fwrite: proc
extern _fgets: proc
extern _fseek: proc
extern _fclose: proc

extern _GetStdHandle@4: proc				; STD_OUTPUT_HANDLE = (DWORD)-11
extern _SetCurrentConsoleFontEx@12: proc
extern _SetConsoleTextAttribute@8: proc
extern _SetConsoleScreenBufferSize@8: proc

.code

set_color_values proc
		push		ebp
		mov			ebp, esp
		;[ebp+8] board_ptr
		;[ebp+12] platform_ptr
		;[ebp+16] ball_ptr
		sub			esp, 12
		sub			esp, 32		; [ebp-16] = getline buffer
		push		ebx
		push		edi
		mov			dword ptr [ebp-4], "txt"
		mov			dword ptr [ebp-8], ".tes"
		mov			byte ptr [ebp-1], 0			; [ebp-8] = file_name = "set.txt\0";
		mov			byte ptr [ebp-12], "r"		; [ebp-12] = file_opts = "r\0";
		mov			byte ptr [ebp-11], 0

		mov			eax, [ebp+8]	; eax = board_ptr
		mov			al, [eax+3]		; al = level_number
		dec			al
		mov			ecx, 12
		mul			ecx				; 12 lines for each level

		movzx		edi, al			; edi = loop size

		lea			eax, [ebp-12]		; pointer to "r"
		push		eax
		lea			eax, [ebp-8]		; pointer to file_name
		push		eax
		call		_fopen
		add			esp, 8
		mov			ebx, eax			; ebx = FILE*

		inc			edi					; always skip one line before getting values
skip_lines:
		push		ebx
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12
		dec			edi
		cmp			edi, 0
		jne			skip_lines
assign_values:
		mov			edi, [ebp+8]	; board_ptr

		push		ebx				; line_1 = tile_char
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		dec_string_to_char
		add			esp, 4
		mov			[edi+8], al

		push		ebx				; line_2 = tile_color
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		hex_string_to_char
		add			esp, 4
		mov			[edi+9], al

		push		ebx				; line_3 = background_color
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		hex_string_to_char
		add			esp, 4
		mov			[edi+10], al

		push		ebx				; line_4 = border_char
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		dec_string_to_char
		add			esp, 4
		mov			[edi+12], al

		push		ebx				; line_5 = border_color
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		hex_string_to_char
		add			esp, 4
		mov			[edi+13], al

		mov			edi, [ebp+12]		; platform ptr

		push		ebx				; line_6 = platform_char left
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		dec_string_to_char
		add			esp, 4
		mov			[edi+12], al

		push		ebx				; line_7 = platform_char middle
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		dec_string_to_char
		add			esp, 4
		mov			[edi+13], al

		push		ebx				; line_8 = platform_char right
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		dec_string_to_char
		add			esp, 4
		mov			[edi+14], al

		push		ebx				; line_9 = platform_color
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		hex_string_to_char
		add			esp, 4
		mov			[edi+15], al

		mov			edi, [ebp+16]		;ball ptr

		push		ebx				; line_10 = ball_char
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		dec_string_to_char
		add			esp, 4
		mov			[edi+20], al
		
		push		ebx				; line_11 = ball_color
		push		32
		lea			eax, [ebp-44]
		push		eax
		call		_fgets
		add			esp, 12

		push		[ebp-44]
		call		hex_string_to_char
		add			esp, 4
		mov			[edi+21], al



		pop			edi
		pop			ebx
		add			esp, 44
		pop			ebp
		ret
set_color_values endp

read_board_from_file proc
		push		ebp
		mov			ebp, esp
		sub			esp, 4			; local variable
		push		ebx
		push		esi
		push		edi

		mov			eax, "br"
		mov			[ebp-4], eax		; local variable
		lea			eax, [ebp-4]		; pointer to a text "rb"

		push		eax
		push		[ebp+12]			; file name
		call		_fopen			
		add			esp, 8
		cmp			eax, 0
		je			end_proc

		mov			ebx, eax		; remember FILE* returned by _fopen
		push		eax
		push		32
		push		1
		mov			eax, [ebp+8]			;board_ptr
		push		[eax+4]				; board_tiles
		call		_fread
		add			esp, 16
		
		push		ebx
		call		_fclose
		add			esp, 4

		mov			ebx, 0				; count tiles
		mov			edi, 0				; bit index
		mov			edx, 0				; general index
		mov			esi, [ebp+8]			; board_ptr
		mov			esi, [esi+4]		; board_tiles

count_tiles:
		bt			[esi], edi
		jnc			dont_add_tile
		inc			ebx
dont_add_tile:
		inc			edi
		cmp			edi, 8
		jne			count_tiles
		mov			edi, 0
		inc			esi
		inc			edx
		cmp			edx, 32
		jb			count_tiles

		mov			esi, [ebp+8]
		mov			[esi+11], bl
		mov			eax, 1
end_proc:
		pop			edi
		pop			esi
		pop			ebx
		add			esp, 4			; local variable
		pop			ebp
		ret
read_board_from_file endp

dec_string_to_char proc
		push		ebp
		mov			ebp, esp
		push		ebx
		push		edx
		push		esi

		mov			eax, 0			; return value
		mov			esi, ebp
		add			esi, 8			; esi = offset string
		mov			edx, 0
		mov			ecx, 10			; ... eax *= 10; ...
converting:
		mov			bl, [esi]
		sub			bl, '0'
		mul			ecx
		add			al, bl
		inc			esi
		cmp			byte ptr [esi], '0'
		jb			end_proc
		cmp			byte ptr [esi], '9'
		jbe			converting
end_proc:
		pop			esi
		pop			edx
		pop			ebx
		pop			ebp
		ret
dec_string_to_char endp

hex_string_to_char proc
		push		ebp
		mov			ebp, esp

		mov			ecx, ebp
		add			ecx, 8			; ecx = offset string
		movzx		eax, byte ptr [ecx]
		cmp			eax, '9'
		jb			decimal_first_digit
;a, b, c, d, e or f
		sub			eax, 'a'
		add			eax, 10
		jmp			second_digit
decimal_first_digit:
		sub			eax, '0'
second_digit:
		shl			eax, 4
		inc			ecx
		add			al, [ecx]
		cmp			byte ptr [ecx], '9'
		jb			decimal_second_digit
;a, b, c, d, e or f
		sub			eax, 'a'
		add			eax, 10
		jmp			end_proc
decimal_second_digit:
		sub			eax, '0'
end_proc:
		pop			ebp
		ret
hex_string_to_char endp

round_unsigned_float_to_int proc
		push		ebp
		mov			ebp, esp
		push		ebx
		; [ebp+8]=float(number)

		mov			ecx, [ebp+8]
		shr			ecx, 23			; ecx = exponent
		cmp			cl, 7fh			; 7fh -> 2^0
		ja			above_zero
		je			result_is_one
		mov			eax, 0
		bt			dword ptr [ebp+8], 22		; check if it's 0.5 or above. check mantissa bit of value 2^(-1)
		jnc			end_proc
		inc			eax
		jmp			end_proc
result_is_one:
		mov			eax, 1
		bt			dword ptr [ebp+8], 22		; check if it's 1.5 or above. check mantissa bit of value 2^(-1)
		jnc			end_proc
		inc			eax
		jmp			end_proc
above_zero:
		sub			cl, 7fh
		mov			ebx, [ebp+8]
		ror			ebx, 22			; least significant bit in ebx has value 2^(-n)
		mov			eax, 1			; return value
multiply_mantissa:					; changing form from (mantissa*2^exp) to ((int)eax*2^0)
		shl			eax, 1				; eax *= 2
		bt			ebx, 0				; if bit 2^(-n) == 1, add bit to eax
		jnc			skip_adding_bit
		inc			eax
skip_adding_bit:
		rol			ebx, 1				; n++
		loop		multiply_mantissa	; ecx = exponent
		
		bt			ebx, 0		; check if it's (something).5 or above. check mantissa bit of value 2^(-n)
		jnc			end_proc
		inc			eax
end_proc:
		pop			ebx
		pop			ebp
		ret
round_unsigned_float_to_int endp

ceil_unsigned_float_to_int proc
		push		ebp
		mov			ebp, esp
		push		ebx
		; [ebp+8]=float(number)

		mov			ecx, [ebp+8]
		shr			ecx, 23			; ecx = exponent
		cmp			cl, 7fh			; 7fh -> 2^0
		ja			above_zero
		je			result_is_one
		mov			eax, 0
		and			dword ptr [ebp+8], 007fffffh
		cmp			dword ptr [ebp+8], 0
		je			end_proc
		inc			eax
		jmp			end_proc
result_is_one:
		mov			eax, 1
		and			dword ptr [ebp+8], 007fffffh	; leave just mantissa bits, and compare it to 0
		cmp			dword ptr [ebp+8], 0
		je			end_proc
		inc			eax
		jmp			end_proc
above_zero:
		sub			cl, 7fh
		mov			ebx, [ebp+8]
		and			ebx, 007fffffh		; leave just mantissa
		ror			ebx, 22			; least significant bit in ebx has value 2^(-n)
		mov			eax, 1			; return value
multiply_mantissa:					; changing form from (mantissa*2^exp) to ((int)eax*2^0)
		shl			eax, 1				; eax *= 2
		btr			ebx, 0				; if bit 2^(-n) == 1, add bit to eax. reset bit to leave only least significant bits
		jnc			skip_adding_bit
		inc			eax
skip_adding_bit:
		rol			ebx, 1				; n++
		loop		multiply_mantissa	; ecx = exponent
		
		cmp			ebx, 0		; check if there's something left in mantissa
		je			end_proc
		inc			eax
end_proc:
		pop			ebx
		pop			ebp
		ret
ceil_unsigned_float_to_int endp

floor_unsigned_float_to_int proc
		push		ebp
		mov			ebp, esp
		push		ebx
		; [ebp+8]=float(number)

		mov			ecx, [ebp+8]
		shr			ecx, 23			; ecx = exponent
		cmp			cl, 7fh			; 7fh -> 2^0
		ja			above_zero
		je			result_is_one
		mov			eax, 0
		jmp			end_proc
result_is_one:
		mov			eax, 1
		jmp			end_proc
above_zero:
		sub			cl, 7fh
		mov			ebx, [ebp+8]
		ror			ebx, 22			; least significant bit in ebx has value 2^(-n)
		mov			eax, 1			; return value
multiply_mantissa:					; changing form from (mantissa*2^exp) to ((int)eax*2^0)
		shl			eax, 1				; eax *= 2
		bt			ebx, 0				; if bit 2^(-n) == 1, add bit to eax
		jnc			skip_adding_bit
		inc			eax
skip_adding_bit:
		rol			ebx, 1				; n++
		loop		multiply_mantissa	; ecx = exponent
end_proc:
		pop			ebx
		pop			ebp
		ret
floor_unsigned_float_to_int endp

set_console_options proc
		push		ebp
		mov			ebp, esp
		
		sub			esp, 84
		mov			[ebp - 84], dword ptr 00000054h		; cbSize = sizeof(cfi);
		mov			[ebp - 80], dword ptr 0				; cFont = 0
		mov			[ebp - 76], word ptr 16				; font width
		mov			[ebp - 74], word ptr 12				; font height
		mov			[ebp - 72], dword ptr 0				; FontFamily = FF_DONTCARE;
		mov			[ebp - 68], dword ptr 00000190h		; FontWeight = FW_NORMAL;

		sub			esp, 4

		push		0FFFFFFF5h			; STD_OUTPUT_HANDLE = (DWORD)-11
		call		_GetStdHandle@4
		mov			[ebp-88], eax

		lea			eax, [ebp-84]
		push		eax
		push		0
		push		[ebp-88]
		call		_SetCurrentConsoleFontEx@12

		add			esp, 88
		pop			ebp
		ret
set_console_options endp
END