"""Make `python -m dsl_cli ...` invoke cli.main().

Preferred portable entry (PEP 723, auto-installs runtime deps via uv):

    uv run .athena/skills/aibdd-core/scripts/run_dsl_cli.py <subcommand> ...
"""

from __future__ import annotations

import sys

from dsl_cli.cli import main

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
