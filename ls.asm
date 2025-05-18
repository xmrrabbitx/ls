format ELF64 executable

SYS_GETDENT = 217

fd dq 0
buffer rb 1024

;;include necessary file
include "./helper/helper.asm"

macro paramsCheck 
        
	pop rcx ; rcx = 2, rsp += 8        
	pop rsi ; rdi = argv[0], rsp += 8 (discard program name)
	pop rsi ; rdi = argv[1], rsp += 8 (now points to NULL)
	
	cmp rsi, 0 ;; check on NULL value
	je currPass 	

	;;cmp rsi, "-"
	;;jne pass2

	mov rdi, pathDir
        mov rcx, 256
        rep movsb ;; Copy until null terminator or RCX=0
	jmp dirPass	

end macro

segment readable executable
entry main
main:

	paramsCheck ;; check if params existed!

;; list current dir _ no options
currPass:
	
	call get_currentDir

	mov rax, 2
	mov rdi, currentDir
	mov rsi, 0
	mov rdx, 0
	syscall
	mov [fd], rax
	jmp pass

;; list specific dir 
dirPass:

	mov rax, 2
	mov rdi, pathDir
	mov rsi, 0
	mov rdx, 0
	syscall
	mov [fd], rax
	jmp pass

;; create getdent buffer
pass:
	;; getdent syscall 
	mov rax, SYS_GETDENT
	mov rdi, [fd]
	mov rsi, buffer
	mov rdx, $-buffer
	syscall

	mov rbx, buffer 

loop_entry:
	cmp byte [rbx+18],4
	jne not_dir

	mov rax, 1
	mov rdi, 1
	mov rsi, color_blue
	mov rdx, 5
	syscall
	
not_dir:
 	lea rbx, [rbx+18]
	xor rcx, rcx

find_null:
	cmp byte [rbx + rcx], 0                
	je init_entry

	inc rcx  
        jmp find_null 

check_singleDot:
	cmp byte [rbx+1], '.'
	je next_entry
	jmp print_entry
check_doubleDots:
	cmp byte [rbx+2], '.'
	je next_entry
	jmp print_entry 

init_entry:
	
	push rcx
	mov [ascii_digit], cl   

	add byte [ascii_digit], '0' ;; convert to ASCI 

    	push rdi
	push rsi
	push rdx

	;mov rax, 1       
    	;mov rdi, 1         
    	;mov rsi, ascii_digit   
    	;mov rdx, 2        
    	;syscall 
	
	pop rdi
	pop rsi
	pop rdx
	pop rcx

	cmp rcx, 2
	je check_singleDot	
	
	cmp rcx, 3
	je check_doubleDots

print_entry:
	
	;; print directory entries	
	mov rax, 1
	mov rdi, 1
	mov rsi, rbx
	mov rdx, rcx
	syscall

	mov rax,1
	mov rdi,1
	mov rsi,space
	mov rdx,4
	syscall

next_entry:
	
	movzx rax, word [rbx - 2] ;; access to d_reclen value and store in rax
	add rbx, rax ;; add d_reclen to rbx 
	sub rbx, 18
	
	;; check if entries end	
	cmp byte [rbx], 0
	je exit

	mov rax, 1
	mov rdi, 1
	mov rsi, color_reset
	mov rdx, 5
	
	syscall
	xor rcx,rcx	
	
	;;jmp find_null
	jmp loop_entry

exit:	
	;; new line at the end of entries	
	mov rax,1
	mov rdi,1
	mov rsi,newLine
	mov rdx,1
	syscall
	
	mov rax,60
	xor rdi, rdi
	syscall

segment readable writeable
space db '    ' ;;4 chars space
newLine db 0xa, 0 ;; new line
ascii_digit db 0,0xA
pathDir db 256 dup(?)

;; https://en.wikipedia.org/wiki/ANSI_escape_code
color_blue db 0x1B, '[94m', 0 ;; bright blue ANSI escaped code 

color_reset db 0x1B, '[0m', 0
