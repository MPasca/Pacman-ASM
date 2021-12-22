.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	--- 30219 Pasca Maria
;	--- Pacman : jucatorul se poate plimba prin labirint
;	------------ fiecare punct mic ii adauga 5 puncte
;	------------ bonusul ii adauga 25 de puncte si face fantoma vulnerabila
;	------------ dupa o anumita durata de timp apare bonusul de 50 de puncte si dupa cateva secunde dispare
;	------------ jucatorul se deplaseaza cu ajutorul sagetilor din dreapta ferestrei de joc
;	------------ daca jucatorul intra in contact cu o fantoma, pierde
;	------------ daca jucatorul intra in contact cu o fantoma vulnerabila, castiga
;	-----------------------------------------
;   --------------------- Fantoma nu se misca


; includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

public start

.data
; fisiere cu date / simboluri / chestii ;
	include digits.inc ; 0 -> 9
	include letters.inc ; A -> Z
	include pacman.inc ; the characters:
		; 0: +5 pct
		; 1: zid
		; 2: +25 pct + power up (makes the ghost vulnerable)
		; 3: pacman
		; 4: ghost
		; 5: bonus +50 pct
		; 6: spatiu liber
		; 7: vulnerable ghost
; ------------------------------------- ;

; ----- chestii tehnice ----- ;
	window_title DB "Pacman",0					; the title

	counter DD 0 			; counts the time events

	arg1 EQU 8				; points to the first argument (first element in the stack)
	arg2 EQU 12				; points to the second argument (second element in the stack)
	arg3 EQU 16				; points to the third argument
	arg4 EQU 20				; points to the fourth argument
	
	i DD 0		; counter verticala
	j DD 0		; counter orizontala
	
	aux DD 0	; variabila auxiliara
	aux2 DD 0	; variabila auxiliara
	
	symbol_width EQU 10		; the symbol's width 		symbol = letter / digit
	symbol_height EQU 20	; the symbol's height
	
	counter_bonus DD 0

	scor DD 0
	lost DB 0
	won DB 0
; --------------------------- ;

; ----- window specs ----- ;
	area_width EQU 640							; the window's width
	area_height EQU 480							; the window's height
	area DD 0
; ------------------------ ;

; ----- controls ----- ;
	control_box EQU 40

	x_up EQU 500
	y_up EQU 300

	x_down EQU 500
	y_down EQU 350

	x_left EQU 450
	y_left EQU 350

	x_right EQU 550
	y_right EQU 350
; -------------------- ;

; ----- characters ----- ;
	character DD 0
	chunk_width EQU 20			; the width of a game surface chunk
	chunk_height EQU 20			; the height of a game surface chunk
	
	;			   0		 1		   2		3		  4			5		  6			7		  8			9
	colours DD 0A0A0A0h, 0FFFF99h, 0FFF200h, 0E1E100h, 0C3C3C3h, 07F7F7Fh, 0009900h, 04A8523h, 080FF00h, 0C7C000h
		; 0 - bckgd
		; 1 - point
		; 2 - fill pacman
		; 3 - outline pacman
		; 4 - fill eyes
		; 5 - outline eyes
		; 6 - fill ghost invul
		; 7 - outline ghost invul
		; 8 - fill bonus
		; 9 - outline bonus

	index_colour DB 0
	current_colour DD 0
; ---------------------- ;

; ----- pacman ----- ;
	x_pacman DD 40
	y_pacman DD 280
	
	x_matrix_pacman DD 1
	y_matrix_pacman DD 10
; ------------------ ;

; ----- ghost ------ ;
	x_ghost DD 180
	y_ghost	DD 260
	
	x_matrix_ghost DD 8
	y_matrix_ghost DD 9
	
	character_ant DD 0
	counter_ghost DD 0
	vulnerable DB 0
; ------------------ ;

