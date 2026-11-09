#!/usr/bin/env python3
"""Build a deterministic Harness archive from an explicit source allowlist."""

import argparse
import gzip
import hashlib
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tarfile
import tempfile


EXPECTED_VERSION = "2.0.0"
FIXED_MTIME = 0
ARCHIVE_MANIFEST = "ARCHIVE_MANIFEST.tsv"

# These are the public assets promised by the final distribution contract. A
# manifest entry may cover a required path through a directory-prefix entry.
REQUIRED_PATHS = (
    ".claude",
    ".codex",
    ".cursor",
    ".windsurfrules",
    "AGENTS.md",
    "CLAUDE.md",
    "MAP.md",
    "README.md",
    "CHANGELOG.md",
    "VERSION",
    "LICENSE",
    ".gitattributes",
    "scripts",
    "tests",
    "spec-templates",
    "token-templates",
    "project-templates",
    "docs/harness",
    "distribution",
)


class PackageError(Exception):
    """A predictable input or packaging-contract error."""


def fail(message):
    raise PackageError(message)


def is_within(path, directory):
    """Return whether path is directory or a descendant of directory."""
    try:
        return os.path.commonpath([os.path.abspath(path), os.path.abspath(directory)]) == os.path.abspath(directory)
    except ValueError:
        return False


def ensure_regular(path, label):
    try:
        mode = os.lstat(path).st_mode
    except OSError as exc:
        fail("missing {}: {} ({})".format(label, path, exc.strerror or exc))
    if stat.S_ISLNK(mode):
        fail("symlink is not allowed for {}: {}".format(label, path))
    if not stat.S_ISREG(mode):
        fail("{} is not a regular file: {}".format(label, path))


def ensure_directory(path, label):
    try:
        mode = os.lstat(path).st_mode
    except OSError as exc:
        fail("missing {}: {} ({})".format(label, path, exc.strerror or exc))
    if stat.S_ISLNK(mode):
        fail("symlink is not allowed for {}: {}".format(label, path))
    if not stat.S_ISDIR(mode):
        fail("{} is not a directory: {}".format(label, path))


def read_version(root):
    version_path = root / "VERSION"
    ensure_regular(version_path, "VERSION")
    try:
        raw = version_path.read_bytes()
    except OSError as exc:
        fail("cannot read VERSION: {}".format(exc))
    if raw.startswith(b"\xef\xbb\xbf") or b"\r" in raw:
        fail("invalid VERSION: use UTF-8 LF text")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        fail("invalid VERSION: use UTF-8 text")
    if text.endswith("\n"):
        text = text[:-1]
    if "\n" in text or text != EXPECTED_VERSION or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", text):
        fail("invalid VERSION: expected {}".format(EXPECTED_VERSION))
    return text


def validate_manifest_path(raw, line_number):
    if not raw:
        fail("unsafe empty manifest entry at line {}".format(line_number))
    if "\\" in raw or "\t" in raw or "\x00" in raw:
        fail("unsafe manifest path at line {}: {}".format(line_number, raw))
    if any(ord(char) < 32 or ord(char) == 127 for char in raw):
        fail("unsafe manifest path at line {}: {}".format(line_number, raw))
    directory_prefix = raw.endswith("/")
    path = raw[:-1] if directory_prefix else raw
    if not path or path.startswith("/"):
        fail("unsafe manifest path at line {}: {}".format(line_number, raw))
    components = path.split("/")
    if any(component in ("", ".", "..") for component in components):
        fail("unsafe manifest path at line {}: {}".format(line_number, raw))
    return path, directory_prefix


def parse_manifest(root):
    manifest_path = root / "distribution" / "MANIFEST.txt"
    ensure_regular(manifest_path, "distribution manifest")
    try:
        raw = manifest_path.read_bytes()
    except OSError as exc:
        fail("cannot read distribution manifest: {}".format(exc))
    if raw.startswith(b"\xef\xbb\xbf") or b"\r" in raw:
        fail("distribution manifest must be UTF-8 LF text")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        fail("distribution manifest must be UTF-8 text")

    entries = []
    seen = set()
    seen_casefold = set()
    for line_number, line in enumerate(text.split("\n"), 1):
        if not line or line.startswith("#"):
            continue
        path, directory_prefix = validate_manifest_path(line, line_number)
        if path in seen:
            fail("duplicate manifest entry or overlap: {}".format(line))
        if path.casefold() in seen_casefold:
            fail("duplicate manifest entry or case conflict: {}".format(line))
        for previous, _ in entries:
            if path == previous or path.startswith(previous + "/") or previous.startswith(path + "/"):
                fail("duplicate manifest entry or overlap: {}".format(line))
        seen.add(path)
        seen_casefold.add(path.casefold())
        entries.append((path, directory_prefix))

    if not entries:
        fail("distribution manifest is empty")

    for required in REQUIRED_PATHS:
        covered = any(
            required == path or (directory_prefix and required.startswith(path + "/"))
            for path, directory_prefix in entries
        )
        if not covered:
            fail("distribution manifest omits required path: {}".format(required))
    return entries


