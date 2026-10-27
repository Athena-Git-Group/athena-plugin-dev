# 訪談引擎：grill-with-docs（拷問式工作坊）

> 這是 clarify 階段的**訪談引擎**：定義「怎麼問、問到多精確」。
> 它**不**負責 clarify 的輸入/輸出 artifact 與 STATUS gate——那由 `../SKILL.md` 掌管。
> 原為獨立 skill，此處改寫為 clarify 的內部 reference。

## 要做的事

針對這份需求/計畫的每個面向，不留情地訪談使用者，直到達成共識。沿著設計樹的
每個分支往下走，逐一解決決策之間的相依關係。**每個問題都附上你建議的答案。**

一次只問一個問題，每題都等使用者回饋後再繼續。

如果某個問題可以靠探索 codebase 得到答案，先自行探索，不要直接把它丟給使用者問。
**探索 codebase 時，優先用 graphify（見下節），而不是一上來就 grep / 讀整檔。**
但探索得到的結論**不是定論**：整理後一定要回頭跟使用者確認「是不是這樣」，
不要擅自據此做決定。

## 用 graphify 探索 codebase（優先）

> **探索 ≠ 定論。** 用 codebase 查到的任何結論，都要先自行探索、整理，再回頭跟使用者
> 確認「是不是這樣」——不要擅自把探索結果當成已確認的事實去推進。

**使用前提：** 先確認專案根目錄是否存在 `graphify-out/graph.json`。
- 存在 → 直接用下列唯讀查詢，**不要**重建圖。
- 不存在 → 退回傳統 grep / Read；是否先建圖由使用者決定，不要擅自跑重建。

**唯讀查詢指令（擇一）：**

```bash
graphify query "<自然語言問題>"            # BFS 廣度遍歷，拿廣脈絡（X 怎麼運作、誰呼叫 Y）
graphify query "<問題>" --dfs              # DFS，追一條特定路徑 / 資料流
graphify query "<問題>" --budget 1500      # 把答案壓在 N tokens 內（省 token）
graphify path "概念A" "概念B"              # 兩個概念之間的最短路徑（釐清關係的利器）
graphify explain "節點名稱"                # 用白話解釋某個節點
```

**對應到訪談的用法：**
- 「這題能不能靠 codebase 回答」→ 先用 `graphify query` 自行探索；把整理後的發現
  回頭跟使用者確認，不要擅自當定論。
- 要釐清兩個概念的關係 / 邊界 → `graphify path "A" "B"`，比猜測或翻檔更全面。
- 不確定某個術語在程式裡到底是什麼 → `graphify explain "Term"`。

## 領域意識（Domain awareness）— 選用增益

> 以下整段僅在「專案已有既有 codebase / 領域文件」時啟用。
> 純 greenfield 的 PM 需求沒有可比對的程式碼或 CONTEXT.md 時，整段跳過。

探索 codebase 時，也要一併尋找既有的文件。

### 檔案結構

多數 repo 只有單一 context：

```text
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

若根目錄存在 `CONTEXT-MAP.md`，代表這個 repo 有多個 context。這份 map 指出
每個 context 各自的所在位置：

```text
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← 系統層級的決策
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← 該 context 專屬的決策
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

惰性建檔——只有當你真的有東西要寫時才建。若不存在 `CONTEXT.md`，在第一個術語
被釐清時才建立它。若不存在 `docs/adr/`，在第一份 ADR 需要時才建立。

## 工作坊進行中

### 用詞彙表（glossary）挑戰

當使用者用的術語與 `CONTEXT.md` 既有語言衝突時，立刻指出。
「你的詞彙表把『取消』定義為 X，但你現在的意思像是 Y——到底是哪個？」

### 磨利模糊的語言

當使用者用了模糊或一詞多義的字眼，提出一個精確的標準術語。
「你說『account』——你指的是 Customer 還是 User？這是兩回事。」

### 討論具體情境

當在討論領域關係時，用具體情境做壓力測試。發明能探測邊界案例的情境，
逼使用者把概念之間的界線講精確。

### 與程式碼交叉比對（選用增益）

當使用者陳述某件事如何運作時，檢查程式碼是否同意。優先用 `graphify query` /
`graphify path` 拉出實際的呼叫關係與資料流，再比對使用者的說法。若發現矛盾，攤開來講：
「你的程式碼取消整張 Order，但你剛說可以部分取消——哪個才對？」

### 即時更新 CONTEXT.md（選用增益）

當一個術語被釐清，就地更新 `CONTEXT.md`。不要累積成批，發生當下就記下。

`CONTEXT.md` 必須完全不含實作細節。不要把它當成規格、草稿紙，或實作決策的倉庫。
它就是一份詞彙表，僅此而已。

> 格式見同目錄的 `CONTEXT-FORMAT.md` 與 `ADR-FORMAT.md`。clarify 的主要產出是
> `clarified.md`，CONTEXT.md / ADR 只是選用增益。

### 謹慎地提議 ADR（選用增益）

只有當以下三點**同時**成立時，才提議建立 ADR：

1. **難以反轉**——日後改變心意的成本不容小覷
2. **缺乏脈絡會令人意外**——未來的讀者會納悶「他們當初為什麼這樣做？」
3. **是真實取捨的結果**——當時確有其他可行選項，而你基於特定理由選了這個

只要三者缺一，就略過 ADR。
