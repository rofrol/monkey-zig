const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const Tag = enum {
        illegal,
        eof,
        identifier,
        int_literal,
        // operators
        plus,
        minus,
        asterisk,
        slash,
        bang,
        angle_bracket_left,
        angle_bracket_right,
        equal,
        equal_equal,
        bang_equal,
        // delimiters
        comma,
        semicolon,
        l_paren,
        r_paren,
        l_brace,
        r_brace,
        keyword_fn,
        keyword_let,
        keyword_true,
        keyword_false,
        keyword_if,
        keyword_else,
        keyword_return,
    };

    pub const Keywords = std.ComptimeStringMap(Tag, .{
        .{ "fn", .keyword_fn },
        .{ "let", .keyword_let },
        .{ "true", .keyword_true },
        .{ "false", .keyword_false },
        .{ "if", .keyword_if },
        .{ "else", .keyword_else },
        .{ "return", .keyword_return },
    });
};

pub const Lexer = struct {
    input: []const u8,
    pos: usize = 0,

    /// For debugging purposes
    pub fn dump(self: *Lexer, token: *const Token) void {
        std.debug.print("{s} \"{s}\"\n", .{ @tagName(token.tag), self.input[token.start..token.end] });
    }

    pub fn init(input: []const u8) Lexer {
        return Lexer{
            .input = input,
        };
    }

    const State = enum {
        start,
        plus,
        minus,
        asterisk,
        slash,
        bang,
        equal,
        angle_bracket_left,
        angle_bracket_right,
        identifier,
        int_literal,
    };

    pub fn next(self: *Lexer) Token {
        var token = Token{ .tag = .eof, .loc = .{ .start = self.pos, .end = undefined } };
        var state: State = .start;

        while (true) : (self.pos += 1) {
            if (self.pos >= self.input.len) {
                token.loc.end = self.pos;
                return token;
            }
            const c = self.input[self.pos];
            switch (state) {
                .start => switch (c) {
                    0 => break,
                    ' ', '\n', '\r', '\t' => token.loc.start = self.pos + 1,
                    '+' => state = .plus,
                    '-' => state = .minus,
                    '*' => state = .asterisk,
                    '/' => state = .slash,
                    '!' => state = .bang,
                    '<' => state = .angle_bracket_left,
                    '>' => state = .angle_bracket_right,
                    '=' => state = .equal,
                    '{' => {
                        token.tag = .l_brace;
                        self.pos += 1;
                        break;
                    },
                    '}' => {
                        token.tag = .r_brace;
                        self.pos += 1;
                        break;
                    },
                    '(' => {
                        token.tag = .l_paren;
                        self.pos += 1;
                        break;
                    },
                    ')' => {
                        token.tag = .r_paren;
                        self.pos += 1;
                        break;
                    },
                    ',' => {
                        token.tag = .comma;
                        self.pos += 1;
                        break;
                    },
                    ';' => {
                        token.tag = .semicolon;
                        self.pos += 1;
                        break;
                    },
                    'a'...'z', 'A'...'Z', '_' => {
                        state = .identifier;
                        token.tag = .identifier;
                    },
                    '0'...'9' => {
                        state = .int_literal;
                        token.tag = .int_literal;
                    },
                    else => {
                        token.tag = .illegal;
                        self.pos += 1;
                        break;
                    },
                },
                // NOTE: this break down is so that it's easily extensible
                // e.g. if we need to support '+=' in the future.
                .plus => {
                    token.tag = .plus;
                    break;
                },
                .minus => {
                    token.tag = .minus;
                    break;
                },
                .asterisk => {
                    token.tag = .asterisk;
                    break;
                },
                .slash => {
                    token.tag = .slash;
                    break;
                },
                .angle_bracket_left => {
                    token.tag = .angle_bracket_left;
                    break;
                },
                .angle_bracket_right => {
                    token.tag = .angle_bracket_right;
                    break;
                },
                .bang => switch (c) {
                    '=' => {
                        token.tag = .bang_equal;
                        self.pos += 1;
                        break;
                    },
                    else => {
                        token.tag = .bang;
                        break;
                    },
                },
                .equal => switch (c) {
                    '=' => {
                        token.tag = .equal_equal;
                        self.pos += 1;
                        break;
                    },
                    else => {
                        token.tag = .equal;
                        break;
                    },
                },
                .identifier => switch (c) {
                    'a'...'z', 'A'...'Z', '_' => {},
                    else => {
                        var ident = self.input[token.loc.start..self.pos];
                        if (Token.Keywords.get(ident)) |tag| {
                            token.tag = tag;
                        }
                        break;
                    },
                },
                .int_literal => switch (c) {
                    '0'...'9' => {},
                    else => break,
                },
            }
        }

        token.loc.end = self.pos;
        return token;
    }
};

