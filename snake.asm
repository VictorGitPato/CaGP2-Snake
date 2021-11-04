;	set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;	
; return values
;     This procedure should never return.
main:
    ; TODO: Finish this procedure.
	
	call clear_leds
	
	call create_food

	call create_food

	call draw_array

	

	ret

; BEGIN: clear_leds
clear_leds:
	
	addi t1, zero, 0
	stw zero, LEDS(t1) ; store zero in LEDS[0]

	addi t1, zero, 4
	stw zero, LEDS(t1) ; store zero in LEDS[1]

	addi t1, zero, 8
	stw zero, LEDS(t1) ; store zero in LEDS[2]

	ret
; END: clear_leds


; BEGIN: set_pixel
set_pixel:
	; register a0 : the pixel s x-coordinate
	; register a1 : the pixel s y-coordinate

	; LEDS[0]_x : (0, 1,  2,  3) = (0000, 0001, 0010, 0011)
	; LEDS[1]_x : (4, 5,  6,  7) = (0100, 0101, 0110, 0111)
	; LEDS[2]_x : (8, 9, 10, 11) = (1000, 1001, 1010, 1011)

	; LEDS[i]_x determined by the 4 bits this way :
	; 
	; 1xxx => i = 2
	; 01xx => i = 1
	; 00xx => i = 0
	;
	; t2 := x(3) or x(2)
	; 
	;
	; => i = 0 add t2
	;    i = i << x(3)
	;
	; t1 := i
	; 
	; 0  : 00000   (0 : 0000, 4 : 0100,  8 : 1000)
	; 8  : 01000   (1 : 0001, 5 : 0101,  9 : 1001) 
	; 16 : 10000   (2 : 0010, 6 : 0110, 10 : 1010)
	; 24 : 11000   (3 : 0011, 7 : 0111, 11 : 1011)
	;
	; In word index :
	;   n = x(1 downto 0) && "000" + y
	;
	; t2 := n
	;
	; Procedure goal :
	;   LEDS[i][n] = '1'
	; 
	; (needs to be checked : little endian definition)
	; 1 bit activator mask : m = 1 << n
	; 
	; => LEDS[i][n] = '1' <=> LEDS[i] = LEDS[i] or m

	addi t3, zero, 1

	slli t4, t3, 3
	and t4, t4, a0   ; get x(3)
	srli t4, t4, 3

	slli t5, t3, 2
	and t6, t5, a0   ; get x(2)
	srli t6, t6, 2

	or t2, t4, t6

	add t1, zero, t2
	sll t1, t1, t4     ;  t1 := i index in the LEDS array

	addi t3, zero, 3   ; two LSBs active
	and t4, t3, a0
	slli t4, t4, 3
	add t4, t4, a1     ; t4 := n

	; get LEDS[i]
	; set LEDS[i][n]

	addi t3, zero, 1
	sll t3, t3, t4     ; t3 := m

	slli t1, t1, 2 ; we multiply by 4

	ldw t5, LEDS(t1)
	or t5, t5, t3
	stw t5, LEDS(t1)

	ret

; END: set_pixel


; BEGIN: display_score
display_score:

; END: display_score


; BEGIN: init_game
init_game:

; END: init_game


; BEGIN: create_food
create_food:
	; In this section you will write procedure create_food, which creates a new food item at a random location on the screen.
	; The food size is always one (a single LED pixel), while its location must not overlap
	; with the snake. You can differentiate between a snake and the food easily: GSA element representing
	; the food has the value 5, while the GSA elements representing the snake have values 1-4. To display the
	; food, draw_array can be used


	until_valid:
		; 0 : empty
		; 1-4 : snake
		; 5 : food

		ldw t1, RANDOM_NUM(zero)
		addi t2, zero, 0xFF ; mask to get the first byte

		and t4, t1, t2 ; get the first byte
		slli t4, t4, 2 ; * 4 since we will use words

		ldw t5, GSA(t4)

		bne t5, zero, until_valid
		
		addi t5, zero, 5

		stw t5, GSA(t4)

		ret

; END: create_food


