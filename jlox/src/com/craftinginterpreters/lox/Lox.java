package com.craftinginterpreters.lox;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

// Placeholder entry point so the project compiles from day one.
// Replace all of this as you work through chapter 4 (Scanning).
public class Lox {
  public static void main(String[] args) throws IOException {
    switch (args.length) {
      case 0 -> prompt();
      case 1 -> script(args[0]);
      default -> {
        System.err.println("usage: jlox [script.lox]");
        System.exit(64);
      }
    }
  }

  private static void script(String file) throws IOException {
    String source = Files.readString(Path.of(file), StandardCharsets.UTF_8);
    System.err.println("TODO: interpret " + file + " (" + source.length() + " chars). Nothing is written yet.");
    System.exit(70);
  }

  private static void prompt() throws IOException {
    BufferedReader in = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
    System.out.println("jlox REPL placeholder. Ctrl-D to quit.");
    while (true) {
      System.out.print("> ");
      System.out.flush();
      String line = in.readLine();
      if (line == null) {
        System.out.println();
        break;
      }
      System.out.println("TODO: evaluate `" + line + "`");
    }
  }
}
