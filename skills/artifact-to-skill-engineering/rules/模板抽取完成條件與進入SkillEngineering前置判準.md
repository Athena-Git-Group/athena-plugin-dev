# Rule 1 - template 抽取完成後必須同時具備骨架檔與範例檔

- Level: `MUST`
- 進入 skill engineering 前，必須已完成同主題、同格式的 template 雙檔：骨架檔與範例檔。
- 骨架檔負責固定結構與可變槽位；範例檔負責展示已定稿 example 的完整樣貌。兩者缺一不可。
- 若只存在 example、只有骨架、或雙檔內容責任混淆，表示 template 抽取尚未完成。

## Good Example

- 這個例子是好的，因為它同時提供骨架與範例，後續 skill 才有明確的目標 artifact。

````md
templates/spec.template.md
templates/spec.example.md
````

## Bad Example

- 這個例子是壞的，因為它只有範例，還沒有完成可工程化的模板雙檔。

````md
templates/spec.example.md
````

# Rule 2 - template 必須忠實反映已定稿 example，而不是在抽取階段偷偷改需求

- Level: `MUST`
- template 抽取的責任是把已定稿 example 轉成「固定結構 + 可變槽位」，不是重新設計 artifact。
- 若抽 template 時發現還想回頭更改章節、欄位、需求邏輯或例外結構，表示 example 其實尚未定稿，應回到上一階段，而不是在 template 階段偷改。
- 進入 skill engineering 前，應確認骨架與範例皆對應同一份已定稿 example。

## Good Example

- 這個例子是好的，因為 template 只抽象化已確認好的 artifact，不另外發明新結構。

````md
已定稿 example：
- User Story 底下包含 Acceptance Criteria、FR、NFR
- 需求區只保留全域需求

抽出的 template：
- 保留相同章節結構
- 只把內容替換成填位符號
````

## Bad Example

- 這個例子是壞的，因為它利用 template 抽取階段偷偷重設 artifact 結構。

````md
已定稿 example：
- 全域需求只留跨故事需求

抽 template 時改成：
- 重新新增獨立的 FR / NFR 總表
````

# Rule 3 - 只有當 artifact 結構已穩定，skill engineering 才有意義

- Level: `SHOULD`
- skill engineering 的目標是反推出「如何高可靠度產出這種 artifact」的流程與規則；若 artifact 結構本身仍頻繁變動，過早進入這一階段只會導致 target skill 很快失真。
- 若後續仍預期大幅修改章節結構、欄位語意、主要分群方式或範本邊界，應先停在 template 階段繼續穩定 artifact。
- 只有在 artifact 已足夠穩定，後續主要工作轉為推理流程設計時，才適合進入 `/skill-engineering`。

## Good Example

- 這個例子是好的，因為 artifact 結構已穩定，後續重點自然轉為反推 skill。

````md
目前狀態：
- example 已定稿
- template 雙檔已完成
- 後續不再改章節結構，只需設計如何從 prompt 可靠推到該 artifact

決策：
- 進入 `/skill-engineering`
````

## Bad Example

- 這個例子是壞的，因為 artifact 結構還沒穩，卻急著開始設計 target skill。

````md
目前狀態：
- 還不確定需不需要保留全域需求
- 還不確定故事底下要不要有 NFR

決策：
- 先開始寫 target skill SOP
````

# Rule 4 - 進入 skill engineering 時，必須明示 target skill 的設計約束

- Level: `SHOULD`
- 委派 `/skill-engineering` 前，應明示本次 target skill 的主要設計約束，例如：不要過度工程、先從最簡單的 SOP 開始、rules 按需疊代、所有新增規則都必須掛回主 SOP。
- 這些約束能避免 target skill 在起步階段就引入多餘模組，偏離 artifact 導向的最小設計。
- 若使用者已明確給出這些原則，應把它們作為委派前的固定輸入，而不是只留在口頭印象中。

## Good Example

- 這個例子是好的，因為它把方法論約束一起交給 skill engineering，而不是只丟 artifact。

````md
委派 `/skill-engineering` 時附帶：
- 目標 artifact = `templates/spec.template.md` / `templates/spec.example.md`
- 原則 = 不要過度工程、先從最簡單 SOP 開始、rules 按需疊代並確實掛回
````

## Bad Example

- 這個例子是壞的，因為它只丟 target artifact，卻沒有把方法論邊界一併帶入。

````md
請直接把這個 template 變成一個 skill。
````
