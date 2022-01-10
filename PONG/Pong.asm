STACK SEGMENT PARA STACK        	;PARA is used to set boundary as paragraph.
    DB 64 DUP (' ')             	;DUP is used as duplicate the stack space as 64 bytes spaces. 
STACK ENDS


DATA SEGMENT PARA 'DATA'        	;'DATA' is used as class here.
    
	WINDOW_WIDTH DW 140H			;the width of the window screen i.e 320 pixels changed into hexa (140)
	WINDOW_HEIGHT DW 0C8H			; the height of the window screen i.e 200 pixels in hexa
	WINDOW_BOUNDS DW 6				;variable used to check collisions to walls early
	
    TIME_AUX DB 0               	;Variable used to check if time has changed
    
	TEXT_PLAYER_ONE_POINTS DB '0','$'		;text with player one points
	TEXT_PLAYER_TWO_POINTS DB '0','$'		;text with player two points
	
    BALL_ORIGINAL_X DW 0A0H
	BALL_ORIGINAL_Y DW 64H
	
	BALL_X DW 0A0H               	;X position (column) of ball
    BALL_Y DW 64H               	;X position (column) of ball
    BALL_SIZE DW 04H            	;size of the ball(pixels in width and height)
    
	BALL_VELOCITY_X DW 05H			; horizontal velocity of ball
	BALL_VELOCITY_Y DW 02H			; vertical velocity of ball
	
	PADDLE_LEFT_X DW 0AH
	PADDLE_LEFT_Y DW 0AH
	
	PLAYER_ONE_POINTS DB 0			;player one points
	PLAYER_TWO_POINTS DB 0		;PLAYER TWO POINTS
	
	PADDLE_RIGHT_X DW 130H
	PADDLE_RIGHT_Y DW 0AH
	
	PADDLE_WIDTH DW 05H
	PADDLE_HEIGHT DW 1FH
	
	PADDLE_VELOCITY DW 05H
	
DATA ENDS