; BEGIN: hit_test
hit_test:
	; v0 : 1 for score increment, 2 for the game end, and 0 when no collision.

	ldw t1, HEAD_X(zero)
	ldw t2, HEAD_Y(zero)

	call get_input

	; in v0 after call to get_input
	; 1 leftwards    0001
	; 2 upwards      0010
	; 3 downwards    0011
	; 4 rightwards   0100

	addi t4, zero, 1
	beq v0, t4, left

	addi t4, zero, 2
	beq v0, t4, up
	
	addi t4, zero, 3
	beq v0, t4, down
	
	addi t4, zero, 4
	beq v0, t4, right

	left:
		addi t1, t1, -1
		call finish

	up:
		addi t2, t2, -1
		call finish

	down:
		addi t2, t2, 1
		call finish
	
	right:
		addi t1, t1, 1
		call finish

	finish:
		cmpgei t5, t1, 0 ; check value
		cmplti t6, t1, 11

		or t5, t5, t6
		addi t6, zero, 1
		addi v0, zero, 2 ; end of the game
		bne t5, t6, x_axis_ok ; collision detected with the x axis boundaries
		addi v0, zero, 2
		ret

		x_axis_ok:
			cmpgei t5, t2, 0 ; check value
			cmplti t6, t2, 7

			or t5, t5, t6
			addi t6, zero, 1
			addi v0, zero, 2 ; end of the game
			bne t5, t6, ok_inside ; collision detected with the y axis boundaries
			addi v0, zero, 2
			ret

		; need to check if snake collide with its own tail
		; need to check when snake collide with food

		ok_inside:
			srli t3, t1, 3 ; x * 8
			add t3, t3, t2 ; i = x * 8 + y
			ldw t1, GSA(t3) ; load GSA[index] to get the new cell

			; Recall: 1 for score increment, 2 for the game end, and 0 when no collision.

			bne t1, zero, with_element_in_the_cell ; when there is an element in the cell
			addi v0, zero, 0 ; no collision
			ret
			
		with_element_in_the_cell: ; element : number inside t1
			cmpgei t1, t1, 5 ; if food 
			addi t2, zero, 1
			bne t1, t2, hit_tail
			; else hit food
			addi v0, zero, 1
			ret


		hit_tail:
			addi v0, zero, 2
			ret

	; Outside if :
	; x < 0 or
	; x > 11 or
	; y < 0 or
	; y > 7	

; END: hit_test


; BEGIN: get_input
get_input:
	; return values :
	;   register v0 : Which button is pressed. The return value is indicated in table 4 

	addi t3, zero, 1

	slli t4, t3, 4
	addi t2, zero, BUTTONS ;4 bytes for the buttons 
	addi t2, t2, 4 ; edgecapture starts from this address (4 bytes as well)

	addi v0, zero, 6
	slli t4, t3, 5

	check: 
		addi v0, v0, -1
		srli t4, t4, 1
		and t1, t2, t4 ; check if Button[i] was pressed
		bne t1, t3, check

		addi t1, zero, 4
		stw zero, BUTTONS(t1);clear edgecapture

		addi t1, zero, 5
		beq v0, t1, end	;change snake's head direction if a direction button was pressed (ie if v0 != t1)

		
		ldw t1, HEAD_X(zero) ;get current posx, 
		ldw t2, HEAD_Y(zero) ;get posy of snake (head)

		slli t1, t1, 3
		add t1, t1, t2
		ldw t3, GSA(t1) ;get dir value (8x + y)
		
		addi t2, zero, 5
		beq t3, t1, end ;Check if the new direction value is not directly opposite to the snake's current direction value. (ie if it is = to 5 or not, 1+4 or 2+3
                   ; are opposite directions)
	
		stw v0, GSA(t1);else we change the direction
		end:
		ret

; END: get_input


; BEGIN: draw_array
draw_array:
	main_draw:
		addi s1, zero, -1 ; s1 := x
		addi s6, zero, 13 ; upper bound
		for_x: ; x := s1
			blt s1, s6, inside
			jmp ra
			addi s1, s1, 1

			inside:
				addi s1, s1, 1

				addi s2, zero, -1
				addi s5, zero, 9 ; upper bound
				for_y: ; y := s2
					bge s2, s5, for_x
					addi s2, s2, 1

					srli t3, s1, 3
					add t3, t3, s2 ; t3 := i = (x * 8 + y)
			
				
					ldw t4, GSA(t3)
				
					beq t4, zero, for_y
				
					stw s1, 0(a0)
					stw s2, 0(a1)

					call set_pixel

					br for_y
	end_draw:
		ret
; END: draw_array


; BEGIN: move_snake
move_snake:
	;calculate new head position (with old head pos and the direction vector)
	;update hx and hy

	;if collision with food then jmp to food.
	
	;calculate old tail pos (with tx and ty)
	;clear old tail elem
	;calculate new tail elem (with tail dir with gsa and tx and ty)
	;update tx and ty
	
	food:

; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:

; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:

; END: restore_checkpoint


; BEGIN: blink_score
blink_score:

; END: blink_score
