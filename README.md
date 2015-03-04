# Ngin

Ngin is an NES game engine. There is no game here, at least yet; the engine is simply a playground for some ideas.

## How to Build

Dependencies: cc65, CMake, Ninja, Python 2

TBD

## Random Notes

Ngin places most of its identifiers in the `ngin` namespace, either by using an `ngin_` prefix (for symbols, macros, etc), or by using ca65's scoping feature (`ngin::`) where possible (constants). Because ca65 lacks the ability to import scopes into other scopes, some established identifiers like `ppu::mask` are placed directly into the global scope to avoid excess verboseness.
