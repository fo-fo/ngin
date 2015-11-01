# Ngin

Ngin is an NES game engine. There is no game here, at least yet; the engine is simply a playground for some ideas.

The engine is fairly incomplete at this point, so I don't recommend using it for anything apart from toying around.

## How to Build

### Easy Start

I have compiled a package containing all of the required dependencies (*Note: Windows only*). You can download the package [from Dropbox (~50 MB)](https://www.dropbox.com/s/mpbvuztlel80rw3/ngin-deps-v01.zip). The package has to be extracted in the Ngin root directory, i.e. the `deps` directory has to be at the same level as `include`, `src`, and so on.

If you use the above package, you can skip straight to the [Configuring](#configuring) section. Otherwise, you'll have to download the dependencies separately.

### Dependencies

- [CMake](http://www.cmake.org/download/) (recent version, mine is *3.1.20150114-gdb5583*)
- [Ninja](https://github.com/martine/ninja/releases) (I have version *1.5.3*)
- [cc65](http://cc65.github.io/cc65/) (I have *V2.14 - Git a13284a*)
- [Python 2](https://www.python.org/downloads/) (I have version *2.7.9*)
- [NDX](http://kkfos.aspekt.fi/projects/nes/tools/nintendulatordx/) (*v36* or later)
- [Musetracker](http://kkfos.aspekt.fi/projects/nes/tools/musetracker/) (*v15* or later)
  - Currently required -- will likely be made optional at some point.

Only Windows is supported as a host platform at this time. The build system itself doesn't depend on Windows, but the engine heavily depends on the Lua support of *NDX*, and *NDX* is currently only available for Windows.

*CMake*, *Ninja*, *cc65* and *Python 2* need to be in system *PATH*. *Python 2* needs to be accessible as `python`. *NDX* (`Nintendulator.exe`) needs to exist in directory `C:\Program Files (x86)\nintendulatordx` or in *PATH* and *Musetracker* (`Musetracker.exe`) needs to exist in directory `C:\Program Files (x86)\musetracker` or in *PATH*.

Sorry about the hardcoded paths, they will be eventually made configurable.

The path of the engine source code must not contain spaces. An error will be given by CMake if this is the case.

### Configuring

To configure the build, open a command line window at Ngin's directory and execute `initialize-build`. This will create a directory called `build`, and use CMake to configure the Release and Debug builds within it. **Note that this step needs to be executed only once.** It only needs to be re-executed if the `build` directory is removed (e.g. if the build becomes corrupted for some reason, or you want to do a clean rebuild).

### Building

To build the engine and samples, execute `build-debug` or `build-release` in the command line window. Currently there are very few differences between the Debug and Release builds.

The arguments of these commands are passed directly to *Ninja*, so they can be used to build individual targets as well. To build the sprite animation sample (for example), the following command can be used.

    build-debug ngin-sample-sprite-animation

The following command can be used to start a sample in NDX:

    build-debug start-ngin-sample-sprite-animation

The available targets can be enumerated as follows:

    build-debug -t targets
