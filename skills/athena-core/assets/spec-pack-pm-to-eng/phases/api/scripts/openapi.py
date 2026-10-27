#!/usr/bin/env python3
"""
openapi.py — minimal transpiler (athena-skills / api stage)
=================================================================

保留核心三件事：
  1. exposes 驅動的 path 推導（base = api，用複數名詞；遵循 Intent Format Anchor）
  2. DTO 雙 schema（<Entity> response / <Entity>Request writable-only）
  3. 狀態碼 + 共用 Error schema

輸入同樣輸出、純函數、可重現。openapi.yaml 是 build artifact，不可手改。

用法:
    python3 openapi.py \
        --intent  specs/<slug>/api/                 # *.intent.yaml 目錄或單檔
        --dbml   specs/<slug>/db_table/erm.dbml \
        --output specs/<slug>/api/openapi.yaml \
        --title  "訂單服務"
"""

import argparse
import re
import sys
from pathlib import Path

import yaml


# ── DBML parser ──────────────────────────────────────────────────────────────

def dbml_type_to_schema(raw_type: str, enums: dict) -> dict:
    """DBML 欄位型別 → OpenAPI schema fragment（通用型別，非 MSSQL 專屬）。"""
    raw = raw_type.strip().strip('"').lower()

    # enum-typed column → 列舉值集合（展現 data_model enum → OpenAPI enum）
    if raw in enums:
        return {"type": "string", "enum": list(enums[raw])}

    m = re.match(r"(?:n?varchar|n?char|character varying|text|string)\((\d+)\)", raw)
    if m:
        return {"type": "string", "maxLength": int(m.group(1))}
    if raw in ("text", "string", "nvarchar(max)", "varchar(max)"):
        return {"type": "string"}

    m = re.match(r"(?:decimal|numeric)\((\d+),\s*(\d+)\)", raw)
    if m:
        return {"type": "number", "format": "decimal"}
    if raw in ("decimal", "numeric", "money"):
        return {"type": "number", "format": "decimal"}
    if raw in ("float", "double", "real"):
        return {"type": "number"}

    if raw in ("smallint", "int", "integer"):
        return {"type": "integer", "format": "int32"}
    if raw in ("bigint",):
        return {"type": "integer", "format": "int64"}

    if raw in ("bool", "boolean", "bit"):
        return {"type": "boolean"}

    if raw in ("date",):
        return {"type": "string", "format": "date"}
    if re.match(r"(?:datetime2?|timestamp)(?:\(\d+\))?", raw) or raw == "timestamptz":
        return {"type": "string", "format": "date-time"}

    if raw in ("uuid", "uniqueidentifier"):
        return {"type": "string", "format": "uuid"}

    return {"type": "string"}  # fallback


def parse_dbml(text: str) -> dict:
    """回傳 {'enums': {name: [values]}, 'tables': {Name: {'fields': [...], 'note': str}}}。"""
    enums = {}
    for em in re.finditer(r"Enum\s+(\w+)\s*\{([^}]*)\}", text, re.DOTALL):
        name = em.group(1).lower()
        values = [ln.strip().split()[0] for ln in em.group(2).splitlines() if ln.strip()]
        enums[name] = values

    tables = {}
    field_re = re.compile(r'^\s*"?(\w+)"?\s+([\w\(\),"\s]+?)\s*(?:\[(.*)\])?\s*$')
    note_re = re.compile(r"note:\s*'([^']*)'", re.IGNORECASE)

    # 用平衡括號掃描取出 table body（而非非貪婪 `\{(.*?)\}`）：
    # note / Note 字串內可合法出現 `{` `}`（例 `{zh-TW, en}`、`{true,false}`），
    # 且 body 內含巢狀的 `Indexes { ... }` 區塊——非貪婪 regex 會在第一個 `}` 提早截斷，
    # 導致欄位遺漏。平衡掃描同時跳過單引號字串內的括號，確保 body 完整。
    def extract_bodies(src: str):
        for hm in re.finditer(r"Table\s+\"?(\w+)\"?\s*\{", src):
            name = hm.group(1)
            i = hm.end()
            depth, in_str = 1, False
            start = i
            while i < len(src):
                ch = src[i]
                if in_str:
                    if ch == "'":
                        in_str = False
                elif ch == "'":
                    in_str = True
                elif ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        break
                i += 1
            yield name, src[start:i]

    for table_name, body in extract_bodies(text):
        tbl_note_m = re.search(r"Note:\s*'([^']*)'", body)
        tbl_note = tbl_note_m.group(1) if tbl_note_m else ""

        fields = []
        for line in body.splitlines():
            s = line.strip()
            if not s or s.startswith("//") or s.lower().startswith("note:") or s.startswith("indexes"):
                continue
            fm = field_re.match(s)
            if not fm:
                continue
            fname, ftype, attrs = fm.group(1), fm.group(2).strip(), (fm.group(3) or "")
            is_pk = bool(re.search(r"\bpk\b|primary key", attrs))
            is_required = is_pk or "not null" in attrs
            fnote_m = note_re.search(attrs)
            fields.append({
                "name": fname,
                "schema": dbml_type_to_schema(ftype, enums),
                "required": is_required,
                "pk": is_pk,
                "label": fnote_m.group(1) if fnote_m else "",
            })
        tables[table_name] = {"fields": fields, "note": tbl_note}
    return {"enums": enums, "tables": tables}


