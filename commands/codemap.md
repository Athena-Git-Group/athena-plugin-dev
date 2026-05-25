---
description: 一鍵替專案生成 graphify codemap — 自動補齊安裝步驟，最後 delegate 給 /graphify skill 產出 graph.html / GRAPH_REPORT.md / graph.json
argument-hint: <目標路徑，預設為 "."；可加 flag 如 --update / --wiki / --svg>
---

Generate a codebase knowledge graph by ensuring [graphify](https://github.com/safishamsi/graphify) is set up, then delegating to Claude Code's registered `/graphify` skill.

> **重要**：本指令透過 Claude Code 內已註冊的 `/graphify` skill 執行（Claude 即 LLM），**不需設定 LLM API key**。只有在 shell 直接跑 `graphify <path>`（例如 CI）才需要 `ANTHROPIC_API_KEY` 等。

## Why this command exists

很多人裝完 graphify 後忘了真的去執行 `/graphify .`，結果什麼都沒產出。
`/codemap` 是一鍵整合包：**先把 setup 補齊，再強制走一次產出**。

Setup 是一次性的，產出每次跑都要做一次。

---

## Phase A — Setup（一次性，已完成則跳過）

### Step 1. 檢查 `graphify` CLI 是否已安裝

```bash
command -v graphify && graphify --version
```

若未安裝，**停下來提示使用者**自行安裝（系統層級變更需經使用者同意，不要自動執行）：

```bash
uv tool install graphifyy        # 推薦
# 或 pipx install graphifyy
# 或 pip install graphifyy
```

安裝完請使用者重跑 `/codemap`。**不要繼續往下做。**

> PATH 提醒：plain `pip` 可能需要把 `~/.local/bin`（Linux）或 `~/Library/Python/3.x/bin`（macOS）加入 shell PATH；`uv` / `pipx` 會自動處理。

### Step 2. 檢查 graphify skill 是否已註冊到 Claude Code

依 OS 自動偵測對應路徑與安裝旗標：

| OS                                  | Skill 路徑                              | 安裝指令                              |
| ----------------------------------- | --------------------------------------- | ------------------------------------- |
| macOS / Linux (`Darwin` / `Linux`)  | `~/.claude/skills/graphify`             | `graphify install`                    |
| Windows (`MINGW*` / `MSYS*` / `CYGWIN*`) | `%USERPROFILE%\.claude\skills\graphify` | `graphify install --platform windows` |

判定邏輯（bash 範例）：
```bash
case "$(uname -s)" in
  Darwin|Linux)         GRAPHIFY_PLATFORM_FLAG="" ;;
  MINGW*|MSYS*|CYGWIN*) GRAPHIFY_PLATFORM_FLAG="--platform windows" ;;
  *)                    GRAPHIFY_PLATFORM_FLAG="" ;;
esac
```

若對應 skill 目錄不存在：
1. **先得到使用者同意**（會寫入使用者層級設定 `~/.claude/skills/`）。
2. 執行 `graphify install $GRAPHIFY_PLATFORM_FLAG`。
3. 安裝後若 Claude Code 在當前 session 看不到 `graphify` skill（available skills 清單中沒有），請使用者**重啟 Claude Code session** 再重跑 `/codemap`，**不要繼續往下做**。

> 註：其他 AI 平台（Codex、Cursor、Gemini CLI、OpenCode、Copilot CLI 等）有各自的 `graphify install --platform <name>` 旗標；本指令鎖定 Claude Code，不自動切換。

---

## Phase B — Generate（每次都跑）

### Step 3. Delegate 給 `/graphify` skill，實際產生 codemap

**不要**從 shell 直接呼叫 `graphify <path>`（那會嘗試 spawn 外部 LLM，需要 API key）。
**改為**用 Skill 工具呼叫已註冊的 `graphify` skill，將 `$ARGUMENTS` 原封不動傳入（若為空則傳 `.`）：

```
Skill(skill="graphify", args="${ARGUMENTS:-.}")
```

由 `/graphify` skill 內部的 SKILL.md 步驟負責 extraction、clustering、視覺化等工作；Claude 本身作為 LLM，無需 API key。

> 這步是核心：**安裝完不執行 `/graphify .`，是不會有任何產出的**。`/codemap` 的價值就是把這步幫使用者跑掉。

### Step 4. 回報產出位置

完成後告知使用者：

```
graphify-out/
├── graph.html       # 互動式視覺化（瀏覽器開啟，可點擊節點/搜尋/篩選）
├── GRAPH_REPORT.md  # 重點摘要與洞察
└── graph.json       # 完整 graph，供 /graphify query 使用
```

並建議使用者：
- 在瀏覽器開啟 `graphify-out/graph.html` 來瀏覽。
- 後續查詢直接在對話中跑：`/graphify query "<question>"` / `/graphify explain "<entity>"` / `/graphify path "A" "B"`。
- 程式碼變更後做增量更新：`/graphify . --update`。

---

## Notes

- 此指令不修改 codebase（只產生 `graphify-out/`），**不需走 `/athena-point`**。
- 若使用者真的要在 shell / CI 直跑 `graphify <path>`，才需要設定 `ANTHROPIC_API_KEY` 等 LLM key — 但這不是 `/codemap` 的預設路徑。
- Phase A 是冪等的：CLI 已裝、skill 已註冊，會自動跳過，直接進 Phase B。

Request:

$ARGUMENTS
