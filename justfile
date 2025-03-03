debug_flags := "-use-separate-modules -debug -dynamic-map-calls"
exe :=  "build/pinky.exe"

build:
    @mkdir -p build
    odin build src {{ debug_flags }} -out:{{ exe }}

run: build
    ./{{exe}} scripts/myscript.pinky

test:
    odin test src/