# ── naming helpers ───────────────────────────────────────────────────────────

def kebab(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "-", name).replace("_", "-").lower().strip("-")


def pascal(name: str) -> str:
    return "".join(p[:1].upper() + p[1:] for p in re.split(r"[-_\s]+", name) if p)


def camel(name: str) -> str:
    p = pascal(name)
    return p[:1].lower() + p[1:] if p else name


def camel_field(name: str) -> str:
    """DB snake_case → API camelCase（純機械、不改語意）。"""
    return camel(name)


# ── path 推導（遵循 Intent Format Anchor：base = api，用複數）──────────────────

STANDARD_OPS = {
    "list":   ("get",    False),
    "create": ("post",   False),
    "read":   ("get",    True),
    "update": ("put",    True),
    "patch":  ("patch",  True),
    "delete": ("delete", True),
}

# 持久化機制欄位：response/request 都隱藏（內部，非業務語意）
MECH_FIELDS = {"version", "deleted_at"}
# server 生成欄位：response 有、request 無
SERVER_FIELDS = {"created_at", "updated_at", "created_by", "updated_by"}


def _assert_format(intent: dict, file: str) -> None:
    """偵測 anchor 禁止的舊/自創格式，直接報錯擋下（對應 dsl-lint）。"""
    if "endpoints" in intent:
        sys.exit(f"✗ [SCHEMA-002] {file}: 出現自創頂層 `endpoints:`；"
                 f"端點來自 exposes.standard + exposes.operations。")


