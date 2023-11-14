  section .text
  extern error
  global our_code_starts_here
our_code_starts_here:
  mov [rsp - 8], rdi

  mov rax, 3
  and rax, 1
  shl rax, 1
  mov [rsp + -16], rax
  and rax, 1
  cmp rax, 0
  jne near error_non_bool
  mov rax, [rsp + -16]
  cmp rax, 0x2
  jne near temp_else_9
  mov rax, 3
  jmp near temp_end_if_10
temp_else_9:
  mov rax, 5
temp_end_if_10:
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