; ---- the labyrinth ---- ;
	game_y_coord EQU 80			; the x coord of the game surface 
	game_x_coord EQU 20			; the y coord of the game surface
	
	x_chunk DD 0
	y_chunk DD 0
	
	matrix_width EQU 20			; the game matrix is 22 chunks wide
	matrix_height EQU 15		; the game matrix is 20 chunks high

	i_surf DD 0
	j_surf DD 0

	
	surface	DD 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1	; 0
			DD 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1	; 1
			DD 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 1	; 2
			DD 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 2, 1, 0, 1	; 3
			DD 1, 0, 1, 2, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1	; 4
			DD 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1	; 5
			DD 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1	; 6
			DD 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 1	; 7
			DD 1, 0, 1, 1, 1, 1, 1, 1, 1, 6, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1	; 8
			DD 1, 0, 0, 0, 0, 0, 2, 1, 4, 6, 1, 0, 0, 0, 0, 0, 2, 1, 0, 1	; 9
			DD 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1	; 10
			DD 1, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1	; 11
			DD 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1	; 12
			DD 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1	; 13
			DD 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1	; 14
; ----------------------- ;

.code
; --- procedura make_text afiseaza o litera sau o cifra la coordonatele date --- ;
	; arg1 - simbolul de afisat (litera sau cifra)
	; arg2 - pointer la vectorul de pixeli
	; arg3 - pos_x
	; arg4 - pos_y
	make_text proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp+arg1]		; eax = symbol
		cmp eax, 'A'			; if eax is lower than 'A' or greater than 'Z', it means it's not a word 
		jl make_digit			; then it jumps to make_digit
		cmp eax, 'Z'
		jg make_digit
		sub eax, 'A'
		lea esi, letters		; else esi becomes a pointer to letters.inc
		jmp draw_text			; jumps to draw_text
	make_digit:
		cmp eax, '0'			; if eax is lower than '0' or greater than '9', it means it's not a digit
		jl make_space			; then it jumps to make_space
		cmp eax, '9'
		jg make_space
		sub eax, '0'
		lea esi, digits			; else esi becomes a pointer to digits.inc
		jmp draw_text			; jumps to draw_text
	make_space:	
		mov eax, 26 			; from 0 to 25 = letters, 26 = space
		lea esi, letters		; esi becomes a pointer to letters.inc
		
	draw_text:
		mov ebx, symbol_width	; ebx = symbol_width
		mul ebx					; eax = eax * ebx, eax = symbol * symbol_width
		mov ebx, symbol_height	; ebx = symbol_height
		mul ebx					; eax = eax * ebx, eax = symbol * symbol_width * symbol_height
		add esi, eax			; esi = esi + eax | esi = the position of the chosen symbol
		mov ecx, symbol_height	; ecx = symbol_height
		
	bucla_simbol_linii:
		mov edi, [ebp+arg2] 		; pointer la matricea de pixeli
		mov eax, [ebp+arg4] 		; eax = y
		add eax, symbol_height		; eax = y + symbol_height
		sub eax, ecx				; eax = y + symbol_height - ecx | ecx = counter => eax : y to y + symbol_height
		mov ebx, area_width			; ebx = area_width
		mul ebx						; eax = (y + symbol_height - ecx) * ebx | eax = (y + symbol_height - ecx) * area_width					
		add eax, [ebp+arg3] 		; eax = (y + symbol_height - ecx) * area_width	+ x
		shl eax, 2 					; eax = ((y + symbol_height - ecx) * area_width	+ x) * 4 | Double word
		add edi, eax				; edi = edi + eax | edi then points to the position where the symbol is to be written
		push ecx					; pushes ecx (symbol_height) on the stack
		mov ecx, symbol_width		; ecx = symbol_width
		
		bucla_simbol_coloane:
			cmp byte ptr[esi], 0			; if the value on the current pixel is 0 then
			je simbol_pixel_fundal			; jumps to simbol_pixel_fundal
			mov dword ptr [edi], 0FFFFFFh 	; else it colours the pixel the chosen colour (white)
			jmp simbol_pixel_next			; jumps to simbol_pixel_next
			
			simbol_pixel_fundal:
				mov dword ptr [edi], 0000000h	; colours the pixel the chosen background colour (black)
				
			simbol_pixel_next:
				inc esi							; increments esi so it's pointing to the next pixel of the symbol
				add edi, 4						; edi = edi + 4 | points to the next pixel to be coloured
				loop bucla_simbol_coloane		; loop bucla_simbol_coloane
				pop ecx							; ecx = symbol_width
				loop bucla_simbol_linii			; loop bucla_simbol_linii
				popa
				mov esp, ebp					; esp = ebp 
				pop ebp
				ret
	make_text endp

	; un macro ca sa apelam mai usor desenarea simbolului
	make_text_macro macro symbol, drawArea, x, y
		push y
		push x
		push drawArea
		push symbol
		call make_text
		add esp, 16
	endm
