.686
.model flat

extern set_console_options: proc		; console font size = 8x8
extern set_color_values: proc			; load from file characters and colors, and assign them to board, platform and ball
extern read_board_from_file: proc		; load array board_tiles from file
extern draw_all: proc
extern redraw_platform: proc
extern erase_ball: proc
extern draw_ball: proc
extern end_animation: proc

extern move_platform: proc
extern move_ball: proc

extern platform_init: proc
extern ball_init: proc
extern board_init: proc
extern reset_platform_position: proc
extern reset_ball_position: proc

extern _Sleep@4: proc
extern _PlaySoundA@12: proc

extern _funkcja: proc

public _main

.data

ball_ptr			dd		?
platform_ptr		dd		?
board_ptr			dd		?
file_name			db		'level01.bin', 0

.code

next_file_name proc
		push		ebp
		mov			ebp, esp
		push		ebx
		push		esi

		mov			esi, offset file_name
		mov			bl, [esi+6]
		inc			bl
		cmp			bl, '9'
		jbe			incremented_level
; carry to next digit
		mov			bl, [esi+5]
		inc			bl
		mov			[esi+5], bl
		mov			bl, '0'
incremented_level:
		mov			[esi+6], bl

		pop			esi
		pop			ebx
		pop			ebp
		ret
next_file_name endp

_main proc
		push		ebp
		mov			ebp, esp

		call		set_console_options				; set font size to 8x8, seems to work

		push		offset board_ptr
		call		board_init
		add			esp, 4

		push		offset platform_ptr
		call		platform_init
		add			esp, 4

		push		offset ball_ptr
		call		ball_init
		add			esp, 4
new_level:
		push		platform_ptr
		call		reset_platform_position
		add			esp, 4
		push		ball_ptr
		call		reset_ball_position
		add			esp, 4

		push		ball_ptr
		push		platform_ptr
		push		board_ptr
		call		set_color_values
		add			esp, 12

		push		offset file_name
		push		board_ptr
		call		read_board_from_file
		add			esp, 8
		cmp			eax, 0
		je			end_game

		push		ball_ptr
		push		platform_ptr
		push		board_ptr
		call		draw_all
		add			esp, 12

game_loop:
		push		board_ptr
		push		platform_ptr
		call		move_platform
		add			esp, 8
		mov			bl, al			; if bl==1 then redraw platform
		
		
		push		board_ptr
		push		ball_ptr
		call		erase_ball
		add			esp, 8
		push		ball_ptr
		push		platform_ptr
		push		board_ptr
		call		move_ball
		add			esp, 12
		mov			bh, al
		push		ball_ptr
		push		platform_ptr
		push		board_ptr
		call		move_ball
		add			esp, 12
		or			bh, al
		push		ball_ptr
		push		platform_ptr
		push		board_ptr
		call		move_ball
		add			esp, 12
		or			bh, al
		
		cmp			bh, 1
		je			lost_life
		cmp			bh, 2
		je			next_level

		push		board_ptr
		push		ball_ptr
		call		draw_ball
		add			esp, 8

		cmp			bl, 0
		je			dont_redraw_platform
		push		board_ptr
		push		platform_ptr
		call		redraw_platform
		add			esp, 8
dont_redraw_platform:
		push		65
		call		_Sleep@4
		jmp			game_loop
lost_life:
		push		board_ptr
		call		end_animation
		add			esp, 4
		mov			eax, platform_ptr
		mov			bl, [eax+11]
		dec			bl
		mov			[eax+11], bl
		cmp			bl, 0
		jne			new_level
		jmp			end_game
next_level:
		mov			eax, board_ptr
		movzx		ebx, byte ptr [eax+3]
		inc			bl
		cmp			bl, 6
		jb			no_level_overflow
		mov			bl, 1
no_level_overflow:
		mov			[eax+3], bl
		push		board_ptr
		call		end_animation
		add			esp, 4
		call		next_file_name
		jmp			new_level
end_game:

		mov			eax, 0					; return 0
		pop			ebp
		ret
_main endp
END