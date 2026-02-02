# Luartex Obfuscator Documentation

Welcome to the Luartex Obfuscator documentation!

## Table of Contents

1. [Installation](INSTALLATION.md)
2. [Usage Guide](USAGE.md)
3. [API Reference](API.md)
4. [Protection Layers](LAYERS.md)

## Quick Start

```lua
local Luartex = require("Luartex-Obfuscator")

local source = [[
    print("Hello, World!")
]]

local obfuscator = Luartex.new()
obfuscator:usePreset("standard")

local protected = obfuscator:obfuscate(source)
print(protected)