; ------------------------------------------------------------------------------ ;

; ------- make_character ------- ;
	; param:
		; arg1 - drawArea
		; arg2 - character
		; arg3 - x
		; arg4 - y
	make_character proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp + arg4]		; eax = y
		mov ebx, area_width		
		mul ebx						; eax = y * area_width
		add eax, [ebp + arg3]		; eax = y * area_width + x
		
		mov ecx, eax				; ecx = y * area_width + x
		
		mov eax, [ebp + arg2]		; eax = character
		cmp eax, 1
		je wall							; it's wall
		
		; ----- pacman[character] ----- ;
			mov ebx, chunk_width
			mul ebx						; eax = character * chunk_width
			mov ebx, chunk_height
			mul ebx						; eax = character * chunk_width * chunk_height
			mov aux, eax
			; ----------------------------- ;

		mov i, 0
		chr_line:
			mov j, 0
			chr_col:
				mov eax, i 				; eax = i
				mov ebx, area_width
				mul ebx					; eax = i * area_width
				add eax, j				; eax = i * area_width + j
				add eax, ecx
				shl eax, 2
				add eax, [ebp + arg1]		; points to area[x+j][y+i]
				mov aux2, eax				; aux2 points to area[x+j][y+i]
				
				mov eax, i
				mov ebx, chunk_width
				mul ebx					; eax = i * chunk_width
				add eax, j				; eax = i * chunk_width + j
				add eax, aux			; pacman[character][i][j]
				
				xor ebx, ebx
				mov bl, pacman[eax]
				shl ebx, 2
				mov ebx, colours[ebx]
				
				mov eax, aux2
				
				mov dword ptr[eax], ebx
				
				inc j
			cmp j, chunk_width
			jl chr_col
			
			inc i
		cmp i, chunk_height
		jl chr_line
		
		jmp end_chr
		
	wall:
		mov ebx, chunk_width
		mul ebx						; eax = character * chunk_width
		mov ebx, chunk_height		
		mul ebx						; eax = character * chunk_width * chunk_height

		mov i, 0
		wall_line:
			mov j, 0
			wall_col:
				mov eax, i 
				mov ebx, area_width
				mul ebx
				add eax, j
				add eax, ecx
				shl eax, 2
				add eax, [ebp + arg1]		; points to area[x+j][y+i]
				
				mov dword ptr[eax], 0FFFFFFh 
				
				inc j
			cmp j, chunk_width
			jl wall_col
			
			inc i
		cmp i, chunk_height
		jl wall_line

	end_chr:
		popa
		mov esp, ebp					; esp = ebp 
		pop ebp
		ret
	make_character endp

	make_character_macro macro drawArea, character, x, y
		push y
		push x
		push character
		push drawArea
		call make_character
		add esp, 16
	endm
; ------------------------------ ;

