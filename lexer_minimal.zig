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

    const Expectation = struct { tag: Token.Tag, literal: []const u8 };
    const expectations = [_]Expectation{
        .{ .tag = .identifier, .literal = "indexoutofbounds" },
        .{ .tag = .identifier, .literal = "let" },
        .{ .tag = .identifier, .literal = "five" },
        .{ .tag = .illegal, .literal = "=" },
    };
    for (expectations) |e| {
        const t = l.next();
        try std.testing.expectEqual(e.tag, t.tag);
        try std.testing.expectEqualStrings(e.literal, input[t.start..t.end]);
    }
}