test "next token - complete program" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\
        \\if (5 < 10) {
        \\	return true;
        \\} else {
        \\	return false;
        \\}
        \\
        \\10 == 10;
        \\10 != 9;
        \\
    ;
    var l = Lexer.init(input);

    const Expectation = struct { tag: Token.Tag, literal: []const u8 };
    const expectations = [_]Expectation{
        // let five = 5;
        .{ .tag = .keyword_let, .literal = "let" },
        .{ .tag = .identifier, .literal = "five" },
        .{ .tag = .equal, .literal = "=" },
        .{ .tag = .int_literal, .literal = "5" },
        .{ .tag = .semicolon, .literal = ";" },
        // let ten = 10;
        .{ .tag = .keyword_let, .literal = "let" },
        .{ .tag = .identifier, .literal = "ten" },
        .{ .tag = .equal, .literal = "=" },
        .{ .tag = .int_literal, .literal = "10" },
        .{ .tag = .semicolon, .literal = ";" },
        //let add = fn(x, y) {
        .{ .tag = .keyword_let, .literal = "let" },
        .{ .tag = .identifier, .literal = "add" },
        .{ .tag = .equal, .literal = "=" },
        .{ .tag = .keyword_fn, .literal = "fn" },
        .{ .tag = .l_paren, .literal = "(" },
        .{ .tag = .identifier, .literal = "x" },
        .{ .tag = .comma, .literal = "," },
        .{ .tag = .identifier, .literal = "y" },
        .{ .tag = .r_paren, .literal = ")" },
        .{ .tag = .l_brace, .literal = "{" },
        // x + y;
        .{ .tag = .identifier, .literal = "x" },
        .{ .tag = .plus, .literal = "+" },
        .{ .tag = .identifier, .literal = "y" },
        .{ .tag = .semicolon, .literal = ";" },
        // };
        .{ .tag = .r_brace, .literal = "}" },
        .{ .tag = .semicolon, .literal = ";" },
        // let result = add(five, ten);
        .{ .tag = .keyword_let, .literal = "let" },
        .{ .tag = .identifier, .literal = "result" },
        .{ .tag = .equal, .literal = "=" },
        .{ .tag = .identifier, .literal = "add" },
        .{ .tag = .l_paren, .literal = "(" },
        .{ .tag = .identifier, .literal = "five" },
        .{ .tag = .comma, .literal = "," },
        .{ .tag = .identifier, .literal = "ten" },
        .{ .tag = .r_paren, .literal = ")" },
        .{ .tag = .semicolon, .literal = ";" },
        // !-/*5;
        .{ .tag = .bang, .literal = "!" },
        .{ .tag = .minus, .literal = "-" },
        .{ .tag = .slash, .literal = "/" },
        .{ .tag = .asterisk, .literal = "*" },
        .{ .tag = .int_literal, .literal = "5" },
        .{ .tag = .semicolon, .literal = ";" },
        // 5 < 10 > 5;
        .{ .tag = .int_literal, .literal = "5" },
        .{ .tag = .angle_bracket_left, .literal = "<" },
        .{ .tag = .int_literal, .literal = "10" },
        .{ .tag = .angle_bracket_right, .literal = ">" },
        .{ .tag = .int_literal, .literal = "5" },
        .{ .tag = .semicolon, .literal = ";" },
        // if (5 < 10) {
        .{ .tag = .keyword_if, .literal = "if" },
        .{ .tag = .l_paren, .literal = "(" },
        .{ .tag = .int_literal, .literal = "5" },
        .{ .tag = .angle_bracket_left, .literal = "<" },
        .{ .tag = .int_literal, .literal = "10" },
        .{ .tag = .r_paren, .literal = ")" },
        .{ .tag = .l_brace, .literal = "{" },
        // return true;
        .{ .tag = .keyword_return, .literal = "return" },
        .{ .tag = .keyword_true, .literal = "true" },
        .{ .tag = .semicolon, .literal = ";" },
        // } else {
        .{ .tag = .r_brace, .literal = "}" },
        .{ .tag = .keyword_else, .literal = "else" },
        .{ .tag = .l_brace, .literal = "{" },
        // return false;
        .{ .tag = .keyword_return, .literal = "return" },
        .{ .tag = .keyword_false, .literal = "false" },
        .{ .tag = .semicolon, .literal = ";" },
        // }
        .{ .tag = .r_brace, .literal = "}" },
        // 10 == 10;
        .{ .tag = .int_literal, .literal = "10" },
        .{ .tag = .equal_equal, .literal = "==" },
        .{ .tag = .int_literal, .literal = "10" },
        .{ .tag = .semicolon, .literal = ";" },
        // 10 != 9;
        .{ .tag = .int_literal, .literal = "10" },
        .{ .tag = .bang_equal, .literal = "!=" },
        .{ .tag = .int_literal, .literal = "9" },
        .{ .tag = .semicolon, .literal = ";" },
    };

    for (expectations) |expectation| {
        const next = l.next();
        try std.testing.expectEqual(expectation.tag, next.tag);
        const literal = input[next.loc.start..next.loc.end];
        try std.testing.expectEqualStrings(expectation.literal, literal);
    }
}
