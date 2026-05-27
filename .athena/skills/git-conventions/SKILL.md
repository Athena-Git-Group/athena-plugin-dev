---
name: git-conventions
user-invocable: false
description: >
  建立 Git 分支或撰寫 commit message 時使用。提供標準化的 Git 工作流規範，
  包含分支命名與 commit message 格式。觸發詞：branch naming、commit message、
  git branch、git commit、HAP ticket、feature branch、bugfix branch、hotfix branch、
  commit convention、分支命名、提交訊息。
---

# Git Conventions

Git 分支命名與 Commit Message 規範，確保團隊協作的一致性與可追溯性。

## When to Use

- **建立新分支** - 使用標準分支命名格式
- **撰寫 commit message** - 使用標準 commit 格式
- **Code review** - 檢查分支和 commit 是否符合規範

---

## Branch Naming

### Format

```
<type>/<source>_<description>
<type>/<source>_hap<ticket>_<description>
```

### Branch Types

| Type | 用途 | 範例（有 HAP） | 範例（無 HAP） |
|------|------|----------------|----------------|
| `feature/` | 新功能開發 | `feature/main_hap3621_member_export` | `feature/develop_member_export` |
| `bugfix/` | 一般錯誤修復 | `bugfix/develop_hap3449_tier_calculation` | `bugfix/develop_tier_calculation` |
| `hotfix/` | 緊急線上修復 | `hotfix/main_hap5678_fix_critical_bug` | `hotfix/main_fix_payment_error` |
| `refactor/` | 程式碼重構 | `refactor/main_hap3600_cleanup_service` | `refactor/main_cleanup_service` |
| `chore/` | 雜項（文檔、CI/CD、Skill 調整等） | — | `chore/main_update_cicd_pipeline` |

### Source Branch

來源分支標示此分支從哪裡切出：

| Source | 說明 |
|--------|------|
| `main` | 從 main 切出 |
| `master` | 從 master 切出 |
| `develop` | 從 develop 切出 |
| `release` | 從 release 切出 |

### Naming Rules

1. **全部小寫** - 使用小寫字母
2. **底線分隔** - 描述部分使用 `_` 分隔
3. **簡潔明瞭** - 描述應簡短但能表達意圖
4. **Ticket 可選** - HAP ticket 號碼為可選，有則加入

### Examples

```bash
# 有 HAP ticket
git checkout -b feature/main_hap3621_member_export
git checkout -b bugfix/develop_hap3449_tier_calculation
git checkout -b hotfix/main_hap5678_fix_critical_bug
git checkout -b refactor/main_hap3600_cleanup_service

# 無 HAP ticket
git checkout -b feature/develop_member_export
git checkout -b bugfix/develop_fix_null_pointer
git checkout -b hotfix/main_fix_payment_error
git checkout -b refactor/main_cleanup_legacy_code

# 版本升級（v2 變體）
git checkout -b feature/main_hap3621_member_export_v2
```

---

## Commit Convention

### Format

```
# 分支有 HAP ticket 時
[HAP-XXXX] type(scope): 簡述

# 分支無 HAP ticket 時
type(scope): 簡述
```

### Commit Types

| Type | 用途 | 範例（有 HAP） | 範例（無 HAP） |
|------|------|----------------|----------------|
| `feat` | 新功能 | `[HAP-1234] feat(member): add export API` | `feat(member): add export API` |
| `fix` | Bug 修復 | `[HAP-1234] fix(tier): correct calculation` | `fix(tier): correct calculation` |
| `docs` | 文件更新 | `[HAP-1234] docs(api): update swagger spec` | `docs(api): update swagger spec` |
| `refactor` | 重構 | `[HAP-1234] refactor(service): extract helper` | `refactor(service): extract helper` |
| `test` | 測試相關 | `[HAP-1234] test(member): add unit tests` | `test(member): add unit tests` |
| `chore` | 維護性工作 | `[HAP-1234] chore(deps): update dependencies` | `chore(deps): update dependencies` |

### Scope Guidelines

Scope 應反映變更的模組或領域：

| Scope | 說明 |
|-------|------|
| `member` | 會員模組 |
| `tier` | 等級模組 |
| `points` | 積分模組 |
| `api` | API 層 |
| `db` | 資料庫相關 |
| `config` | 配置相關 |
| `deps` | 依賴套件 |

### Commit Message Rules

1. **簡述用祈使句** - 使用動詞開頭（add, fix, update, remove）
2. **簡述限制 50 字元** - 保持簡潔
3. **首字母小寫** - type 後的簡述首字母小寫
4. **不加句號** - 簡述結尾不加標點符號
5. **語言偏好** - 簡述可使用用戶配置的語言