def excluded_source_path(relative_path):
    """Apply the public package's denylist to files under allowlisted prefixes."""
    parts = relative_path.split("/")
    basename = parts[-1]
    lower_name = basename.lower()

    if ".DS_Store" in parts or ".git" in parts or "__pycache__" in parts:
        return True
    if lower_name == "project_map.md":
        return True
    if len(parts) >= 2 and parts[0] == "docs" and parts[1] in ("specs", "token-specs", "superpowers"):
        return True
    if basename in ("settings.local.json", "config.local.toml"):
        return True
    if ".local." in lower_name or lower_name in (
        ".env",
        ".env.local",
        "credentials",
        "secret",
        "id_rsa",
        "id_dsa",
        "authorized_keys",
    ):
        return True
    if "credential" in lower_name or "secret" in lower_name:
        return True
    if lower_name.endswith((".pem", ".key", ".p12", ".pfx")):
        return True
    if lower_name.endswith((".pyc", ".pyo")):
        return True
    return False


def collect_files(root, entries):
    files = {}
    files_casefold = {}
    for relative_entry, directory_prefix in entries:
        source = root / Path(relative_entry)
        if directory_prefix:
            ensure_directory(source, "manifest directory")

            def onerror(error):
                fail("cannot read manifest directory {}: {}".format(source, error))

            for current, directories, filenames in os.walk(
                str(source), topdown=True, onerror=onerror, followlinks=False
            ):
                directories.sort()
                filenames.sort()
                # Symlinks are rejected even when their basename would be on
                # the denylist: the allowlisted tree must be link-free.
                for name in list(directories) + list(filenames):
                    candidate = Path(current) / name
                    if candidate.is_symlink():
                        fail("symlink is not allowed in manifest source: {}".format(candidate))
                kept_directories = []
                for name in directories:
                    candidate = Path(current) / name
                    if name in (".git", ".DS_Store", "__pycache__", ".pytest_cache", ".mypy_cache"):
                        continue
                    mode = os.lstat(candidate).st_mode
                    if not stat.S_ISDIR(mode):
                        fail("manifest directory contains non-directory: {}".format(candidate))
                    kept_directories.append(name)
                directories[:] = kept_directories
                for name in filenames:
                    candidate = Path(current) / name
                    mode = os.lstat(candidate).st_mode
                    if not stat.S_ISREG(mode):
                        fail("manifest directory contains non-regular file: {}".format(candidate))
                    relative = candidate.relative_to(root).as_posix()
                    if excluded_source_path(relative):
                        continue
                    if relative in files:
                        fail("duplicate source path selected by manifest: {}".format(relative))
                    folded = relative.casefold()
                    if folded in files_casefold:
                        fail("duplicate source path case conflict: {}".format(relative))
                    files[relative] = candidate
                    files_casefold[folded] = relative
        else:
            ensure_regular(source, "manifest source")
            if not excluded_source_path(relative_entry):
                folded = relative_entry.casefold()
                if folded in files_casefold:
                    fail("duplicate source path case conflict: {}".format(relative_entry))
                files[relative_entry] = source
                files_casefold[folded] = relative_entry
    if not files:
        fail("distribution manifest selected no files")
    return files


def normalized_mode(source):
    source_mode = stat.S_IMODE(os.lstat(source).st_mode)
    return 0o755 if source_mode & 0o111 else 0o644


def set_fixed_metadata(path, mode):
    os.chmod(path, mode)
    os.utime(path, (FIXED_MTIME, FIXED_MTIME), follow_symlinks=False)


