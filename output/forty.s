  section .text
  extern error
  global our_code_starts_here
our_code_starts_here:
  mov [rsp - 8], rdi

  mov rax, 85
  mov [rsp + -16], rax
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -16]
  sub rax, 2
  jo near overflow_check
  mov [rsp + -16], rax
  and rax, 1
  cmp rax, 1
  jne near error_non_int
  mov rax, [rsp + -16]
  sub rax, 2
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
