  section .text
  extern error
  global our_code_starts_here
our_code_starts_here:
  mov [rsp - 8], rdi

  mov rax, 1
  mov [rsp + -16], rax
  mov rax, 3
  mov [rsp + -24], rax
temp_loop_pred_15:
  mov rax, [rsp + -8]
  mov [rsp + -32], rax
  mov rax, 1
  mov [rsp + -40], rax
  and rax, [rsp + -32]
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -32]
  cmp rax, [rsp + -40]
  jg near temp_greater_13
  mov rax, 0
  jmp near temp_end_14
temp_greater_13:
  mov rax, 0x2
temp_end_14:
  mov [rsp + -32], rax
  and rax, 1
  cmp rax, 0
  jne near error_non_bool
  mov rax, [rsp + -32]
  cmp rax, 0x2
  jne near temp_after_loop_16
  mov rax, [rsp + -8]
  mov [rsp + -32], rax
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -32]
  sub rax, 2
  jo near overflow_check
  mov [rsp + -8], rax
  mov rax, [rsp + -16]
  mov [rsp + -32], rax
  mov rax, [rsp + -24]
  mov [rsp + -16], rax
  mov rax, [rsp + -24]
  mov [rsp + -40], rax
  mov rax, [rsp + -32]
  mov [rsp + -48], rax
  and rax, [rsp + -40]
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -40]
  and rax, 0xfffffffffffffffe
  add rax, [rsp + -48]
  jo near overflow_check
  mov [rsp + -24], rax
  jmp near temp_loop_pred_15
temp_after_loop_16:
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
