  section .text
  extern error
  global our_code_starts_here
our_code_starts_here:
  mov [rsp - 8], rdi

  mov rax, -83
  mov [rsp + -16], rax
  mov rax, 21
  mov [rsp + -24], rax
  and rax, [rsp + -16]
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -16]
  and rax, 0xfffffffffffffffe
  add rax, [rsp + -24]
  jo near overflow_check
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
