#+feature dynamic-literals

package pinky

import "core:strings"
import "core:fmt"
import text "core:text/match"

Token :: struct {
    type : Token_type,
    lexeme: string,
    line: int,
}

Tokenizer :: struct {
    source: string,
    start: int,
    current: int,
    line: int,
    tokens: [dynamic]Token,
}

tokenize :: proc(source: string) -> []Token {
    t := Tokenizer {
        source = source,
        line = 1,
    }

    for t.current < len(t.source) {
        t.start = t.current
        ch := advance(&t)

        handle_number :: proc(using t: ^Tokenizer) {
            for is_digit(peek(t)) do advance(t)
            if peek(t) == '.' && is_digit(look_ahead(t)) {
                advance(t)
                for is_digit(peek(t)) do advance(t)
                add_token(t, .FLOAT)
            } else {
                add_token(t, .INTEGER)
            }
        }

        handle_string :: proc(using t: ^Tokenizer, start_quote: byte) {
            for peek(t) != start_quote && current < len(source) do advance(t)
            if current >= len(source) {
                fmt.panicf("line: %v, missing closing quote for string", line)
            }
            advance(t)
            add_token(t, .STRING)
        }

        handle_identifier_or_keyword :: proc(using t: ^Tokenizer) {
            for is_alphanum(peek(t)) || peek(t) == '_' do advance(t)

            text := source[start:current]
            if text in keyword_lookup do add_token(t, keyword_lookup[text])
            else do add_token(t, .IDENTIFIER)
        }

        switch {
        // white space
        case ch == '\n': t.line += 1
        case ch == '\t': continue
        case ch == ' ': continue
        case ch == '\r': continue



        // single character tokens
        case ch == '(': add_token(&t, .LPAREN)
        case ch == ')': add_token(&t, .RPAREN)
        case ch == '{': add_token(&t, .LCURLY)
        case ch == '}': add_token(&t, .RCURLY)
        case ch == '[': add_token(&t, .LSQUAR)
        case ch == ']': add_token(&t, .RSQUAR)
        case ch == ',': add_token(&t, .COMMA)
        case ch == '.': add_token(&t, .DOT)
        case ch == '+': add_token(&t, .PLUS)
        case ch == '*': add_token(&t, .STAR)
        case ch == '^': add_token(&t, .CARET)
        case ch == '%': add_token(&t, .MOD)
        case ch == ';': add_token(&t, .SEMICOLON)
        case ch == '?': add_token(&t, .QUESTION)

        case ch == '/':
            if match(&t, '*') {
                for peek(&t) != '*' && look_ahead(&t) != '/' && t.current < len(t.source) do advance(&t)
                if t.current >= len(t.source) do fmt.panicf("line: %v, missing */ for multiline comment", t.line)
                advance(&t, 2)
            }
            else do add_token(&t, .SLASH)
        case ch == '-':
            if match(&t, '-') {
                // line comment
                for peek(&t) != '\n' && t.current < len(t.source) do advance(&t)
            }
            else do add_token(&t, .MINUS)
        case ch == '=':
            if match(&t, '=') do add_token(&t, .EQEQ)
            else do add_token(&t, .EQ)
        case ch == '~':
            if match(&t, '=') do add_token(&t, .NE)
            else do add_token(&t, .NOT)
        case ch == '<':
            if match(&t, '=') do add_token(&t, .LE)
            else do add_token(&t, .LT)
        case ch == '>':
            if match(&t, '=') do add_token(&t, .GE)
            else do add_token(&t, .GT)
        case ch == ':':
            if match(&t, '=') do add_token(&t, .ASSIGN)
            else do add_token(&t, .COLON)

        case is_digit(ch): handle_number(&t)
        case ch == '\'' || ch == '"': handle_string(&t, ch)

        case is_alpha(ch) || ch == '_': handle_identifier_or_keyword(&t)
        case:
            fmt.panicf("line: %v, unknown character %v", t.line, rune(ch))
        }
    }

    return t.tokens[:]
}

is_digit :: proc(char: byte) -> bool {
    return char >= '0' && char <= '9'
}

is_alpha :: #force_inline proc(ch: byte) -> bool {
    return text.is_alpha(rune(ch))
}

is_alphanum :: proc(ch: byte) -> bool {
    return is_alpha(ch) || is_digit(ch)
}

advance :: proc(using t: ^Tokenizer, n := 1) -> byte {
    ch := source[current]
    current += n
    return ch
}

peek :: proc(using t: ^Tokenizer) -> byte {
    if current >= len(source) do return 0
    return source[current]
}

look_ahead :: proc(using t: ^Tokenizer, n := 1) -> byte {
    if current >= len(source) do return 0
    return source[current + n]
}

match :: proc(using t: ^Tokenizer, expected: byte) -> bool {
    if current >= len(source) do return false
    if source[current] != expected do return false
    else {
        current += 1
        return true
    }
}

add_token :: proc(using t: ^Tokenizer, type: Token_type) {
    append(&tokens, Token{type = type, lexeme = source[start:current], line = line})
}

Token_type :: enum {
    LPAREN,                 //  (
    RPAREN,                 //  )
    LCURLY,                 //  {
    RCURLY,                 //  }
    LSQUAR,                 //  [
    RSQUAR,                 //  ]
    COMMA,                  //  ,
    DOT,                    //  .
    PLUS,                   //  +
    MINUS,                  //  -
    STAR,                   //  *
    SLASH,                  //  /
    CARET,                  //  ^
    MOD,                    //  %
    COLON,                  //  :
    SEMICOLON,              //  ;
    QUESTION,               //  ?
    NOT,                    //  ~
    GT,                     //  >
    LT,                     //  <
    EQ,                     //  =
    // Two-char tokens
    GE,                     //  >=
    LE,                     //  <=
    NE,                     //  ~=
    EQEQ,                   //  ==
    ASSIGN,                 //  :=
    GTGT,                   //  >>
    LTLT,                   //  <<
    // Literals
    IDENTIFIER,
    STRING,
    INTEGER,
    FLOAT,
    // Keywords
    IF,
    THEN,
    ELSE,
    TRUE,
    FALSE,
    AND,
    OR,
    WHILE,
    DO,
    FOR,
    FUNC,
    NULL,
    END,
    PRINT,
    PRINTLN,
    RET,
}

keyword_lookup : map[string]Token_type = {
    "if" = .IF,
    "then" = .THEN,
    "else" = .ELSE,
    "true" = .TRUE,
    "false" = .FALSE,
    "and" = .AND,
    "or" = .OR,
    "while" = .WHILE,
    "do" = .DO,
    "for" = .FOR,
    "func" = .FUNC,
    "null" = .NULL,
    "end" = .END,
    "print" = .PRINT,
    "println" = .PRINTLN,
    "ret" = .RET,
}