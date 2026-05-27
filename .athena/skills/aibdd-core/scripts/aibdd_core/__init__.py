"""Shared libraries for aibdd-core scripts."""

from aibdd_core.arguments_resolver import (
    DEFAULT_ARGS_REL,
    MAX_DEPTH,
    ResolveError,
    load_arguments_data,
    resolve_placeholders,
)
from aibdd_core.project_args import ResolveResult, resolve_key, resolve_text
from aibdd_core.repo_root import repo_root_from_module

__all__ = [
    "DEFAULT_ARGS_REL",
    "MAX_DEPTH",
    "ResolveError",
    "ResolveResult",
    "load_arguments_data",
    "repo_root_from_module",
    "resolve_key",
    "resolve_placeholders",
    "resolve_text",
]
