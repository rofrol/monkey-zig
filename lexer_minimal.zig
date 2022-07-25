const std = @import("std");

const Token = struct {
    tag: Tag,
    start: usize,
    end: usize,
    const Tag = enum { eof, illegal, identifier };
};

const Lexer = struct {
    input: []const u8,
    pos: usize = 0,
    fn init(input: []const u8) Lexer {
        return Lexer{ .input = input };
    }
    const State = enum { start, identifier };
    fn next(self: *Lexer) Token {
        var token = Token{ .tag = .eof, .start = self.pos, .end = undefined };
        var state: State = .start;
        while (true) : (self.pos += 1) {
            if (self.pos == self.input.len) break;
            const c = self.input[self.pos];
            switch (state) {
                .start => switch (c) {
                    ' ', '\n' => {
                        token.start = self.pos + 1;
                    },
                    'a'...'z' => {
                        token.tag = .identifier;
                        state = .identifier;
                    },
                    else => {
                        token.tag = .illegal;
                        self.pos += 1;
                        break;
                    },
                },
                .identifier => switch (c) {
                    'a'...'z' => {},
                    else => {
                        break;
                    },
                },
            }
        }
        token.end = self.pos;
        return token;
    }
};

test "next" {
    const input =
        \\indexoutofbounds
        \\let five = 5;
    ;
    var l = Lexer.init(input);
    _ = l.next();
    const t1 = l.next();
    const e1 = Token{ .tag = .identifier, .start = 0, .end = 3 };
    try std.testing.expectEqual(e1.tag, t1.tag);
    try std.testing.expectEqualStrings("let", input[t1.start..t1.end]);
}
