debug_flags := "-debug"
exe :=  "build/pinky.exe"

build:
    @mkdir -p build
    odin build src {{ debug_flags }} -out:{{ exe }} -show-timings

run: build
    ./{{exe}} scripts/myscript.pinky

test:
    odin test src/
