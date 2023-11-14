  section .text
  extern error
  global our_code_starts_here
our_code_starts_here:
  mov [rsp - 8], rdi

  mov rax, 5
  mov [rsp + -16], rax
  mov rax, 3
  mov [rsp + -24], rax
  and rax, [rsp + -16]
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -16]
  cmp rax, [rsp + -24]
  jg near temp_greater_9
  mov rax, 0
  jmp near temp_end_10
temp_greater_9:
  mov rax, 0x2
temp_end_10:
  ret
overflow_check:
  mov rdi, 3
  call error
error_non_int:
  mov rdi, 1
  call error
error_non_bool:
  mov rdi, 2
  call error
