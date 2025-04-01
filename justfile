debug_flags := "-debug"
exe :=  "build/pinky.exe"

build: check
    @mkdir -p build
    odin build src {{ debug_flags }} -out:{{ exe }} -show-timings

run: build
    ./{{exe}} scripts/myscript.pinky

check:
    #!/usr/bin/env bash
    time odin check src/ -vet

test:
    odin test src/