; ------ arrows ------ ;
	; param:
		; arg1 - x_click
		; arg2 - y_click
	arrows proc
		push ebp
		mov ebp, esp
		pusha
		
		mov eax, [ebp + arg1]	; eax = x
		mov ebx, [ebp + arg2]	; ebx = y
		
		cmp eax, 450
		jl end_arrows			; x < 450
		cmp eax, 600
		jg end_arrows			; x > 600
		
		cmp ebx, 300
		jl end_arrows			; y < 300
		cmp ebx, 400
		jg end_arrows			; y > 400
		
		cmp ebx, 350
		jl arrow_up				; 300 < y < 350
		
		cmp eax, 500
		jl arrow_left			; 450 < x < 500
		
		cmp eax, 550
		jl arrow_down			; 500 < x < 550
		
	arrow_right:
		mov eax, y_matrix_pacman
		mov ebx, matrix_width
		mul ebx
		add eax, x_matrix_pacman
		add eax, 1					
		shl eax, 2					; surface[x_matrix_pacman + 1][y_matrix_pacman] 
		
		cmp [surface + eax], 1		; if it's wall
		je end_arrows
		
		cmp [surface + eax], 0
		je r_add_5
		cmp [surface + eax], 2
		je r_add_25
		cmp [surface + eax], 5
		je r_add_50
		
		cmp [surface + eax], 4
		je lose
		cmp [surface + eax], 7
		je r_win
	
	back_right:
		make_character_macro area, 6, x_pacman, y_pacman
		
		lea ebx, surface
		add ebx, eax
		mov dword ptr[ebx], 6
		mov eax, x_matrix_pacman
		add eax, 1
		mov x_matrix_pacman, eax
		
		mov eax, chunk_width
		mov ecx, x_pacman
		add ecx, eax
		mov x_pacman, ecx
		make_character_macro area, 3, x_pacman, y_pacman
		
		jmp end_arrows
	
r_add_5:
	add scor, 5
	jmp back_right
r_add_25:
	add scor, 25
	mov vulnerable, 1
	mov counter_ghost, 0
	jmp back_right
r_add_50:
	add scor, 50
	jmp back_right
	
r_win:
	add scor, 100 
	make_text_macro 'Y', area, 20, 400
	make_text_macro 'O', area, 30, 400
	make_text_macro 'U', area, 40, 400
	
	make_text_macro 'W', area, 60, 400
	make_text_macro 'O', area, 70, 400
	make_text_macro 'N', area, 80, 400
	
	mov won, 1
	jmp back_right
	
	arrow_left:
		mov eax, y_matrix_pacman
		mov ebx, matrix_width
		mul ebx
		add eax, x_matrix_pacman
		sub eax, 1					
		shl eax, 2					; surface[x_matrix_pacman - 1][y_matrix_pacman] 
		
		cmp [surface + eax], 1		; if it's wall
		je end_arrows
		
		cmp [surface + eax], 0
		je l_add_5
		cmp [surface + eax], 2
		je l_add_25
		cmp [surface + eax], 5
		je l_add_50
		
		cmp [surface + eax], 4
		je lose
		cmp [surface + eax], 7
		je l_win
		
	back_left:
		make_character_macro area, 6, x_pacman, y_pacman
		
		lea ebx, surface
		add ebx, eax
		mov dword ptr[ebx], 6
		mov eax, x_matrix_pacman
		sub eax, 1
		mov x_matrix_pacman, eax
		
		mov eax, chunk_width
		mov ecx, x_pacman
		sub ecx, eax
		mov x_pacman, ecx
		make_character_macro area, 3, x_pacman, y_pacman

		jmp end_arrows	
		
l_add_5:
	add scor, 5
	jmp back_left
l_add_25:
	add scor, 25
	mov vulnerable, 1
	mov counter_ghost, 0
	jmp back_left
l_add_50:
	add scor, 50
	jmp back_left
	
