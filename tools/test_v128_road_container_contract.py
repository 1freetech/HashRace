from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    source = ROOT / "native/cpp/test_v128_road_container_contract.cpp"
    assert source.exists(), "native v0.128 C++ contract is missing"
    with tempfile.TemporaryDirectory() as temp_dir:
        binary = Path(temp_dir) / "v128_contract"
        subprocess.run([
            "g++", "-std=c++20", "-O2", "-Wall", "-Wextra", "-Werror", "-pedantic",
            str(source), "-o", str(binary),
        ], cwd=ROOT, check=True)
        subprocess.run([str(binary)], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