CODE SEGMENT PARA 'CODE'       		;'CODE' is used as class here
    
    MAIN PROC FAR               	;FAR is used as main proc is in a different code segment
        
    ASSUME CS:CODE,DS:DATA,SS:STACK         ;Assume segments as respective registers    
        
    PUSH DS                         ;push DS segment to stack
    SUB AX,AX                       ;clean AX register by subtracting
    PUSH AX                         ;push AX to stack    
    
    MOV AX,DATA                     ;save contents of DATA in AX
    MOV DS,AX                       ;save contents of AX in DS
    
    POP AX                          ;release the top item from stack to AX
    POP AX                          ;release the top item from stack to AX
           
		CALL CLEAR_SCREEN
		
        CHECK_TIME: 
            MOV AH,2CH              			;get the TIME of the system to use for changing the frames to move the ball
            INT 21H                 			;CH = hour CL = minute DH = second DL = 1/100 seconds
			;we use time(DL) for changing frames(DL to change one frame in 100th of second) to move ball 
            ;compare the system time with TIME_AUX
            CMP DL,TIME_AUX
            JE CHECK_TIME           			;if time is same then check again
            
            ;if the time is different then draw, and move
            
            MOV TIME_AUX,DL         			;update time
			
			CALL CLEAR_SCREEN					;frame changed 
			
			CALL MOVE_BALL 						;new position of ball
			CALL DRAW_BALL          			;calling DRAW_BALL proc
            
			CALL MOVE_PADDLES		
			CALL DRAW_PADDLE
			
			CALL DRAW_UI 						;draw game user interface
			
            JMP CHECK_TIME          ;			after everything check time agian                                                                                     
        RET
    MAIN ENDP
     
	MOVE_BALL PROC NEAR
	
		MOV AX,BALL_VELOCITY_X
		ADD BALL_X,AX							;moving ball with X-axis
		
		MOV AX,WINDOW_BOUNDS
		CMP BALL_X,AX							;BALL_X < WINDOW_BOUNDS (Yes -> collided with left boundary)
		JL GIVE_POINT_TO_PLAYER_TWO				;if it is less,give one point to player TWO and reset ball position
		
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX							;BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS (Yes -> collided with right boundary)		
		JG GIVE_POINT_TO_PLAYER_ONE				;if it is greater ,give one point to player ONE and reset ball position  
		JMP MOVE_BALL_VERTICALLY
		
		GIVE_POINT_TO_PLAYER_ONE:
			INC PLAYER_ONE_POINTS				;increament player one points
			CALL RESET_BALL_POSITION			;reset the bal position to the center of the screen
			
			CALL UPDATE_TEXT_PLAYER_ONE_POINTS		;update of text of player one points
			
			CMP PLAYER_ONE_POINTS,05H			;check if this player one has reached 5 points
			JGE GAME_OVER						;if this player points is 5 or more, the game is over
			RET
		
		GIVE_POINT_TO_PLAYER_TWO:
			INC PLAYER_TWO_POINTS				;increament player two points
			CALL RESET_BALL_POSITION			;reset the bal position to the center of the screen
			
			CALL UPDATE_TEXT_PLAYER_TWO_POINTS		;update of text of player two points
			
			CMP PLAYER_TWO_POINTS,05H			;check if this player two has reached 5 points
			JGE GAME_OVER						;if this player points is 5 or more, the game is over
		
			RET
		
		GAME_OVER:								;if someone has reached 5 points restart the game
			MOV PLAYER_ONE_POINTS,00H			;restart player one's points
			MOV PLAYER_TWO_POINTS,00H			;restart player two's points
			CALL UPDATE_TEXT_PLAYER_ONE_POINTS
			CALL UPDATE_TEXT_PLAYER_TWO_POINTS
			RET
		
		
		MOVE_BALL_VERTICALLY:
			MOV AX,BALL_VELOCITY_Y
			ADD BALL_Y,AX						;moving ball with Y-axis
		
			MOV AX,WINDOW_BOUNDS
			CMP BALL_Y,AX							;BALL_Y < WINDOW_BOUNDS (Yes -> collided with top boundary)
			JL NEG_VELOCITY_Y						;ball collided with top boundary and reversed the velocity of ball
			
			MOV AX,WINDOW_HEIGHT
			SUB AX, BALL_SIZE
			SUB AX,WINDOW_BOUNDS
			CMP BALL_Y,AX							;BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS (Yes -> collided with bottom boundary)
			JG NEG_VELOCITY_Y						;ball collided with bottom boundary and reversed the velocity of ball
		
		;check if the ball is colliding with the right paddle
			;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
			
				;(BALL_X + BALL_SIZE > PADDLE_RIGHT_X) && (BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH) 
				;&& (BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y) && (BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT) 
				
				MOV AX,BALL_X
				ADD AX,BALL_SIZE
				CMP AX,PADDLE_RIGHT_X							;(BALL_X + BALL_SIZE > PADDLE_RIGHT_X)
				JNG CHECK_COLLISION_WITH_LEFT_PADDELE			;if there's no collisions check for left paddle collisions
				
				MOV AX,PADDLE_RIGHT_X
				ADD AX,PADDLE_WIDTH
				CMP BALL_X,AX									;(BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH)
				JNL CHECK_COLLISION_WITH_LEFT_PADDELE			;if there's no collisions check for left paddle collisions
				
				MOV AX,BALL_Y
				ADD AX,BALL_SIZE
				CMP AX,PADDLE_RIGHT_Y							;(BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y)
				JNG CHECK_COLLISION_WITH_LEFT_PADDELE
				
				MOV AX,PADDLE_RIGHT_Y
				ADD AX,PADDLE_HEIGHT
				CMP BALL_Y,AX									;(BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT)
				JNL CHECK_COLLISION_WITH_LEFT_PADDELE
				
				;if it reaches this point,the ball is colliding with the right paddle
				JMP NEG_VELOCITY_X
			
		;check if the ball is colliding with the left paddle
		CHECK_COLLISION_WITH_LEFT_PADDELE:
			;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
					
			;(BALL_X + BALL_SIZE > PADDLE_LEFT_X) && (BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH) 
			;&& (BALL_Y + BALL_SIZE > PADDLE_LEFT_Y) && (BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT) 
		
			MOV AX,BALL_X
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_LEFT_X								;(BALL_X + BALL_SIZE > PADDLE_LEFT_X)
			JNG EXIT_COLLISIONS_CHECK
			
			MOV AX,PADDLE_LEFT_X
			ADD AX,PADDLE_WIDTH
			CMP BALL_X,AX										;(BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH)
			JNL EXIT_COLLISIONS_CHECK
			
			MOV AX,BALL_Y
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_LEFT_Y								;(BALL_Y + BALL_SIZE > PADDLE_LEFT_Y)
			JNG EXIT_COLLISIONS_CHECK
			
			MOV AX,PADDLE_LEFT_Y
			ADD AX,PADDLE_HEIGHT
			CMP AX,BALL_Y										;(BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT) 
			JNL EXIT_COLLISIONS_CHECK
			
			;if it reaches this point,the ball is colliding with the left paddle
			JMP NEG_VELOCITY_X

			NEG_VELOCITY_Y:
				NEG BALL_VELOCITY_Y				;				negation of BALL_VELOCITY_Y
				RET
		
			NEG_VELOCITY_X:
				NEG BALL_VELOCITY_X								;reverse the horizontal velocity of ball
				RET												;exit this procedure (because there's no collision with right paddle)
		
			EXIT_COLLISIONS_CHECK:
				RET
		

	MOVE_BALL ENDP 
	
	MOVE_PADDLES PROC NEAR
		
		;LEFT PADDLE MOVEMENT:
			
			;check if any key is pressed (if not check the other paddle)
			MOV AH,01H
			INT 16H
			JZ CHECK_RIGHT_PADDLE_MOVEMENT						;ZF=1, if ZF is zero then jump
			
			;check which key is being pressed (AL = ASCII character)
			MOV AH,00H
			INT 16H
			
			;if it is 'w' or 'W' move up
			CMP AL,77H								;77H is w
			JE MOVE_LEFT_PADDLE_UP
			CMP AL,57H								;57H is W
			JE MOVE_LEFT_PADDLE_UP

			;if it is 's' or 'S' move down
			CMP AL,73H								;77H is s
			JE MOVE_LEFT_PADDLE_DOWN
			CMP AL,53H								;57H is S
			JE MOVE_LEFT_PADDLE_DOWN
			JMP CHECK_RIGHT_PADDLE_MOVEMENT

			MOVE_LEFT_PADDLE_UP:
				MOV AX,PADDLE_VELOCITY
				SUB PADDLE_LEFT_Y,AX
				
				MOV AX,WINDOW_BOUNDS
				CMP PADDLE_LEFT_Y,AX
				JL FIX_PADDLE_LEFT_TOP_POSITION
				JMP CHECK_RIGHT_PADDLE_MOVEMENT

				FIX_PADDLE_LEFT_TOP_POSITION:
					MOV AX,WINDOW_BOUNDS
					MOV PADDLE_LEFT_Y,AX
					JMP CHECK_RIGHT_PADDLE_MOVEMENT

			MOVE_LEFT_PADDLE_DOWN:
				MOV AX,PADDLE_VELOCITY
				ADD PADDLE_LEFT_Y,AX
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDS
				SUB AX,PADDLE_HEIGHT
				CMP PADDLE_LEFT_Y,AX
				JG FIX_PADDLE_LEFT_BOTTOM_POSITION			
				JMP CHECK_RIGHT_PADDLE_MOVEMENT

				FIX_PADDLE_LEFT_BOTTOM_POSITION:
					MOV PADDLE_LEFT_Y,AX
					JMP CHECK_RIGHT_PADDLE_MOVEMENT

		
		;RIGHT PADDLE MOVEMENT:
		CHECK_RIGHT_PADDLE_MOVEMENT:
		
			;if it is 'o' or 'O' move up
			CMP AL,6FH								;6FH is o
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL,4FH								;4FH is O
			JE MOVE_RIGHT_PADDLE_UP
			;if it is 'l' or 'L' move down
			CMP AL,6CH								;6CH is l
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL,4CH								;4CH is L
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
		
			MOVE_RIGHT_PADDLE_UP:
				MOV AX,PADDLE_VELOCITY
				SUB PADDLE_RIGHT_Y,AX
				
				MOV AX,WINDOW_BOUNDS
				CMP PADDLE_RIGHT_Y,AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				JMP EXIT_PADDLE_MOVEMENT

				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV AX,WINDOW_BOUNDS
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_DOWN:
				MOV AX,PADDLE_VELOCITY
				ADD PADDLE_RIGHT_Y,AX
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDS
				SUB AX,PADDLE_HEIGHT
				CMP PADDLE_RIGHT_Y,AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION			
				JMP EXIT_PADDLE_MOVEMENT

				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
			
		EXIT_PADDLE_MOVEMENT:
			
			RET
	
	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR
		
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX				;BALL_ORIGINAL_X position is moved to BALL_X
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX				;BALL_ORIGINAL_Y position is moved to BALL_Y
		
		RET
	RESET_BALL_POSITION ENDP
	 
    DRAW_BALL PROC NEAR
        
        MOV CX,BALL_X               ;set the initial colums of X as VARIABLE
        MOV DX,BALL_Y               ;set the intial line of Y as VARIABLE                                                                                   
        
        DRAW_BALL_HORIZONTAL:
        
            MOV AH,0CH              ;setting up configuration of writing pixel
            MOV AL,0FH              ;pixel color as white
            MOV BH,00H              ;SET THE PAGE NUMBER
            INT 10H                 ;execution
            
			INC CX                  ;CX = CX + 1
            ;CX -BALL_X > BALL_SIZE (Yes -> go to next line  No -> go to next column)
            MOV AX,CX
            SUB AX,BALL_X
            CMP AX,BALL_SIZE
            JNG DRAW_BALL_HORIZONTAL    ;JNG is jump not greater
           
            MOV CX,BALL_X           ;CX go back to initial column
            INC DX                  ;we advance one line
           
            ;DX - BALL_Y >BALL_SIZE (Yes -> exit the procedure  No -> continue to next line)
           
            MOV AX,DX
            SUB AX,BALL_Y
            CMP AX,BALL_SIZE
            JNG DRAW_BALL_HORIZONTAL
            
		RET
    DRAW_BALL ENDP
	
	DRAW_PADDLE PROC NEAR
		MOV CX,PADDLE_LEFT_X               ;set the initial colums of X as VARIABLE
        MOV DX,PADDLE_LEFT_Y               ;set the intial line of Y as VARIABLE       
		
		DRAW_PADDLE_LEFT_HORIZONTAL:
			MOV AH,0CH              ;setting up configuration of writing pixel
			MOV AL,0FH              ;pixel color as white
			MOV BH,00H              ;SET THE PAGE NUMBER
			INT 10H                 ;execution
		
			INC CX                  ;CX = CX + 1
            ;CX -PADDLE_LEFT_X > PADDLE_WIDTH (Yes -> go to next line  No -> go to next column)
            MOV AX,CX
            SUB AX,PADDLE_LEFT_X
            CMP AX,PADDLE_WIDTH
            JNG DRAW_PADDLE_LEFT_HORIZONTAL		  ;JNG is jump not greater
			
			
			MOV CX,PADDLE_LEFT_X           ;CX go back to initial column
            INC DX                  ;we advance one line
           
            ;DX - PADDLE_LEFT_Y > PADDLE_HEIGHT (Yes -> exit the procedure  No -> continue to next line)
           
            MOV AX,DX
            SUB AX,PADDLE_LEFT_Y
            CMP AX,PADDLE_HEIGHT
            JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			
			
		MOV CX,PADDLE_RIGHT_X               ;set the initial colums of X as VARIABLE
        MOV DX,PADDLE_RIGHT_Y               ;set the intial line of Y as VARIABLE       
		
		DRAW_PADDLE_RIGHT_HORIZONTAL:
			MOV AH,0CH              ;setting up configuration of writing pixel
			MOV AL,0FH              ;pixel color as white
			MOV BH,00H              ;SET THE PAGE NUMBER
			INT 10H                 ;execution
		
			INC CX                  ;CX = CX + 1
            ;CX - PADDLE_RIGHT_X > PADDLE_WIDTH (Yes -> go to next line  No -> go to next column)
            MOV AX,CX
            SUB AX,PADDLE_RIGHT_X
            CMP AX,PADDLE_WIDTH
            JNG DRAW_PADDLE_RIGHT_HORIZONTAL		  ;JNG is jump not greater
			
			
			MOV CX,PADDLE_RIGHT_X           ;CX go back to initial column
            INC DX                 			 ;we advance one line
           
            ;DX - PADDLE_RIGHT_Y > PADDLE_HEIGHT (Yes -> exit the procedure  No -> continue to next line)
           
            MOV AX,DX
            SUB AX,PADDLE_RIGHT_Y
            CMP AX,PADDLE_HEIGHT
            JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
			
			
		RET
	DRAW_PADDLE ENDP
	
	DRAW_UI PROC NEAR
		
		;draw the points of lest player (player one)
		MOV AH,02H						;set cursor position
		MOV BH,00H						;set page number
		MOV DH,04H						;set row
		MOV DL,06H						;set column
		INT 10H							;execution 
		
		MOV AH,09H						;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_PLAYER_ONE_POINTS	;give DX a pointer to the string TEXT_PLAYER_ONE_POINTS 
		INT 21H							;print the string
		
		;draw the points    of right player (player two)
		
		MOV AH,02H						;set cursor position
		MOV BH,00H						;set page number
		MOV DH,04H						;set row
		MOV DL,1FH						;set column
		INT 10H							;execution 
		
		MOV AH,09H						;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_PLAYER_TWO_POINTS	;give DX a pointer to the string TEXT_PLAYER_ONE_POINTS 
		INT 21H							;print the string
		
		RET
	DRAW_UI ENDP
	
	UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
	
		XOR AX,AX
		MOV AL,PLAYER_ONE_POINTS			;given player one points
		;now before printing on screen, we need to convert decimal to ascii
		;we can do this by adding 30h and by subracting 30h
		ADD AL,30H							
		MOV [TEXT_PLAYER_ONE_POINTS],AL
		
	RET
	UPDATE_TEXT_PLAYER_ONE_POINTS ENDP
	
	UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
	
		XOR AX,AX
		MOV AL,PLAYER_TWO_POINTS			;given player two points
		;now before printing on screen, we need to convert decimal to ascii
		;we can do this by adding 30h and by subracting 30h
		ADD AL,30H							;AL = 2
		MOV [TEXT_PLAYER_TWO_POINTS],AL
		
		
	RET
	UPDATE_TEXT_PLAYER_TWO_POINTS ENDP
	
	CLEAR_SCREEN PROC NEAR
		MOV AH,00H                  ;AH=00H is funtion to set video mode
        MOV AL,13H                  ;AL=13H is used to choose the video mode as 256 color graphics
        INT 10H                     ;10H is used for execute video mode using BIOS interrupt call
        
        MOV AH,0BH               
        MOV BH,00H                  ;AH=0BH and BH=00H is to set background
        MOV BL,00H                  ;BL=00H is for choosing black as background color
        INT 10H                     ;EXECUTION
		RET
	CLEAR_SCREEN ENDP
     
CODE ENDS
END