l_win: 
	add scor, 100
	make_text_macro 'Y', area, 20, 400
	make_text_macro 'O', area, 30, 400
	make_text_macro 'U', area, 40, 400
	
	make_text_macro 'W', area, 60, 400
	make_text_macro 'O', area, 70, 400
	make_text_macro 'N', area, 80, 400
	
	mov won, 1
	jmp back_left
	
	arrow_down:
		mov eax, y_matrix_pacman
		add eax, 1
		mov ebx, matrix_width
		mul ebx
		add eax, x_matrix_pacman
		shl eax, 2					; surface[x_matrix_pacman][y_matrix_pacman + 1] 
		
		cmp [surface + eax], 1		; if it's wall
		je end_arrows
		
		cmp [surface + eax], 0
		je d_add_5
		cmp [surface + eax], 2
		je d_add_25
		cmp [surface + eax], 5
		je d_add_50
		
		cmp [surface + eax], 4
		je lose
		cmp [surface + eax], 7
		je d_win
	
	back_down:
		make_character_macro area, 6, x_pacman, y_pacman
		
		lea ebx, surface
		add ebx, eax
		mov dword ptr[ebx], 6
		mov eax, y_matrix_pacman
		add eax, 1
		mov y_matrix_pacman, eax
		
		mov eax, y_pacman
		mov ebx, chunk_height
		add eax, ebx
		mov y_pacman, eax	; y_pacman = y_pacman + chunk_height
		make_character_macro area, 3, x_pacman, y_pacman

		jmp end_arrows
	
d_add_5:
	add scor, 5
	jmp back_down
d_add_25:
	add scor, 25
	mov vulnerable, 1
	mov counter_ghost, 0
	jmp back_down
d_add_50:
	add scor, 50
	jmp back_down
	
d_win: 
	add scor, 100
	make_text_macro 'Y', area, 20, 400
	make_text_macro 'O', area, 30, 400
	make_text_macro 'U', area, 40, 400
	
	make_text_macro 'W', area, 60, 400
	make_text_macro 'O', area, 70, 400
	make_text_macro 'N', area, 80, 400
	
	mov won, 1
	jmp back_down

		
	arrow_up:
		cmp eax, 500
		jl end_arrows			; x < 500
		cmp eax, 550
		jg end_arrows			; x > 550
		
		mov eax, y_matrix_pacman
		sub eax, 1
		mov ebx, matrix_width
		mul ebx
		add eax, x_matrix_pacman
		shl eax, 2					; surface[x_matrix_pacman][y_matrix_pacman - 1] 
		
		cmp [surface + eax], 1		; if it's wall
		je end_arrows

		cmp [surface + eax], 0
		je u_add_5
		cmp [surface + eax], 2
		je u_add_25
		cmp [surface + eax], 5
		je u_add_50
		
		cmp [surface + eax], 4
		je lose
		cmp [surface + eax], 7
		je u_win
	
	back_up:
		make_character_macro area, 6, x_pacman, y_pacman
		lea ebx, surface
		add ebx, eax
		mov dword ptr[ebx], 6
		mov eax, y_matrix_pacman
		sub eax, 1
		mov y_matrix_pacman, eax	; updates player's position on the matrix
		
		mov eax, y_pacman
		mov ebx, chunk_height
		sub eax, ebx
		mov y_pacman, eax	; y_pacman = y_pacman - chunk_height
		make_character_macro area, 3, x_pacman, y_pacman
		
		jmp end_arrows
	
u_add_5:
	add scor, 5
	jmp back_up
u_add_25:
	add scor, 25
	mov vulnerable, 1
	mov counter_ghost, 0
	jmp back_up
u_add_50:
	add scor, 50
	jmp back_up
	
u_win:
	add scor, 100 
	make_text_macro 'Y', area, 20, 400
	make_text_macro 'O', area, 30, 400
	make_text_macro 'U', area, 40, 400
	
	make_text_macro 'W', area, 60, 400
	make_text_macro 'O', area, 70, 400
	make_text_macro 'N', area, 80, 400
	
	mov won, 1
	jmp back_up
	
lose:
	lea ebx, surface
	add ebx, eax
	mov dword ptr[ebx], 6
	make_character_macro area, 6, x_pacman, y_pacman

	mov scor, 0
	make_text_macro 'Y', area, 20, 400
	make_text_macro 'O', area, 30, 400
	make_text_macro 'U', area, 40, 400
	
	make_text_macro 'L', area, 60, 400
	make_text_macro 'O', area, 70, 400
	make_text_macro 'S', area, 80, 400
	make_text_macro 'T', area, 90, 400
	
	mov lost, 1
	jmp end_arrows

	end_arrows:
		popa
		mov esp, ebp
		pop ebp
		ret
	arrows endp
	
	arrows_macro macro x_click, y_click
		push y_click
		push x_click
		call arrows
		add esp, 8
	endm
