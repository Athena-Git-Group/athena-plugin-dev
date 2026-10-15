# Output Language

用戶語言偏好設定，供 Git commit message 等需要語言選擇的場景使用。

## 讀取優先順序

Local > Project > User

```bash
# 本 plugin 未附帶此 script，不存在時用預設 English
OUTPUT_LANG=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/get_hxde_setting.py" hxde language --default "English" 2>/dev/null || echo "English")
```

## 支援語言

| 語言 | 設定值 | 範例 commit 簡述 |
|------|--------|------------------|
| English | `English` | `add member export API` |
| 繁體中文 | `zh-TW` | `新增會員匯出 API` |
| 日本語 | `ja` | `メンバーエクスポートAPIを追加` |

## 適用範圍

- Commit message 的 **簡述部分**（type 和 scope 保持英文）
- Branch name 一律使用英文小寫
- Handoff artifact 一律使用英文

## 預設值

若未設定或讀取失敗，預設為 `English`。
