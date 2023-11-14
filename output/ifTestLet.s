  section .text
  extern error
  global our_code_starts_here
our_code_starts_here:
  mov [rsp - 8], rdi

  mov rax, 11
  mov [rsp + -16], rax
  mov rax, [rsp + -16]
  mov [rsp + -24], rax
  mov rax, 15
  cmp rax, [rsp + -32]
  jne near temp_not_equal_1
  mov rax, 0x2
  jmp near temp_end_2
temp_not_equal_1:
  mov rax, 0
temp_end_2:
  mov [rsp + -24], rax
  and rax, 1
  cmp rax, 0
  jne near error_non_bool
  mov rax, [rsp + -24]
  cmp rax, 0x2
  jne near temp_else_3
  mov rax, 15
  jmp near temp_end_if_4
temp_else_3:
  mov rax, 17
temp_end_if_4:
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