; -------------------- ;

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp + arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0000000h
	push area
	call memset
	add esp, 12
	
draw_surface:
	
	mov i_surf, 0
	surface_line:
	
		mov j_surf, 0
		surface_col:
			mov eax, i_surf
			mov ebx, matrix_width
			mul ebx
			add eax, j_surf
			shl eax, 2
			
			lea esi, surface
			mov eax, [surface + eax]		; eax = surface[eax]
			mov ecx, eax
			
			; x = game_x_coord + j * chunk_width ;
				mov eax, j_surf
				mov ebx, chunk_width
				mul ebx
				add eax, game_x_coord
				mov x_chunk, eax	; x = x0 + j * chunk_width
			; ---------------------------------- ;
			
			; y = game_y_coord + i * chunk_height ;
				mov eax, i_surf
				mov ebx, chunk_height
				mul ebx
				add eax, game_y_coord
				mov y_chunk, eax	; y = y0 + i * chunk_height
			; ----------------------------------- ;
			
			make_character_macro area, ecx, x_chunk, y_chunk
			
			inc j_surf
		cmp j_surf, matrix_width
		jl surface_col
		
		inc i_surf
	cmp i_surf, matrix_height
	jl surface_line

controls:

	mov i, 300
	mov j, 500
	line_up:
		mov eax, i 
		mov ebx, area_width
		mul ebx
		add eax, j
		shl eax, 2
		add eax, area 
		mov dword ptr[eax], 0FFFFFFh
		inc j
	cmp j, 550
	jle line_up
	
	mov i, 350
	mov j, 450
	line_middle:
		mov eax, i 
		mov ebx, area_width
		mul ebx
		add eax, j
		shl eax, 2
		add eax, area 
		mov dword ptr[eax], 0FFFFFFh
		inc j
	cmp j, 600
	jle line_middle
	
	mov i, 400
	mov j, 450
	line_down:
		mov eax, i 
		mov ebx, area_width
		mul ebx
		add eax, j
		shl eax, 2
		add eax, area 
		mov dword ptr[eax], 0FFFFFFh
		inc j
	cmp j, 600
	jle line_down
	
	mov i, 350
	mov j, 450
	line_left:
		mov eax, i 
		mov ebx, area_width
		mul ebx
		add eax, j
		shl eax, 2
		add eax, area 
		mov dword ptr[eax], 0FFFFFFh
		inc i
	cmp i, 400
	jle line_left
	
	mov i, 300
	mov j, 500
	line_middle_left:
		mov eax, i 
		mov ebx, area_width
		mul ebx
		add eax, j
		shl eax, 2
		add eax, area 
		mov dword ptr[eax], 0FFFFFFh
		inc i
	cmp i, 400
	jle line_middle_left
	
	mov i, 300
	mov j, 550
	line_middle_right:
		mov eax, i 
		mov ebx, area_width
		mul ebx
		add eax, j
		shl eax, 2
		add eax, area 
		mov dword ptr[eax], 0FFFFFFh
		inc i
	cmp i, 400
	jle line_middle_right
	
	mov i, 350
	mov j, 600
	line_right:
		mov eax, i 
		mov ebx, area_width
		mul ebx
		add eax, j
		shl eax, 2
		add eax, area 
		mov dword ptr[eax], 0FFFFFFh
		inc i
	cmp i, 400
	jle line_right
	
evt_click:
	cmp won, 1
	je score
	cmp lost, 1
	je evt_timer

	mov eax, x_pacman	; EAX = x
	mov ebx, y_pacman	; EBX = y
	make_character_macro area, 3, eax, ebx

	mov eax, [ebp + arg2]	; eax = x
	mov ebx, [ebp + arg3]	; eax = y
	arrows_macro eax, ebx

	
