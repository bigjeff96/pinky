package pinky

import "core:fmt"
import "core:mem"

todo :: proc(loc:= #caller_location) {
    assert(false, "Not implemented", loc)
}

Parser :: struct {
    tokens: []Token,
    current: int,
    allocator: mem.Allocator,
}

parser_advance :: proc(using p: ^Parser) {
    current += 1
}

parser_peek :: proc(using p: ^Parser) -> ^Token {
    return &tokens[current]
}

is_next :: proc(using p: ^Parser, token_type: Token_type) -> bool {
    return tokens[current + 1].type == token_type
}

expect :: proc(using p: ^Parser, token_type: Token_type) {
    assert(tokens[current].type == token_type, "current token not matching type")
}

parser_match :: proc(using p: ^Parser, token_type: Token_type) -> bool {
    if tokens[current].type == token_type {
        current += 1
        return true
    }
    else do return false
}

previous_token :: proc(using p: ^Parser) -> ^Token{
    return &tokens[current - 1]
}

// <primary>  ::=  <integer> | <float> | '(' <expr> ')'
primary :: proc(using p: ^Parser) -> ^Expr {
    todo()
    return nil
}

// <unary>  ::=  ('+'|'-'|'~') <unary>  |  <primary>
unary :: proc(using p: ^Parser) -> ^Expr {
    todo()
    return nil
}

// <factor>  ::=  <unary>
factor :: proc(using p: ^Parser) -> ^Expr {
    return unary(p)
}

// <term>  ::=  <factor> ( ('*'|'/') <factor> )*
term :: proc(using p: ^Parser) -> ^Expr {
    expr := factor(p)
    return nil
}

// <expr>  ::=  <term> ( ('+'|'-') <term> )*
expr :: proc(using p: ^Parser) -> ^Expr {
    expr := term(p)
    return nil
}

parse :: proc(using p: ^Parser) -> ^Expr {
    context.allocator = allocator
    return expr(p)
}

// ---Expressions---

Expr_type :: enum {
    integer,
    float,
    un_op,
    bin_op,
    grouping,
}

Expr :: struct {
    type: Expr_type,
}

Integer :: struct {
    using e: Expr,
    value: int,
}

Float :: struct {
    using e: Expr,
    value: f64,
}

Un_op :: struct {
    using e: Expr,
    op: Token,
    operand: ^Expr,
}

Bin_op :: struct {
    using e: Expr,
    op: Token,
    left: ^Expr,
    right: ^Expr,
}

Grouping :: struct {
    using e: Expr,
    value: ^Expr,
}

//---Statements---

Stmt_type :: enum {
    while_stmt,
    assignment,
}

Stmt :: struct {
    type: Stmt_type,
}

While_stmt :: struct {
    using s: Stmt,
}

Assignment :: struct {
    using s: Stmt,
}

