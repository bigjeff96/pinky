package pinky

import "core:fmt"
import "core:mem"
import "core:io"

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

Expr_formatter :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
    expr := cast(^Expr)arg.data
    assert(verb == 'v')

    recursive_formatter :: proc(fi: ^fmt.Info, expr: ^Expr, indent: int) {
        write_indentation :: proc(fi: ^fmt.Info, indent: int) {
            indent := indent
            for indent > 0 {
                io.write_string(fi.writer, "    ", &fi.n)
                indent -= 1
            }
        }
        // TODO: this is not great, should do something better
        write_indentation(fi, indent)
        switch expr.type {
        case .integer:
            integer := cast(^Integer)expr
            io.write_string(fi.writer, "Integer{", &fi.n)
            io.write_string(fi.writer, integer.value, &fi.n)
            io.write_string(fi.writer, "}", &fi.n)
        case .float:
            float := cast(^Float)expr
            io.write_string(fi.writer, "Float{", &fi.n)
            io.write_string(fi.writer, float.value, &fi.n)
            io.write_string(fi.writer, "}", &fi.n)
        case .un_op:
            un_op := cast(^Un_op)expr
            io.write_string(fi.writer, "Un_op{type: ", &fi.n)
            io.write_string(fi.writer, un_op.op.lexeme, &fi.n)
            io.write_string(fi.writer, "\n", &fi.n)
            write_indentation(fi, indent + 1)
            io.write_string(fi.writer, "operand: \n", &fi.n)
            recursive_formatter(fi, un_op.operand, indent + 1)
            io.write_string(fi.writer, "\n", &fi.n)
            write_indentation(fi, indent)
            io.write_string(fi.writer, "}", &fi.n)
        case .bin_op:
            bin_op := cast(^Bin_op)expr
            io.write_string(fi.writer, "Bin_op{type: ", &fi.n)
            io.write_string(fi.writer, bin_op.op.lexeme, &fi.n)
            io.write_string(fi.writer, "\n", &fi.n)
            write_indentation(fi, indent + 1)
            io.write_string(fi.writer, "left: \n", &fi.n)
            recursive_formatter(fi, bin_op.left, indent + 1)
            io.write_string(fi.writer, "\n", &fi.n)
            write_indentation(fi, indent + 1)
            io.write_string(fi.writer, "right: \n", &fi.n)
            recursive_formatter(fi, bin_op.right, indent + 1)
            io.write_string(fi.writer, "\n", &fi.n)
            write_indentation(fi, indent)
            io.write_string(fi.writer, "}", &fi.n)
        case .grouping:
            grouping := cast(^Grouping)expr
            io.write_string(fi.writer, "Grouping{ \n", &fi.n)
            recursive_formatter(fi, grouping.value, indent + 1)
            io.write_string(fi.writer, "\n", &fi.n)
            write_indentation(fi, indent)
            io.write_string(fi.writer, "}", &fi.n)
        }
    }

    recursive_formatter(fi, expr, 0)

    return true
}

@(init)
set_expr_formatter :: proc() {
    fmt.set_user_formatters(new(map[typeid]fmt.User_Formatter))
    err := fmt.register_user_formatter(type_info_of(Expr).id, Expr_formatter)
    assert(err == .None)
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