def build_paths(intent: dict, tables: dict) -> dict:
    file = intent.get("_file", intent.get("api", "<intent>"))
    _assert_format(intent, file)

    entity = intent.get("entity", "")
    base = (intent.get("api") or kebab(entity)).strip("/")
    title = intent.get("title", base)

    exposes = intent.get("exposes", {}) or {}
    standard = exposes.get("standard", []) or []
    operations = exposes.get("operations", []) or []

    paths: dict = {}

    def status_responses(success: str, *, has_id: bool, is_write: bool, conflict: bool) -> dict:
        r = {success: {"description": "成功"}}
        if is_write:
            r["400"] = {"$ref": "#/components/responses/BadRequest"}
        if has_id:
            r["404"] = {"$ref": "#/components/responses/NotFound"}
        if conflict:
            r["409"] = {"$ref": "#/components/responses/Conflict"}
        return r

    def schema_name_for() -> str | None:
        return entity if entity in tables else None

    def emit(path: str, method: str, op_id: str, summary: str, is_custom: bool) -> None:
        has_id = "{id}" in path
        is_write = method in ("post", "put", "patch")
        sn = schema_name_for()

        op = {"operationId": op_id, "summary": summary, "tags": [title]}

        if has_id:
            op["parameters"] = [{
                "name": "id", "in": "path", "required": True,
                "schema": {"type": "string"},
            }]

        if is_write and sn:
            op["requestBody"] = {
                "required": True,
                "content": {"application/json": {
                    "schema": {"$ref": f"#/components/schemas/{sn}Request"}}},
            }

        # success code + body
        if method == "post" and not has_id and not is_custom:
            success = "201"
        elif method == "delete":
            success = "204"
        else:
            success = "200"

        is_list = op_id.startswith("list")
        if method == "delete":
            body_schema = None
        elif is_list and sn:
            body_schema = {"type": "array", "items": {"$ref": f"#/components/schemas/{sn}"}}
        elif sn:
            body_schema = {"$ref": f"#/components/schemas/{sn}"}
        else:
            body_schema = {"type": "object"}

        conflict = method in ("put", "patch", "delete") or is_custom
        responses = status_responses(success, has_id=has_id, is_write=is_write, conflict=conflict)
        if body_schema is not None:
            responses[success]["content"] = {"application/json": {"schema": body_schema}}
        op["responses"] = responses

        paths.setdefault(path, {})[method] = op

    # 標準 CRUD
    for o in standard:
        if o not in STANDARD_OPS:
            sys.exit(f"✗ {file}: 未知 standard 操作 `{o}`（合法：{', '.join(STANDARD_OPS)}）。")
        method, has_id = STANDARD_OPS[o]
        path = f"/{base}/{{id}}" if has_id else f"/{base}"
        emit(path, method, op_id=f"{o}{pascal(entity or base)}",
             summary=f"{o} {entity or base}", is_custom=False)

    # 自訂業務操作
    for o in operations:
        if isinstance(o, str):
            name, method, rel = o, "post", f"/{{id}}/{kebab(o)}"
        elif isinstance(o, dict) and "name" in o:
            name = o["name"]
            method = (o.get("method") or "post").lower()
            rel = o.get("path") or f"/{{id}}/{kebab(name)}"
        else:
            continue
        rel = rel if rel.startswith("/") else f"/{rel}"
        # path 用 base（複數）；operationId 用 entity（單數），與 standard 一致
        emit(f"/{base}{rel}", method, op_id=camel(f"{entity or base}_{name}"),
             summary=name.replace("_", " "), is_custom=True)

    return paths


# ── DTO 雙 schema ─────────────────────────────────────────────────────────────

def build_schemas(tables: dict) -> dict:
    schemas = {}
    for name, tbl in tables.items():
        fields = tbl["fields"]

        def to_props(fs):
            props = {}
            for f in fs:
                p = dict(f["schema"])
                if f["label"]:
                    p["description"] = f["label"]
                props[camel_field(f["name"])] = p
            return props

        resp_fields = [f for f in fields if f["name"] not in MECH_FIELDS]
        req_fields = [f for f in fields
                      if not f["pk"] and f["name"] not in MECH_FIELDS and f["name"] not in SERVER_FIELDS]

        entity_schema = {"type": "object", "properties": to_props(resp_fields)}
        if tbl["note"]:
            entity_schema["description"] = tbl["note"]
        req = [camel_field(f["name"]) for f in resp_fields if f["required"]]
        if req:
            entity_schema["required"] = req

        request_schema = {"type": "object", "properties": to_props(req_fields)}
        rreq = [camel_field(f["name"]) for f in req_fields if f["required"]]
        if rreq:
            request_schema["required"] = rreq

        schemas[name] = entity_schema
        schemas[f"{name}Request"] = request_schema
    return schemas


# ── 共用 components（Error + 標準錯誤 response）──────────────────────────────────

def shared_components() -> dict:
    return {
        "schemas": {
            "Error": {
                "type": "object",
                "required": ["code", "message"],
                "properties": {
                    "code": {"type": "string", "example": "VALIDATION_FAILED"},
                    "message": {"type": "string"},
                    "details": {
                        "type": "array",
                        "items": {"type": "object", "properties": {
                            "field": {"type": "string"},
                            "issue": {"type": "string"}}},
                    },
                },
            }
        },
        "responses": {
            "BadRequest": {"description": "請求參數錯誤",
                           "content": {"application/json": {"schema": {"$ref": "#/components/schemas/Error"}}}},
            "NotFound": {"description": "資源不存在",
                         "content": {"application/json": {"schema": {"$ref": "#/components/schemas/Error"}}}},
            "Conflict": {"description": "衝突（樂觀鎖 / 唯一鍵 / 狀態機）",
                         "content": {"application/json": {"schema": {"$ref": "#/components/schemas/Error"}}}},
        },
    }


# ── assemble ──────────────────────────────────────────────────────────────────

