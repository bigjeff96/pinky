package pinky

import "core:fmt"
import "core:os"

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
}
