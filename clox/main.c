// Placeholder entry point so clox builds from day one.
// Replace it when you reach chapter 14 (Chunks of Bytecode).
#include <stdio.h>

int main(int argc, char* argv[]) {
  if (argc == 2) {
    fprintf(stderr, "TODO: run %s. Nothing is written yet.\n", argv[1]);
    return 70;
  }
  fprintf(stderr, "usage: clox [script.lox]\n");
  return 64;
}