def assemble(intents: list, parsed_dbml: dict, title: str) -> dict:
    tables = parsed_dbml["tables"]
    all_paths = {}
    for h in intents:
        for path, item in build_paths(h, tables).items():
            all_paths.setdefault(path, {}).update(item)

    comp = shared_components()
    comp["schemas"].update(build_schemas(tables))

    return {
        "openapi": "3.0.3",
        "info": {"title": title, "version": "1.0.0"},
        "servers": [{"url": "/api/v1"}],
        "tags": [{"name": h.get("title", h.get("api", "")),
                  "description": h.get("description", "")} for h in intents],
        "paths": all_paths,
        "components": comp,
    }


# ── YAML 輸出（block style）+ $ref 驗證 ─────────────────────────────────────────

class _Dumper(yaml.Dumper):
    # 不要產生 YAML anchor/alias（&id / *id）——OpenAPI 工具與 YAML→JSON 轉換常出錯。
    def ignore_aliases(self, data):
        return True


def _str_repr(dumper, data):
    style = "|" if "\n" in data else None
    return dumper.represent_scalar("tag:yaml.org,2002:str", data, style=style)


_Dumper.add_representer(str, _str_repr)


def dump_yaml(doc: dict) -> str:
    return yaml.dump(doc, Dumper=_Dumper, allow_unicode=True,
                     default_flow_style=False, sort_keys=False, indent=2, width=120)


def validate_refs(doc: dict) -> list:
    """檢查每個 $ref 都解得到（dangling ref = 不可開發的契約）。"""
    errors, refs = [], []

    def walk(node):
        if isinstance(node, dict):
            for k, v in node.items():
                if k == "$ref" and isinstance(v, str):
                    refs.append(v)
                else:
                    walk(v)
        elif isinstance(node, list):
            for x in node:
                walk(x)

    walk(doc)
    for ref in refs:
        if not ref.startswith("#/"):
            continue
        cur = doc
        for part in ref[2:].split("/"):
            if isinstance(cur, dict) and part in cur:
                cur = cur[part]
            else:
                errors.append(ref)
                break
    return sorted(set(errors))


# ── CLI ─────────────────────────────────────────────────────────────────────

def load_intents(path: Path) -> list:
    files = [path] if path.is_file() else sorted(path.glob("*.intent.yaml"))
    out = []
    for p in files:
        with open(p, encoding="utf-8") as f:
            data = yaml.safe_load(f)
        data["_file"] = str(p)
        out.append(data)
    return out


def main():
    ap = argparse.ArgumentParser(description="intent DSL → OpenAPI 3.0.3 (minimal)")
    ap.add_argument("--intent", required=True, help="*.intent.yaml 檔或目錄")
    ap.add_argument("--dbml", required=True, help="annotated DBML 檔")
    ap.add_argument("--output", required=True, help="輸出 openapi.yaml 路徑")
    ap.add_argument("--title", default="API", help="API 標題")
    args = ap.parse_args()

    intent_path, dbml_path, out_path = Path(args.intent), Path(args.dbml), Path(args.output)
    for p, kind in [(intent_path, "intent"), (dbml_path, "dbml")]:
        if not p.exists():
            sys.exit(f"[ERROR] {kind} 不存在: {p}")

    parsed = parse_dbml(dbml_path.read_text(encoding="utf-8"))
    print(f"[1/3] DBML: {len(parsed['tables'])} tables, {len(parsed['enums'])} enums")

    intents = load_intents(intent_path)
    print(f"[2/3] intent: {len(intents)} modules ({', '.join(h.get('api','?') for h in intents)})")

    doc = assemble(intents, parsed, title=args.title)
    refs_bad = validate_refs(doc)
    if refs_bad:
        sys.exit("[ERROR] dangling $ref:\n  " + "\n  ".join(refs_bad))

    n_ops = sum(len([m for m in v if m in ("get", "post", "put", "patch", "delete")])
                for v in doc["paths"].values())
    print(f"[3/3] OpenAPI: {len(doc['paths'])} paths, {n_ops} operations, "
          f"{len(doc['components']['schemas'])} schemas — all $ref resolved ✓")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(dump_yaml(doc), encoding="utf-8")
    print(f"[OK] → {out_path}")
    print(f"     預覽: npx @redocly/cli preview-docs {out_path}")


if __name__ == "__main__":
    main()
