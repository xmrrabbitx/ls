format ELF64 executable

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
currPass:
	
	call get_currentDir

	mov rax, 2
	mov rdi, currentDir
	mov rsi, 0
	mov rdx, 0
	syscall
	mov [fd], rax
	jmp pass3

dirPass:
	mov rax, 2
	mov rdi, pathDir
	mov rsi, 0
	mov rdx, 0
	syscall
	mov [fd], rax
	jmp pass3

pass3:
	mov rax, 217
	mov rdi, [fd]
	mov rsi, buffer
	mov rdx, $-buffer
	syscall

    	mov rbx, buffer      
	add rbx, 18
 
 	xor rcx, rcx
	 

find_null:
 
	cmp byte [rbx+rcx], 0                
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
	mov rax, 1
	mov rdi, 1
	mov rsi, rbx
	mov rdx, rcx
	syscall

	mov rax,1
	mov rdi,1
	mov rsi,del
	mov rdx,1
	syscall

next_entry:

	movzx rax, word [rbx - 2]
	add rbx, rax
	
	cmp byte [rbx], 0
	je exit

	xor rcx,rcx	
	
	jmp find_null
	
exit:	

	mov rax,60
	xor rdi, rdi
	syscall

segment readable writeable
del db 0xa, 0
;;mssg db "exited!",0
dotMsg db "dots detected!",0
ascii_digit db 0, 0xA
pathDir db 256 dup(?)
