  section .text
  extern error
  global our_code_starts_here
our_code_starts_here:
  mov [rsp - 8], rdi

  mov rax, 21
  mov [rsp + -16], rax
  mov rax, 1
  mov [rsp + -24], rax
temp_loop_pred_7:
  mov rax, [rsp + -16]
  mov [rsp + -32], rax
  mov rax, [rsp + -24]
  mov [rsp + -40], rax
  and rax, [rsp + -32]
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -32]
  cmp rax, [rsp + -40]
  jg near temp_greater_5
  mov rax, 0
  jmp near temp_end_6
temp_greater_5:
  mov rax, 0x2
temp_end_6:
  mov [rsp + -32], rax
  and rax, 1
  cmp rax, 0
  jne near error_non_bool
  mov rax, [rsp + -32]
  cmp rax, 0x2
  jne near temp_after_loop_8
  mov rax, [rsp + -24]
  mov [rsp + -32], rax
  mov rax, 3
  mov [rsp + -40], rax
  and rax, [rsp + -32]
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -32]
  and rax, 0xfffffffffffffffe
  add rax, [rsp + -40]
  jo near overflow_check
  mov [rsp + -24], rax
  jmp near temp_loop_pred_7
temp_after_loop_8:
  mov rax, [rsp + -24]
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