package pinky

import "core:fmt"
import "core:os"
import vmem "core:mem/virtual"
import q "core:container/queue"

print :: fmt.println

main :: proc() {
    if len(os.args) != 2 {
        fmt.println("Usage: pinky.exe <filename>")
        os.exit(1)
    }
    filename := os.args[1]
    data, ok := os.read_entire_file(filename)
    if !ok do panic("Couldn't read the file")
    source := string(data)

    fmt.println(source)

    print("LEXER:")

    tokens := tokenize(source)

    for token in tokens do print(token)
    arena: vmem.Arena
    err := vmem.arena_init_growing(&arena)
    ensure(err == nil)
    arena_alloc := vmem.arena_allocator(&arena)

    parser := Parser{tokens = tokens[:], allocator = arena_alloc}
    ast := parse(&parser)
    print_ast(ast, 0)

    print_ast :: proc(expr: ^Expr, indent_level: int) {
        switch expr.type {
        case .integer:
            a := cast(^Integer)expr
            print(indent_level," int:", a.value)
        case .float:
            a := cast(^Float)expr
            print(indent_level," float:", a.value)
        case .un_op:
            a := cast(^Un_op)expr
            print(indent_level," unary op(", a.op.lexeme)
            print_ast(a.operand, indent_level + 1)
        case .bin_op:
            a := cast(^Bin_op)expr
            print(indent_level," ",a.op.lexeme)
            print_ast(a.left, indent_level + 1)
            print_ast(a.right, indent_level + 1)
        case .grouping:
            a := cast(^Grouping)expr
            print(indent_level," grouping:")
            print_ast(a.value, indent_level + 1)
        }
    }

}
