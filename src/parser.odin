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
        if current >= len(tokens) do current = len(tokens) - 1
        return true
    }
    else do return false
}

previous_token :: proc(using p: ^Parser) -> Token{
    return tokens[current - 1]
}

// <primary>  ::=  <integer> | <float> | '(' <expr> ')'
primary :: proc(using p: ^Parser) -> ^Expr {
    if parser_match(p, .INTEGER) {
        integer := new_expr(Integer)
        integer.value = previous_token(p).lexeme
        return &integer.e
    }
    if parser_match(p, .FLOAT) {
        float_expr := new_expr(Float)
        float_expr.value = previous_token(p).lexeme
        return &float_expr.e
    }
    if parser_match(p, .LPAREN) {
        expr := expr(p)
        if !parser_match(p, .RPAREN) do fmt.panicf("Missing closing brackets")
        else {
            grouping := new_expr(Grouping)
            grouping.value = expr
            return &grouping.e
        }
    }
    unreachable()
}

// <unary>  ::=  ('+'|'-'|'~') <unary>  |  <primary>
unary :: proc(using p: ^Parser) -> ^Expr {
    if parser_match(p, .PLUS) || parser_match(p, .MINUS) || parser_match(p, .NOT) {
        op := previous_token(p)
        operand := unary(p)
        unary := new_expr(Un_op)
        unary.op = op
        unary.operand = operand
        return &unary.e
    }
    else do return primary(p)
}

// <factor>  ::=  <unary>
factor :: proc(using p: ^Parser) -> ^Expr {
    return unary(p)
}

// <term>  ::=  <factor> ( ('*'|'/') <factor> )*
term :: proc(using p: ^Parser) -> ^Expr {
    expr := factor(p)
    for parser_match(p, .STAR) || parser_match(p, .SLASH) {
        op := previous_token(p)
        right := factor(p)
        bin_op := new_expr(Bin_op)
        bin_op.op = op
        bin_op.left = expr
        bin_op.right = right
        expr = &bin_op.e
    }
    return expr
}

// <expr>  ::=  <term> ( ('+'|'-') <term> )*
expr :: proc(using p: ^Parser) -> ^Expr {
    expr := term(p)
    for parser_match(p, .PLUS) || parser_match(p, .MINUS) {
        op := previous_token(p)
        right := term(p)
        bin_op := new_expr(Bin_op)
        bin_op.op = op
        bin_op.left = expr
        bin_op.right = right
        expr = &bin_op.e
    }
    return expr
}

cast_expr :: proc(expr: ^Expr, $T: typeid) -> ^T {
    return cast(^T)expr;
}

parse :: proc(using p: ^Parser) -> ^Expr {
    context.allocator = allocator
    return expr(p)
}

new_expr :: proc($expr_type: typeid) -> ^expr_type {
    when expr_type == Integer {
        a := new(Integer)
        a.type = .integer
        return a
    }
    else when expr_type == Float {
        a := new(Float)
        a.type = .float
        return a
    }
    else when expr_type == Un_op {
        a := new(Un_op)
        a.type = .un_op
        return a
    }
    else when expr_type == Bin_op {
        a := new(Bin_op)
        a.type = .bin_op
        return a
    }
    else when expr_type == Grouping {
        a := new(Grouping)
        a.type = .grouping
        return a
    }
    else {
        assert(false, "Unknown expression type")
        return nil
    }
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
    value: string,
}

Float :: struct {
    using e: Expr,
    value: string,
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

