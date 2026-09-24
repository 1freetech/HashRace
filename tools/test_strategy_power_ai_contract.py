#!/usr/bin/env python3
"""Compatibility launcher for the native C++ strategy/power contract.

The repeatedly brittle historical Python assertions were retired in v0.133.
This file remains only because the existing CI step calls this path; all
contract assertions now live in native/cpp/strategy_power_contract.cpp.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = root / "native/cpp/strategy_power_contract.cpp"
with tempfile.TemporaryDirectory() as td:
    binary = Path(td) / "strategy_power_contract"
    subprocess.run(["g++", "-std=c++20", "-O2", "-Wall", "-Wextra", "-Werror", "-pedantic", str(source), "-o", str(binary)], cwd=root, check=True)
    subprocess.run([str(binary)], cwd=root, check=True)
