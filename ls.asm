format ELF64 executable

SYS_GETDENT = 217
SYS_OPEN = 2

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

macro openDir path
	
	mov rax, SYS_OPEN
	mov rdi, path
	mov rsi, 0
	mov rdx, 0
	syscall
end macro 

segment readable executable
entry main
main:

	paramsCheck ;; check if params existed!

;; list current dir _ no options
currPass:
	
	call get_currentDir

	openDir currentDir ;; open current path dir
	mov [fd], rax
	jmp getdent

;; list specific dir 
dirPass:

	openDir pathDir ;; open path dir
	
	mov [fd], rax
	jmp getdent

;; create getdent buffer
getdent:
	;; getdent syscall 
	mov rax, SYS_GETDENT
	mov rdi, [fd]
	mov rsi, buffer
	mov rdx, $-buffer
	syscall

	mov rbx, buffer 

file_type:
		
	;; check if file is a regular file
	;cmp byte [rbx+18],8
	;je set_green

	;; check if file is directory (first byte is type)
	cmp byte [rbx+18],4
	je set_blue
	
	jmp d_name	

set_blue:
	
	mov rax, 1
	mov rdi, 1
	mov rsi, color_blue
	mov rdx, 5
	syscall
	
	jmp d_name

set_green:
	
	mov rax, 1
	mov rdi, 1
	mov rsi, color_green
	mov rdx, 5
	syscall

	jmp d_name	

d_name:
 	lea rbx, [rbx+18] ;; point to begining offset of d_name
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
	
	push rbx ;; reserve initial address value
	add rbx, 1 ;; forward 1 byte to pass type and reach to d_name
	;; example: \n.local or \4.git _ \n and \4 is 1 byte type and rest of
	;; it is d_name bytes	

	;; print directory entries	
	mov rax, 1
	mov rdi, 1
	mov rsi, rbx
	mov rdx, rcx
	syscall

	pop rbx ;; get back to initial address value

	;; add space to each entries
	mov rax, 1
	mov rdi, 1
	mov rsi, space
	mov rdx, 4
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
	
	jmp file_type

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
color_green db 0x1B, '[32m',0 ;; green ANSI
color_reset db 0x1B, '[0m', 0
