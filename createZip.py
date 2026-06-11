#!/usr/bin/env python3
#######################################################################
# Create zip file for function code and dependencies
# - create dependencies if requirements.txt changed
# - create zip file with code from src and dependencies
#
# The zip file will have the following structure:
# .
# ├── src
# │   ├── FILE1.py
# │   └── ...
# └── <installed packages from requirements.txt> 
#
#######################################################################

from __future__ import annotations

import hashlib
import shutil
import subprocess
import sys
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


ROOT = Path(__file__).resolve().parent
DIST_DIR = ROOT / "dist"
DEPENDENCIES_DIR = DIST_DIR / "dependencies"
VENV_DIR = DIST_DIR / ".venv_dest"
REQUIREMENTS_FILE = ROOT / "requirements.txt"
REQUIREMENTS_HASH_FILE = DIST_DIR / ".requirements_hash"
CODE_ZIP = DIST_DIR / "code.zip"
OPTIONAL_FILES = ("README.md", "LICENSE", "bootstrap")


def sha1(path: Path) -> str:
    return hashlib.sha1(path.read_bytes()).hexdigest()


def requirements_changed(new_hash: str) -> bool:
    if not REQUIREMENTS_HASH_FILE.exists():
        return True
    return REQUIREMENTS_HASH_FILE.read_text(encoding="utf-8").strip() != new_hash


def install_dependencies() -> None:
    shutil.rmtree(VENV_DIR, ignore_errors=True)
    shutil.rmtree(DEPENDENCIES_DIR, ignore_errors=True)

    subprocess.run([sys.executable, "-m", "venv", str(VENV_DIR)], check=True, cwd=ROOT)

    venv_python = VENV_DIR / "bin" / "python"
    subprocess.run(
        [
            str(venv_python),
            "-m",
            "pip",
            "install",
            "-r",
            str(REQUIREMENTS_FILE),
            "--target",
            str(DEPENDENCIES_DIR),
        ],
        check=True,
        cwd=ROOT,
    )


def add_tree(zip_file: ZipFile, base_dir: Path, arc_prefix: str = "") -> None:
    for path in sorted(base_dir.rglob("*")):
        if path.is_dir() or "__pycache__" in path.parts:
            continue
        relative_path = path.relative_to(base_dir)
        archive_path = Path(arc_prefix) / relative_path if arc_prefix else relative_path
        zip_file.write(path, archive_path.as_posix())


def build_package() -> None:
    DIST_DIR.mkdir(exist_ok=True)

    new_hash = sha1(REQUIREMENTS_FILE)
    if requirements_changed(new_hash):
        print("Changes detected in requirements.txt, packaging dependencies.")
        install_dependencies()
        REQUIREMENTS_HASH_FILE.write_text(new_hash, encoding="utf-8")
    else:
        print("No changes in requirements.txt, skipping venv creation.")

    with ZipFile(CODE_ZIP, "w", compression=ZIP_DEFLATED) as zip_file:
        add_tree(zip_file, ROOT / "src", "src")
        if DEPENDENCIES_DIR.exists():
            add_tree(zip_file, DEPENDENCIES_DIR)

        for name in OPTIONAL_FILES:
            path = ROOT / name
            if path.is_file():
                zip_file.write(path, name)

    print(f"Packaged code and dependencies into {CODE_ZIP.relative_to(ROOT)}")


if __name__ == "__main__":
    build_package()
