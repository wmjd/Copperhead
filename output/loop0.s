  section .text
  extern error
  global our_code_starts_here
our_code_starts_here:
  mov [rsp - 8], rdi

  mov rax, 1
  mov [rsp + -16], rax
temp_loop_pred_23:
  mov rax, [rsp + -16]
  mov [rsp + -24], rax
  mov rax, 85
  mov [rsp + -32], rax
  and rax, [rsp + -24]
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -24]
  cmp rax, [rsp + -32]
  jg near temp_greater_21
  mov rax, 0
  jmp near temp_end_22
temp_greater_21:
  mov rax, 0x2
temp_end_22:
  mov [rsp + -24], rax
  and rax, 1
  cmp rax, 0
  jne near error_non_bool
  mov rax, [rsp + -24]
  cmp rax, 0x2
  jne near temp_after_loop_24
  mov rax, [rsp + -16]
  mov [rsp + -24], rax
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -24]
  add rax, 2
  jo near overflow_check
  mov [rsp + -16], rax
  jmp near temp_loop_pred_23
temp_after_loop_24:
  mov rax, [rsp + -16]
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