def sha256_path(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def copy_to_stage(files, stage_root):
    records = []
    for relative in sorted(files):
        source = files[relative]
        destination = stage_root / Path(relative)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(str(source), str(destination), follow_symlinks=False)
        mode = normalized_mode(source)
        set_fixed_metadata(destination, mode)
        records.append((relative, mode, sha256_path(destination)))
    for current, directories, _ in os.walk(str(stage_root), topdown=False):
        for name in directories:
            set_fixed_metadata(Path(current) / name, 0o755)
    set_fixed_metadata(stage_root, 0o755)
    return records


def write_archive_manifest(stage_root, records):
    target = stage_root / ARCHIVE_MANIFEST
    lines = ["{}\t{:04o}\t{}\n".format(relative, mode, digest) for relative, mode, digest in records]
    target.write_bytes("".join(lines).encode("utf-8"))
    set_fixed_metadata(target, 0o644)


def tar_info(tar, path, archive_name, mode):
    info = tar.gettarinfo(str(path), arcname=archive_name)
    info.mode = mode
    info.uid = 0
    info.gid = 0
    info.uname = ""
    info.gname = ""
    info.mtime = FIXED_MTIME
    info.pax_headers = {}
    return info


def write_deterministic_archive(stage_root, archive_path):
    package_name = stage_root.name
    with archive_path.open("wb") as raw:
        with gzip.GzipFile(fileobj=raw, mode="wb", filename="", mtime=FIXED_MTIME) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.USTAR_FORMAT) as tar:
                root_info = tar_info(tar, stage_root, package_name, 0o755)
                tar.addfile(root_info)
                for current, directories, filenames in os.walk(str(stage_root), topdown=True):
                    directories.sort()
                    filenames.sort()
                    current_path = Path(current)
                    for name in directories:
                        path = current_path / name
                        relative = path.relative_to(stage_root).as_posix()
                        info = tar_info(tar, path, package_name + "/" + relative, 0o755)
                        tar.addfile(info)
                    for name in filenames:
                        path = current_path / name
                        relative = path.relative_to(stage_root).as_posix()
                        info = tar_info(
                            tar,
                            path,
                            package_name + "/" + relative,
                            stat.S_IMODE(os.lstat(path).st_mode),
                        )
                        with path.open("rb") as handle:
                            tar.addfile(info, handle)


def validate_output_path(output):
    if output.exists() and output.is_symlink():
        fail("output directory cannot be a symlink: {}".format(output))
    if output.exists() and not output.is_dir():
        fail("output path is not a directory: {}".format(output))


def validate_output_boundary(root, output):
    """Keep generated archives outside the source tree before any writes."""
    root_real = Path(os.path.realpath(str(root)))
    output_real = Path(os.path.realpath(str(output)))
    if is_within(output_real, root_real):
        fail("output directory must be outside the Harness source tree: {}".format(output))


def build(root_path, output_path):
    root = Path(os.path.abspath(str(root_path)))
    output = Path(os.path.abspath(str(output_path)))
    ensure_directory(root, "Harness root")
    validate_output_path(output)
    validate_output_boundary(root, output)
    version = read_version(root)
    entries = parse_manifest(root)
    files = collect_files(root, entries)

    archive_name = "project-harness-{}.tar.gz".format(version)
    checksum_name = archive_name + ".sha256"
    if output.exists():
        for name in (archive_name, checksum_name):
            candidate = output / name
            if candidate.is_symlink():
                fail("output file cannot be a symlink: {}".format(candidate))

    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="harness-package-") as staging:
        stage_root = Path(staging) / ("project-harness-{}".format(version))
        stage_root.mkdir(mode=0o755)
        records = copy_to_stage(files, stage_root)
        write_archive_manifest(stage_root, records)

        temporary_archive = Path(tempfile.mkstemp(prefix="." + archive_name + ".", dir=str(output))[1])
        try:
            write_deterministic_archive(stage_root, temporary_archive)
            digest = sha256_path(temporary_archive)
            archive_path = output / archive_name
            os.replace(str(temporary_archive), str(archive_path))
        finally:
            if temporary_archive.exists():
                temporary_archive.unlink()

    checksum_path = output / checksum_name
    temporary_checksum = Path(tempfile.mkstemp(prefix="." + checksum_name + ".", dir=str(output))[1])
    try:
        temporary_checksum.write_bytes("{}  {}\n".format(digest, archive_name).encode("utf-8"))
        set_fixed_metadata(temporary_checksum, 0o644)
        os.replace(str(temporary_checksum), str(checksum_path))
    finally:
        if temporary_checksum.exists():
            temporary_checksum.unlink()
    print("✅ {}".format(output / archive_name))
    print("✅ {}".format(output / checksum_name))


def main(argv=None):
    parser = argparse.ArgumentParser(description="Build a deterministic Harness 2.0.0 distribution archive")
    parser.add_argument("--root", required=True, help="Harness source root")
    parser.add_argument("--output", required=True, help="Output directory")
    args = parser.parse_args(argv)
    try:
        build(Path(args.root), Path(args.output))
    except PackageError as exc:
        print("package-harness: {}".format(exc), file=sys.stderr)
        return 1
    except OSError as exc:
        print("package-harness: filesystem error: {}".format(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
