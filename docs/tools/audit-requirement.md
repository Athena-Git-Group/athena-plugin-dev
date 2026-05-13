# PM 需求驗收（athena-audit-requirement-{frontend,backend}）

> 與 `/athena-point` 不同 —— 這對工具是**團隊主動觸發**的「PM 需求單可譯性審計工具」，**不是 plugin 強制執行的閘門**。沒跑 audit-requirement 不會阻擋任何 build 或合併動作。

對 **PM 寫的需求單**做「可譯性審計」 — 檢查 RD 看完能否機械萃取出工程原料。
低分結果是**退回 PM 補資訊**，不是阻擋 RD 工程流程。

雙產出：
1. 對話中三段式建議報告（✅ / 🟡 / 💡，**無 PASS/FAIL**）
2. 寫入 `requirement-feedback/<slug>-{frontend|backend}.md` 的 PM-friendly 澄清問題清單（可逐題補答後重跑 audit）

## 用法

```bash
# 後端視角 — 看資料 / API / 業務規則 / 驗證 / 整合點
/athena-dev-plugin:athena-audit-requirement-backend <path-to-prd.md>
/athena-dev-plugin:athena-audit-requirement-backend <path-to-prd.md> --slug=收藏功能

# 前端視角 — 看角色 / 畫面 / 互動 / 視覺驗收 / 導航
/athena-dev-plugin:athena-audit-requirement-frontend <path-to-prd.md>
/athena-dev-plugin:athena-audit-requirement-frontend <path-to-prd.md> --slug=收藏功能
```

也支援直接貼文字（無檔案路徑時）。Slug 推斷規則：使用者 `--slug` > PM 文件 H1 > 檔名 > `untitled-<timestamp>`。

## 後端 vs 前端視角

兩個工具獨立可用，同份需求各跑一次無衝突，互補產出兩份 feedback doc。

| 維度 | 後端視角看的 | 前端視角看的 |
|------|------------|------------|
| 「使用者」 | 帳號資料屬性 / 權限 | 角色 / 畫面差異 / 訪客行為 |
| 「流程」 | command/query 邊界 / 觸發者 | 畫面跳轉 / 互動順序 / entry 點 |
| 「資料」 | 實體可辨識性 / 屬性 / 關聯 | 畫面要顯示哪些資訊 |
| 「狀態」 | 資料狀態（草稿/已送出/已取消） | UI 狀態（loading/empty/error） |
| 「規則」 | 業務規則完整度（happy/unhappy/edge） | 互動細節 / 禁用條件 |
| 「驗證」 | 後端格式 / 範圍 / 唯一性 | 輸入時的 UI 提示與訊息文案 |
| 「失敗」 | 例外處理 / 重試 / 回滾 | 錯誤訊息畫面 / 文案 |
| 「整合」 | 外部系統 / side effects | 重新整理 / 返回 / 網址分享 |

## PM Feedback 文件範例路徑

```
<project>/requirement-feedback/
├── 收藏功能-backend.md
├── 收藏功能-frontend.md
├── 訂單退款流程-backend.md
└── ...
```

文件採 PM-friendly 業務語言（禁用 RD 術語如 endpoint / schema / component / state），每份含「整體觀察 → ✅ 已給足 → 🟡 需補完 → 💡 進階建議 → 逐題澄清清單（含 PM 補答區）」。

## 與其他 skill 的邊界

| 比較對象 | 差別 |
|---------|------|
| `athena-point` | point 對 **RD** 做工程分流（決定要不要 spec），audit-requirement 對 **PM** 做需求驗收（決定 PM 要不要補資訊）；point 寫機器 verdict 給 flow gate 用，audit-requirement 純對話 + PM-friendly 文字，無 verdict |
| `athena-skill-audit` | 那個 audit 看 **SKILL.md** 結構（給 RD 寫 skill 用），audit-requirement 看 **PM 需求文件**（給 PM 寫 PRD 用） |
| `athena-skill-eval` | eval 看 **skill 跑出來行為對不對**，audit-requirement 看 **PM 需求文件本身寫得夠不夠** |
| `/flow` | flow 是 RD 工程編排，audit-requirement 在 flow **之前**由 PM/TL 主動使用 |
| `athena-audit-requirement-backend` vs `-frontend` | 同類工具的兩個視角，並列、互補；同需求各跑一次無衝突 |

> **與 `athena-point` 的更深劃線**：兩者都看「需求清不清楚」，但 point 的 Requirement Clarity 維度服務 **RD 工程分流**（低分 → 走 spec 重寫），audit-requirement 服務 **PM 需求驗收**（低分 → 退回 PM 補資訊，可重跑）。一次需求週期可同時用兩個工具：先給 PM 跑 audit-requirement 補完需求，再給 RD 跑 point 決定走哪條工程路線。

---

← 回 [README](../../README.md)
