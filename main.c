#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define TRUE 0x0000000000000002L
#define FALSE 0x0000000000000000L

#define BOA_MIN (- (1L << 62))
#define BOA_MAX ((1L << 62) - 1)

extern int64_t our_code_starts_here(int64_t input_val) asm("our_code_starts_here");
extern void error(int64_t val) asm("error");

int64_t print(int64_t val) {
  // FILL IN YOUR CODE FROM HERE
  if(val & 1){
    printf("%lld\n", (val - 1) / 2);
  }
  else if(val == TRUE){
    printf("true\n");
  }
  else if(val == FALSE){
    printf("false\n");
  } else {
    printf("Improper representation: %#018llx\n", val);
  }
  return val;
}

void error(int64_t error_code) {
  // FILL IN YOUR CODE FROM HERE
  if(error_code == 1)
    fprintf(stderr, "Error: expected a number\n");
  else if (error_code == 2)
    fprintf(stderr, "Error: expected a boolean\n");
  else if (error_code == 3)
    fprintf(stderr, "Error: overflow\n");
  else if (error_code == 4)
    fprintf(stderr, "Error: input must be a boolean or a number\n");
  else if (error_code == 5)
    fprintf(stderr, "Error: input is not a representable number\n");
  exit(1);
}



int main(int argc, char** argv) {
  int64_t input_val;
  // FILL IN YOUR CODE FROM HERE
  char * endptr;
  extern int errno;

  if (argc > 1) {
    if (!strcmp("true", argv[1])) {
      input_val = TRUE;
    } else if (!strcmp("false", argv[1])) {
      input_val = FALSE;
    } else {
      endptr = (char*) &argv[1];
      long r = strtol(argv[1], &endptr, 10);
      if (*endptr != '\0') {
        error(4);
      }
      else if (r < BOA_MIN || r > BOA_MAX) {
        error(5);
      }
      input_val = (r << 1) | 1;
    }
  } else {
    input_val = FALSE;
  }

  // YOUR CODE ENDS HERE
  int64_t result = our_code_starts_here(input_val);
  print(result);
  //printf("after print before main.c rets 0\n");
  return 0;
}
