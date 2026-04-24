# Mock Environment

定義 Phase A（建立 mock 環境）與 Phase D（清理）的規範。

## 設計原則

1. **完全隔離**：使用系統 temp dir（如 macOS 的 `/var/folders/.../T/`）
2. **可拋棄**：每次 eval 完整 `rm -rf` 清掉
3. **可觀察**：sub-agent 違反隔離時可選擇保留 temp dir 給人除錯

## 建立 temp dir

```bash
TEMP_DIR=$(mktemp -d -t athena-eval-XXXXXX)
echo "Temp dir: $TEMP_DIR"
# 範例輸出：/var/folders/35/.../T/athena-eval-aBc123
```

eval runner 必須**記錄這個絕對路徑**，整個流程都用它。
不可用相對路徑、不可依賴 `cd`（Bash 跨 call 不持久 — Phase 0 spike 已驗證）。

## 寫入 mock files

從 case 的 `## Setup` 段解析每個檔案區塊。Setup 區塊的格式為：

````markdown
`<relative-file-path>`:
```
<verbatim file content>
```
````

對應的寫入操作：

```bash
mkdir -p "$TEMP_DIR/$(dirname <relative-file-path>)"
cat > "$TEMP_DIR/<relative-file-path>" <<'EOF'
<verbatim file content>
EOF
```

### 範例

case Setup：

````markdown
## Setup

`points/typo-fix.md`:
```
- Summary: 修正 README L23 typo
- Verdict: PASS-DIRECT-BUILD
```

`README.md`:
```
# Project
This is our memberhip program.
```
````

寫入：

```bash
mkdir -p "$TEMP_DIR/points"
cat > "$TEMP_DIR/points/typo-fix.md" <<'EOF'
- Summary: 修正 README L23 typo
- Verdict: PASS-DIRECT-BUILD
EOF

cat > "$TEMP_DIR/README.md" <<'EOF'
# Project
This is our memberhip program.
EOF
```

> 用 `<<'EOF'`（單引號 EOF）避免 shell 變數插值，確保 verbatim 寫入。

### 寫入後驗證

```bash
find "$TEMP_DIR" -type f
```

確認所有 case Setup 列出的檔案都已就位。

## 隔離保證

- ✅ 在 system temp dir 下，與使用者真實 repo 完全分離
- ✅ Sub-agent 用相對路徑時只影響它自己的 cwd（不影響 parent process / user repo）
- ⚠️ 仍依賴 sub-agent 不主動用絕對路徑寫到使用者真實 repo（無法強制，靠 Executor prompt 約束）

## 隔離違規偵測

執行 sub-agent 前後，比對使用者真實 repo 的 git status：

```bash
USER_REPO="<absolute path to user repo>"

# Phase A 結束時
git -C "$USER_REPO" status --porcelain > "$TEMP_DIR/.before_status"

# Phase B 結束時
git -C "$USER_REPO" status --porcelain > "$TEMP_DIR/.after_status"

# 比對
diff "$TEMP_DIR/.before_status" "$TEMP_DIR/.after_status"
```

差異中出現的檔案 → `isolation_violations` 列表 → Grader 在報告中標 🟡 警告。

## 清理（Phase D）

```bash
rm -rf "$TEMP_DIR"
ls "$TEMP_DIR" 2>&1   # 應回 No such file or directory
```

### 清理時機

| 狀況 | 清理時機 |
|------|---------|
| Eval 成功 | 自動清 |
| Eval 失敗（runner internal error） | 自動清 |
| Sub-agent timeout | 自動清 |
| Sub-agent 違反隔離邊界 | **保留 temp dir**（給人除錯），輸出 absolute path |
| 使用者中斷（Ctrl-C） | 不保證清理（best effort） |

### 保留 temp dir 時的提示

```
⚠️ 為了除錯，本次 eval 的 temp dir 已保留：
   /var/folders/.../T/athena-eval-aBc123
   檢查完請手動 rm -rf 該目錄。
```

## 為什麼不用 git stash + apply

- stash 會動到使用者真實 repo 的 git 狀態，風險高
- temp dir 純加法、無副作用
- temp dir 跨 case 不共用，避免污染

## 為什麼不用 docker / sandbox

- 啟動成本高（plugin skill 不該假設環境有 docker）
- 對純 markdown skill 來說 over-engineered
- temp dir + sub-agent prompt 約束已足夠

## 跨平台注意事項

- **macOS**：`mktemp -d` 預設在 `/var/folders/...`
- **Linux**：`mktemp -d` 預設在 `/tmp/...`
- **Windows**：本 plugin 不官方支援；若使用者環境特殊，靠 `mktemp` 抽象處理

`-t` 參數提供 prefix（`athena-eval-`），方便事後辨識遺留 temp dir。
