# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

"""Inspect skill references and local artifacts for one or more skill directories."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ARTIFACT_FOLDERS = ("rules", "templates", "scripts")
PHASE_PATTERN = re.compile(r"^## Phase \d+ -- .+$", re.MULTILINE)
STEP_PATTERN = re.compile(r"^\d+\.\s+(READ|WRITE|THINK|DELEGATE)\b.*$", re.MULTILINE)
SKILL_REF_PATTERN = re.compile(
    r"(?<![A-Za-z0-9_.-])/(?P<name>[a-z0-9][a-z0-9-]{1,63})(?![A-Za-z0-9_.\-/])"
)
ARTIFACT_REF_PATTERN = re.compile(
    r"(?P<path>(?:rules|templates|scripts)/[^\s`\"'，。、；：）)]+)"
)


def fail(message: str, code: int = 2) -> int:
    print(message, file=sys.stderr)
    return code


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Analyze one or more skill directories and report skill references, "
            "artifact references, missing refs, and unreferenced local artifacts."
        )
    )
    parser.add_argument(
        "--skill",
        action="append",
        required=True,
        help="Path to a skill directory. Repeat this flag to inspect multiple skills.",
    )
    return parser.parse_args(argv)


def extract_frontmatter_name(text: str) -> str | None:
    if not text.startswith("---"):
        return None

    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None

    for line in lines[1:]:
        if line.strip() == "---":
            break
        if line.startswith("name:"):
            return line.split(":", 1)[1].strip()

    return None


def normalize_paths(paths: set[str]) -> list[str]:
    return sorted(path.replace("\\", "/") for path in paths)


def collect_local_artifacts(skill_dir: Path) -> dict[str, list[str]]:
    artifacts: dict[str, list[str]] = {}
    for folder in ARTIFACT_FOLDERS:
        folder_path = skill_dir / folder
        items: set[str] = set()
        if folder_path.is_dir():
            for path in folder_path.rglob("*"):
                if path.is_file():
                    items.add(path.relative_to(skill_dir).as_posix())
        artifacts[folder] = normalize_paths(items)
    return artifacts


def extract_skill_refs(text: str) -> list[str]:
    refs = {match.group("name") for match in SKILL_REF_PATTERN.finditer(text)}
    return sorted(refs)


def extract_artifact_refs(text: str) -> dict[str, list[str]]:
    refs_by_folder: dict[str, set[str]] = {folder: set() for folder in ARTIFACT_FOLDERS}

    for match in ARTIFACT_REF_PATTERN.finditer(text):
        path = match.group("path").rstrip("`")
        folder = path.split("/", 1)[0]
        refs_by_folder[folder].add(path)

    return {folder: normalize_paths(paths) for folder, paths in refs_by_folder.items()}


def summarize_skill(skill_dir: Path) -> dict[str, Any]:
    skill_md = skill_dir / "SKILL.md"
    if not skill_dir.is_dir():
        raise FileNotFoundError(f"Skill directory not found: {skill_dir}")
    if not skill_md.is_file():
        raise FileNotFoundError(f"SKILL.md not found under: {skill_dir}")

    text = skill_md.read_text(encoding="utf-8")
    local_artifacts = collect_local_artifacts(skill_dir)
    artifact_refs = extract_artifact_refs(text)
    skill_refs = extract_skill_refs(text)
    skills_root = skill_dir.parent

    missing_artifact_refs: list[str] = []
    for paths in artifact_refs.values():
        for path in paths:
            if not (skill_dir / path).is_file():
                missing_artifact_refs.append(path)

    local_artifact_set = {
        path for paths in local_artifacts.values() for path in paths
    }
    referenced_artifact_set = {
        path for paths in artifact_refs.values() for path in paths
    }
    unreferenced_artifacts = sorted(local_artifact_set - referenced_artifact_set)

    summary: dict[str, Any] = {
        "skillDir": str(skill_dir),
        "dirName": skill_dir.name,
        "skillName": extract_frontmatter_name(text) or skill_dir.name,
        "phaseCount": len(PHASE_PATTERN.findall(text)),
        "phaseTitles": PHASE_PATTERN.findall(text),
        "stepCount": len(STEP_PATTERN.findall(text)),
        "skillRefs": skill_refs,
        "missingSkillRefs": sorted(
            ref for ref in skill_refs if not (skills_root / ref).is_dir()
        ),
        "artifactRefs": artifact_refs,
        "localArtifacts": local_artifacts,
        "missingArtifactRefs": sorted(set(missing_artifact_refs)),
        "unreferencedArtifacts": unreferenced_artifacts,
    }
    return summary


def build_edges(summaries: list[dict[str, Any]]) -> list[dict[str, str]]:
    known_names = {
        summary["skillName"] for summary in summaries
    } | {summary["dirName"] for summary in summaries}
    edges: list[dict[str, str]] = []

    for summary in summaries:
        source = summary["skillName"]
        for ref in summary["skillRefs"]:
            if ref in known_names:
                edges.append({"from": source, "to": ref})

    edges.sort(key=lambda item: (item["from"], item["to"]))
    return edges


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    seen: set[Path] = set()
    skill_dirs: list[Path] = []

    for raw_path in args.skill:
        resolved = Path(raw_path).resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        skill_dirs.append(resolved)

    try:
        summaries = [summarize_skill(skill_dir) for skill_dir in skill_dirs]
    except FileNotFoundError as exc:
        return fail(str(exc))
    except OSError as exc:
        return fail(f"Failed to read skill files: {exc}", code=1)

    payload = {
        "skillCount": len(summaries),
        "skills": summaries,
        "edges": build_edges(summaries),
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
