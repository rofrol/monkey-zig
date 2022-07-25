# monkey-zig

Based on https://interpreterbook.com/

## Test

`zig test lexer.zig`

`watchexec -e zig 'zig test lexer.zig'`

## Run test in original go implementations

After downloading https://interpreterbook.com/waiig_code_1.3.zip

Go to every chapter and do:

```shell
$ cd 01/src/monkey
$ go mod init monkey
$ go test ./lexer
```

https://stackoverflow.com/questions/65758349/how-to-run-tests-from-go-project-root-folder/72969365#72969365

## Other implementations or also in zig

- https://monkeylang.org/#monkeys-in-the-wild
- in Zig https://github.com/mhanberg/zonkey
- in Zig https://github.com/Karitham/singe
- https://github.com/Vexu/bog/blob/master/src/tokenizer.zig
- https://github.com/catdevnull/awesome-zig#compilers-and-interpreters
- https://github.com/C-BJ/awesome-zig#compiler--parser--interpreter
- Toy implementation of Lisp written in Zig https://github.com/mattn/zig-lisp
- https://github.com/search?q=language%3Azig+monkey&type=code
- https://github.com/topics/monkey-programming-language
- https://github.com/topics/monkey-language
- https://github.com/topics/monkey