evt_timer:
	inc counter
	inc counter_bonus
	xor edx, edx
	mov eax, counter
	mov ebx, 5
	div ebx
	cmp edx, 0
	jne evt_bonus
	mov eax, x_ghost
	mov ebx, y_ghost
	;move_ghost_macro area, eax, ebx
	
	cmp won, 1
	je score
	; --- vulnerable ghost --- ;
		cmp vulnerable, 1
		jne evt_bonus
			inc counter_ghost
			
			mov eax, y_matrix_ghost
			mov ebx, matrix_width
			mul ebx
			add eax, x_matrix_ghost
			shl eax, 2
			
			cmp counter_ghost, 10
			jg vul_end
				make_character_macro area, 7, x_ghost, y_ghost
				mov [surface + eax], 7
				jmp evt_bonus
				
			vul_end:
				make_character_macro area, 4, x_ghost, y_ghost
				mov [surface + eax], 4
				mov vulnerable, 0
			
	; ------------------------ ;

evt_bonus:	
	xor edx, edx
	mov eax, counter
	mov ebx, 120
	div ebx
	
	cmp edx, 0
	jne not_bonus
	
	mov counter_bonus, 0

	make_character_macro area, 5, 200, 300
	mov eax, 11
	mov ebx, matrix_width
	mul ebx
	add eax, 9
	shl eax, 2
	mov surface[eax], 5
	
not_bonus:
	cmp counter_bonus, 30
	jne score
	
	make_character_macro area, 6, 200, 300
	mov eax, 11
	mov ebx, matrix_width
	mul ebx
	add eax, 9
	shl eax, 2
	mov surface[eax], 6
	
; ------ scor ------ ;
score:
	mov ebx, 10		; to divide
	
	mov eax, scor
	
	; --- unit --- ;
		mov edx, 0
		div ebx			; edx = eax/10
		add edx, '0'
		make_text_macro edx, area, 540, 20
	
	; --- zeci --- ;
		mov edx, 0
		div ebx
		add edx, '0'
		make_text_macro edx, area, 530, 20
		
	; --- sute --- ;
		mov edx, 0
		div ebx
		add edx, '0'
		make_text_macro edx, area, 520, 20
		
	; --- mii --- ;
		mov edx, 0
		div ebx
		add edx, '0'
		make_text_macro edx, area, 500, 20

; ------------------- ;
	
afisare_litere:	
	;titlul jocului
	make_text_macro 'P', area, 140, 40
	make_text_macro 'A', area, 150, 40
	make_text_macro 'C', area, 160, 40
	
	make_text_macro 'M', area, 180, 40
	make_text_macro 'A', area, 190, 40
	make_text_macro 'N', area, 200, 40
	
	; ------ scor ------ ;
	make_text_macro 'S', area, 450, 20
	make_text_macro 'C', area, 460, 20
	make_text_macro 'O', area, 470, 20
	make_text_macro 'R', area, 480, 20
		
	make_text_macro 'C', area, 500, 250
	make_text_macro 'O', area, 510, 250
	make_text_macro 'N', area, 520, 250
	make_text_macro 'T', area, 530, 250
	make_text_macro 'R', area, 540, 250
	make_text_macro 'O', area, 550, 250
	make_text_macro 'L', area, 560, 250

	; --- arrows --- ;
		make_text_macro 'U', area, 520, 315
		make_text_macro 'D', area, 520, 365 
		make_text_macro 'L', area, 470, 365
		make_text_macro 'R', area, 570, 365
	; -------------- ;
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	; alocam memorie pentru zona de desenat ;
		mov eax, area_width
		mov ebx, area_height
		mul ebx
		shl eax, 2
		push eax
		call malloc
		add esp, 4
		mov area, eax
	; ------------------------------------- ;
	
	; apelam functia de desenare a ferestrei ;
		; typedef void (*DrawFunc)(int evt, int x, int y);
		; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
		push offset draw
		push area
		push area_height
		push area_width
		push offset window_title
		call BeginDrawing
		add esp, 20
	; -------------------------------------- ;
	;terminarea programului
	push 0
	call exit
end start
