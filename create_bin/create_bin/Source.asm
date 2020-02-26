.686
.model flat

; properties -> linker -> advanced -> image has safe exeption handlers: NO

public _main
extern __write: proc
extern __read: proc
extern _fopen: proc
extern _fclose: proc
extern _fread: proc
extern _fwrite: proc

.data
filename			db			32 dup (?)
buffer_bin			db			32 dup (?)
text				db			"Output file name: ", 0

.code

create_bin_from_txt proc
		push		ebp
		mov			ebp, esp
		sub			esp, 12			; [esp-8]="lvl.txt", [esp-12]="r"

		sub			esp, 272		; txt file has 16 lines which are 16 characters long + endl, so there are 17*16 characters to read
		sub			esp, 32			; value for board_tiles, MUST BE DIVISIBLE BY 4 BECAUSE _fopen WON'T WORK!!!

		push		ebx
		push		edx
		push		esi
		push		edi

		mov			eax, "txt"
		mov			[ebp-4], eax
		mov			eax, ".lvl"
		mov			[ebp-8], eax		; local variable contains char[] = "lvl.txt"

		mov			eax, "r"
		mov			[ebp-12], eax			; local variable contains char[] = "r"
		lea			eax, [ebp-12]
		lea			ebx, [ebp-8]

		push		eax					; pointer to the text "r"
		push		ebx					; "lvl.txt"
		call		_fopen
		add			esp, 8

		mov			ebx, eax			; remember FILE*
		lea			edx, [ebp-284]		; pointer for file characters

		push		ebx
		push		272
		push		1
		push		edx
		call		_fread
		add			esp, 16
		
		mov			esi, 0				; index for reading from buffer
		mov			edi, 0				; index for saving to board_tiles
		mov			edx, 0				; = edi mod 8
converting_lines:
		cmp			byte ptr [ebp-284+esi], "0"
		je			character_0
;character_1:
		bts			[ebp-316+edi], edx
		jmp			bit_is_set
character_0:
		btr			[ebp-316+edi], edx
bit_is_set:

		inc			esi					; go to next character from file, and next bit in board_tiles
		inc			edx

		cmp			edx, 8				; if edx == 8 then edi must point to next byte
		jne			done_with_indexes
	
		mov			edx, 0
		inc			edi

done_with_indexes:
		cmp			byte ptr [ebp-284+esi], 0ah
		jne			checked_for_endl
		inc			esi
checked_for_endl:
		cmp			byte ptr [ebp-284+esi], 0ah
		je			converting_lines
		cmp			byte ptr [ebp-284+esi], '0'
		je			converting_lines
		cmp			byte ptr [ebp-284+esi], '1'
		je			converting_lines
		
		push		ebx
		call		_fclose
		add			esp, 4
		
; saving 32 bytes from [ebp-324] in lvl.bin

		mov			eax, "bw"
		mov			[ebp-12], eax			; local variable contains char[] = "wb"
		lea			eax, [ebp-12]

		push		eax					; pointer to the text "wb"
		push		dword ptr offset filename
		call		_fopen
		add			esp, 8

		mov			ebx, eax
		lea			edx, [ebp-316]		; pointer for board_tiles

		push		eax					; eax = FILE* returned by _fopen
		push		32
		push		1
		push		edx
		call		_fwrite
		add			esp, 16
		
		push		ebx
		call		_fclose
		add			esp, 4

		pop			edi
		pop			esi
		pop			edx
		pop			ebx
		add			esp, 316					; delete local variables
		pop			ebp
		ret
create_bin_from_txt endp
_main proc
		push		dword ptr 18
		push		dword ptr offset text
		push		dword ptr 1
		call		__write
		add			esp, 12

		push		dword ptr 31
		push		dword ptr offset filename
		push		dword ptr 0
		call		__read
		add			esp, 12

		mov			ebx, offset filename
		add			ebx, eax
		dec			ebx
		mov			byte ptr [ebx], 0		; changing end_of_line char to empty char '\0'

		call		create_bin_from_txt
		mov			eax, 0
		ret
_main endp
END