### Language Support

**參考 `references/output-language.md`** 以取得用戶語言偏好：

```bash
# 使用共用 script 讀取語言設定（優先順序：Local > Project > User）
OUTPUT_LANG=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/get_athena_setting.py" athena language --default "English")
```

Commit message 的簡述可依語言偏好撰寫：

```bash
# 英文（預設）
git commit -m "[HAP-3621] feat(member): add member export API"

# 繁體中文
git commit -m "[HAP-3621] feat(member): 新增會員匯出 API"

# 日文
git commit -m "[HAP-3621] feat(member): メンバーエクスポートAPIを追加"
```

**注意**：type 和 scope 保持英文，僅簡述部分可使用其他語言。

### Examples

```bash
# === 分支有 HAP ticket 時 ===
git commit -m "[HAP-3621] feat(member): add member export API"
git commit -m "[HAP-3449] fix(tier): correct upgrade calculation logic"
git commit -m "[HAP-3600] refactor(service): extract common validation"

# === 分支無 HAP ticket 時 ===
git commit -m "feat(member): add member export API"
git commit -m "fix(tier): correct upgrade calculation logic"
git commit -m "refactor(service): extract common validation"
git commit -m "docs(readme): update changelog for v1.2.4"
git commit -m "chore: bump version to 1.2.4"
```

---

## Ticket Number Inference

### 從分支名稱自動擷取

當前分支格式為 `<type>/<source>_hap<ticket>_<description>` 時，可自動推斷 ticket 號碼：

```bash
# 取得當前分支
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 擷取 ticket 號碼
TICKET=$(echo "$BRANCH" | grep -oP '(?<=hap)\d+' | head -1)

# 格式化為 commit prefix
PREFIX="[HAP-${TICKET}]"
```

### 範例推斷

| 分支名稱 | 推斷的 Ticket |
|----------|---------------|
| `feature/main_hap3621_member_export` | `[HAP-3621]` |
| `bugfix/develop_hap3449_tier_calculation` | `[HAP-3449]` |
| `feature/main_hap3621_v2` | `[HAP-3621]` |

---

## Quick Reference

### Create Feature Branch

**建立分支前必須先同步遠端 base 分支**，確保從最新版本開始開發：

```bash
# 1. 切換到 base 分支（通常是 main 或 develop）
git checkout main

# 2. 同步遠端最新變更
git pull origin main

# 3. 建立新分支
git checkout -b feature/main_hap<TICKET>_<description>
```

**單行版本**（適合熟練使用者）：

```bash
git fetch origin main && git checkout -b feature/main_hap<TICKET>_<description> origin/main
```

> **為什麼要先同步？**
> - 避免基於過時程式碼開發，減少後續合併衝突
> - 確保包含其他人已合併的變更
> - 保持分支歷史乾淨

### Commit with Convention

```bash
git commit -m "[HAP-<TICKET>] <type>(<scope>): <description>"
```

### Full Workflow Example

```bash
# 1. 同步遠端 base 分支
git checkout main
git pull origin main

# 2. 建立功能分支
git checkout -b feature/main_hap3621_member_export

# 3. 開發並提交
git add .
git commit -m "[HAP-3621] feat(member): add member export API"

# 4. 追加提交
git commit -m "[HAP-3621] test(member): add export unit tests"
git commit -m "[HAP-3621] docs(api): document export endpoint"

# 5. 推送前再次同步（可選，減少 PR 衝突）
git fetch origin main
git rebase origin/main  # 或 git merge origin/main
```

---

## Validation Checklist

### Branch Name

- [ ] 使用正確的 type (`feature/`, `bugfix/`, `hotfix/`, `refactor/`, `chore/`)
- [ ] 包含來源分支 (`main`, `master`, `release`, `develop`)
- [ ] 若有 HAP ticket，格式為 `hap<number>_`
- [ ] 描述簡潔明瞭
- [ ] 全部小寫

### Commit Message

- [ ] 若分支有 HAP，包含 `[HAP-XXXX]` prefix
- [ ] 使用正確的 type (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`)
- [ ] 包含有意義的 scope
- [ ] 簡述使用祈使句
- [ ] 簡述首字母小寫

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.2.0 | 2026-01 | 新增建立分支前同步遠端 base 分支的指引 |
| 1.1.0 | 2026-01 | 補充無 HAP ticket 時的 commit message 範例 |
| 1.0.0 | 2026-01 | Initial release |
