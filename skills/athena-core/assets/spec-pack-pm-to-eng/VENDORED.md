# Vendored 來源與同步

- **來源**：內部 `athena-skills` 目錄（keer.huang 維護的 PM→工程文件 skill 集；vendor 當時尚未版控）
- **Vendor 日期**：2026-07-17
- **來源版控狀態**：vendor 當時來源**不是 git repo**（無 commit hash 可釘）。
  建議來源目錄 `git init` 後在此補記 hash，否則漂移無從比對。

## 帶了什麼、沒帶什麼

| 項目 | 處置 | 原因 |
|------|------|------|
| `score` `clarify` `data_model` `class_diagram` `db_table` `api` `screens` `ui_contract` `gherkin` | ✅ vendor 至 `phases/<name>/` | 9 個 phase skill 本體 |
| `pm-to-eng-flow/references/` | ✅ vendor 至 `phases/pm-to-eng-flow/references/` | phase skills 以 `../pm-to-eng-flow/references/` 相對路徑引用，保留 sibling 佈局使引用不斷鏈 |
| `pm-to-eng-flow/SKILL.md` | ❌ 不帶 | 編排職責由本 pack 根目錄的 `SKILL.md`（stage: spec wrapper）取代，帶了會出現兩個編排器 |
| `arguments.yml` `Index.md` | ❌ 不帶 | 設定改併入 consumer 專案 `specs/arguments.yml` 的 `spec_pack:` 段，避免同名設定檔並存 |
| `design-prototype/` | ❌ 不帶 | 大型範例專案且**內嵌 .git**，複製進 plugin repo 會出事 |
| `doc-requirement/` | ❌ 不帶 | PM 需求單樣例，非 skill 本體 |
| `.DS_Store` `__pycache__` | ❌ 排除 | 雜物 |

## 對 vendored 檔案做過的機械轉換

1. `eng-output/` → `specs/`（全部文字檔，含 `openapi.py` docstring）——
   對齊 spec stage shell 的 Write 範圍（只允許 `specs/` 與 `handoffs/`）。

除此之外 vendored 檔案**零改動**。重新同步時 diff 若出現非此轉換的差異，
即為上游演進或本地漂移，需人工裁決。

## 重新同步腳本

```bash
cd <plugin-root>
PACK=skills/athena-core/assets/spec-pack-pm-to-eng
SRC=<athena-skills 路徑>
for d in score clarify data_model class_diagram db_table api screens ui_contract gherkin; do
  rsync -a --delete --exclude='.DS_Store' --exclude='__pycache__' $SRC/$d/ $PACK/phases/$d/
done
rsync -a --delete --exclude='.DS_Store' $SRC/pm-to-eng-flow/references/ $PACK/phases/pm-to-eng-flow/references/
# 只轉換 vendored 檔（$PACK/phases/）——pack 根層的 SKILL.md / README / VENDORED
# 是本 repo 原創，含「eng-output」meta 描述文字，不得被 sed 掃到
grep -rl 'eng-output' $PACK/phases | xargs sed -i '' 's|eng-output/|specs/|g'
grep -rn 'eng-output' $PACK/phases && echo '⚠️ 替換不完整' || echo '✅ 同步完成'
```

同步後：更新本檔的 Vendor 日期（與 hash，若來源已 git init），並重跑
dogfood 安裝（`.athena/skills/pm-to-eng-spec/` 整目錄重拷）。

## 變更紀錄

- 2026-07-17：初次 vendor（wrapper SKILL.md 為本 repo 原創，非 vendored）
