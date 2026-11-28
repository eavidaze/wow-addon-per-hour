"""Run a repository entry point using Lupa's actual Lua 5.1 interpreter."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dist" / "runtime"))
from lupa.lua51 import LuaRuntime

runtime = LuaRuntime(unpack_returned_tuples=True)
assert runtime.eval("_VERSION") == "Lua 5.1"
entry = sys.argv[1] if len(sys.argv) > 1 else "tests/forever.lua"
runtime.globals().arg = runtime.table_from({i: value for i, value in enumerate(sys.argv[1:])})
runtime.execute("assert(loadfile(...))()", entry)
