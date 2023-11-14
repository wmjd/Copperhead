  section .text
  extern error
  global our_code_starts_here
our_code_starts_here:
  mov [rsp - 8], rdi

  mov rax, 199
  mov [rsp + -16], rax
  mov rax, 45
  mov [rsp + -24], rax
  mov rax, 23
  mov [rsp + -32], rax
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
