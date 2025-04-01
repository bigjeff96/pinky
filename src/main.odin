package pinky

import "core:fmt"
import "core:os"
import vmem "core:mem/virtual"
import q "core:container/queue"

_ :: q

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
    print(ast^)
}
