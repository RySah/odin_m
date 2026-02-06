package main

import "ninja_ir"

import "core:fmt"

// odin build . -export-dependencies-file:dependencies.d -export-dependencies:json

main :: proc() {
    fmt.println("Hi")
}