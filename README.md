# lox-starter

A starting repo for building both interpreters from [Crafting Interpreters](https://craftinginterpreters.com) by Robert Nystrom: jlox (a tree-walk interpreter in Java) and clox (a bytecode VM in C). It's set up so [cracked.guide](https://cracked.guide) can run the book's official test suite against your code on every push and tick off the chapters you pass.

There's no interpreter in here. You get an empty skeleton that compiles, a workflow, a test script and a dev container. The interesting part is yours to write.

## Get started

1. Click **Use this template** at the top of this page (or [this link](https://github.com/new?template_name=lox-starter&template_owner=danedolph)) and create your own repo. Calling it `lox` is fine.
2. **Keep it public.** GitHub Actions are free for public repos. On a private repo every push spends your own Actions minutes, and cracked.guide only reads public repos anyway.
3. Go to [cracked.guide/verify](https://cracked.guide/verify), connect GitHub if you haven't, and pick the new repo.
4. Push something. The **Actions** tab shows a `cracked.guide` run, and `/verify` shows the results.

The first runs fail. That's expected: the stub isn't a scanner yet. Once your chapter 4 code passes `chap04_scanning`, it goes green.

### Codespaces or a dev container

Don't want to install Java, a C compiler and Dart 2 yourself? Open the repo in a Codespace (**Code → Codespaces → Create codespace on main**) or in VS Code with the Dev Containers extension. The container has Temurin Java 21, gcc, make, gdb, valgrind, Dart 2.19.6 and git.

Codespaces hours come out of your own GitHub account's free monthly allowance, so stop the codespace when you're done for the day (it stops itself after a while idle too).

## Layout

```
jlox/src/com/craftinginterpreters/lox/Lox.java   jlox entry point (a stub for now)
jlox/src/com/craftinginterpreters/tool/          GenerateAst.java goes here in chapter 5
clox/main.c                                      clox entry point (a stub for now)
clox/Makefile                                    builds every .c in clox/ into clox/build/clox
scripts/test.sh                                  runs the official tests locally
.github/workflows/cracked.yml                    runs them on GitHub and reports to cracked.guide
.cracked.json                                    tells the workflow how far to test
.devcontainer/                                   Java 21, C, Dart 2.19 for Codespaces / VS Code
```

This is the book's own layout, so the code in each chapter drops straight in. Add new `.java` files next to `Lox.java` and new `.c`/`.h` files next to `main.c`.

## Build and run

jlox:

```sh
javac -d build/jlox-classes $(find jlox -name '*.java')
java -cp build/jlox-classes com.craftinginterpreters.lox.Lox            # REPL
java -cp build/jlox-classes com.craftinginterpreters.lox.Lox hello.lox  # run a file
```

clox:

```sh
make -C clox              # builds clox/build/clox
clox/build/clox hello.lox
make -C clox debug        # clox/build/clox-debug with AddressSanitizer and UBSan
```

Use the debug build while you work on clox. It catches the memory bugs that otherwise show up three chapters later as something weird.

## Run the official tests locally

```sh
scripts/test.sh chap04_scanning      # one chapter's suite
scripts/test.sh chap17_compiling     # chap14 and up run clox
scripts/test.sh jlox                 # everything for a finished jlox
```

The first run clones [munificent/craftinginterpreters](https://github.com/munificent/craftinginterpreters) into `.craftinginterpreters/` (gitignored), fetches the test runner's packages, builds your interpreter and runs `dart tool/bin/test.dart <suite> --interpreter <yours>`. It does the same things the workflow does: unsets `JAVA_TOOL_OPTIONS` (the JVM prints a notice on stderr that the tests count as an error), runs under a UTF-8 locale and gives each test 10 seconds.

The test runner needs **Dart 2**, not Dart 3 (`tool/pubspec.yaml` says `<3.0.0`). The dev container has it. To install 2.19.6 yourself, download the SDK zip for your platform and put its `bin/` on your `PATH`:

```sh
# Linux x64. On macOS swap in dartsdk-macos-arm64-release.zip (Apple silicon) or dartsdk-macos-x64-release.zip.
curl -fLO https://storage.googleapis.com/dart-archive/channels/stable/release/2.19.6/sdk/dartsdk-linux-x64-release.zip
unzip dartsdk-linux-x64-release.zip -d ~/.local
export PATH="$HOME/.local/dart-sdk/bin:$PATH"   # add this to your shell profile
dart --version                                   # Dart SDK version: 2.19.6
```

On Windows, use WSL and the Linux steps.

A heads-up on the early suites: `chap04_scanning` and `chap06_parsing` expect the debug output those chapters print (tokens, an AST). Once you move on and your jlox stops printing them, they fail, and that's fine. Later suites cover the earlier chapters.

## How verification works

On every push, `.github/workflows/cracked.yml`:

1. checks out your repo and the book's repo,
2. builds jlox (every `.java` under `jlox/`, running `GenerateAst` first if `Expr.java` isn't committed) and clox (every `.c` next to `clox/main.c`),
3. runs the suites from your furthest chapter backwards until one passes (a later suite covers the earlier chapters),
4. posts the results to cracked.guide with a short-lived token GitHub signs for your repo. No secrets to set up. cracked.guide checks the token names the repo you connected.

`.cracked.json` controls it:

```json
{
  "jlox_through": 13,
  "clox_through": 30
}
```

Those are the defaults: test everything. Lower them to the chapter you're on (say `"jlox_through": 7`) and each push skips the later suites, which makes runs faster. Other keys, if you change the layout: `"build"` (a command to run first, like `"make -C clox"`), `"jlox"` and `"clox"` (paths to anything that runs a `.lox` file given as its only argument). See [cracked.guide/verify](https://cracked.guide/verify).

Don't edit `cracked.yml` by hand; if cracked.guide updates it, grab the new one from [cracked.guide/verify/workflow.yml](https://cracked.guide/verify/workflow.yml).

## Guides

- [Week 0: setup](https://cracked.guide/curriculum/week-0)
- [The curriculum](https://cracked.guide/curriculum), with a guide for every chapter
- [Verify](https://cracked.guide/verify)
- [Crafting Interpreters](https://craftinginterpreters.com), free to read online

## Credit and license

Crafting Interpreters is by Robert Nystrom, free online at [craftinginterpreters.com](https://craftinginterpreters.com). The tests the workflow runs live in [his repo](https://github.com/munificent/craftinginterpreters) and are fetched at run time. This template contains none of the book's prose or code, only an empty skeleton.

The skeleton is MIT licensed (see `LICENSE`). It's your repo now: change the copyright line to your name, or swap the license for whatever you like.
