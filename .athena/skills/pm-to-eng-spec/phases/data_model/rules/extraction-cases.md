# 萃取決策樹 · 邊界案例規則

> 本檔配合 `SKILL.md` 的「萃取決策樹」使用。決策樹負責「每個名詞該歸成什麼」的主流程，
> 本檔只收錄那些光看決策樹還判不出來的困難邊界情境，需要時才讀，不重述決策樹本體。
> 每條規則都標了 `Level`，並附一個判得對的例子與一個判錯的例子，方便審核者比對差異。

# Rule 1 - enum 與 reference table 的分界

- Level: `MUST`
- 一組封閉的分類值，若集合很小、值本身沒有自己的屬性、也不需要被翻譯成多國語言（例如付款狀態 `PENDING` / `PAID` / `REFUNDED`），就判成 **enum**。
- 若這組分類值需要被在地化、值本身帶有自己的屬性、會被其他資料表以外鍵引用、或營運人員會在後台自行增刪（例如商品分類、角色），就判成 **reference table**。
- 判斷時問自己一句話：「這個分類值未來會不會長出自己的欄位、或需要被 join 查詢？」只要答案是會，就判成 reference table。

## Good Example

- 這個例子是好的，因為它針對兩個分類值分別問了「會不會長出自己的欄位、會不會被 join」，並依答案給出不同判定。

````md
付款狀態（PENDING / PAID / REFUNDED）→ enum。
理由：值固定、沒有自己的屬性、也不需要在地化。

商品分類（3C / 家電 / 服飾，營運後台可自行增刪，前台要顯示中英文名稱）→ reference table。
理由：需要在地化，而且會被營運人員增刪，將來可能長出排序、圖示等欄位。
````

## Bad Example

- 這個例子是壞的，因為它只憑「看起來都是分類」就把兩者判成同一種，忽略了在地化與增刪需求這個關鍵差異。

````md
付款狀態 → enum。
商品分類 → enum。
理由：兩個都是分類值，統一用 enum 比較一致。
````

# Rule 2 - 衍生值預設不存成欄位

- Level: `MUST`
- 可以從其他資料算出來的值（訂單總額、年齡、帳戶餘額、「是否逾期」），預設判成 **derived**：不實際存成一個欄位，只記錄它的計算來源。
- 只有兩種情況例外，可以實際存成一個欄位：一是需要保留歷史快照（例如成交當下的金額，事後不可以隨著單價變動而改變），二是讀取效能要求高而且計算來源的資料量很大。
- 走例外路線、實際存成欄位時，必須把這個欄位標成 `denormalized`，並且寫清楚一致性要怎麼維護：什麼時候觸發更新、什麼時候重算。

## Good Example

- 這個例子是好的，因為它預設判成 derived 並寫明計算來源；需要存欄位的那一筆也交代了例外理由、`denormalized` 標記與重算時機。

````md
訂單總額 → derived，計算來源：訂單明細的 quantity × unit_price 加總，不存成欄位。

成交金額 → 存成欄位 settled_amount，標 denormalized。
例外理由：需要保留成交當下的歷史快照，事後不可隨單價變動。
一致性維護：訂單狀態轉為 PAID 時寫入一次，之後不再更新。
````

## Bad Example

- 這個例子是壞的，因為它直接開一個欄位存值，既沒有說明為什麼需要例外，也沒有標 `denormalized`，更沒有交代這個值什麼時候會被更新。

````md
訂單總額 → 欄位 total_amount，型別數字。
````

# Rule 3 - 1:1 關係預設合併進主實體

- Level: `SHOULD`
- 兩個實體是 1:1 關係時，預設把從屬的那一方**合併進主實體**，當成主實體的幾個欄位（例如 user 的少數 profile 欄位）。
- 只有在以下情況才拆成獨立實體：可選屬性有一大群而且多半是空值、兩邊的生命週期不同（例如 profile 是事後才補的）、兩邊的存取頻率或權限不同（例如敏感資料需要隔離）、或兩邊的資料保存政策不同。
- 沒有落在上述任一種情況時就不要拆，避免製造沒有意義的 join。

## Good Example

- 這個例子是好的，因為它對兩組 1:1 關係分別判斷，合併的那組說明了「欄位少」，拆開的那組指名了具體的拆分理由。

````md
User 與 UserProfile（只有暱稱、頭像兩個欄位，與帳號同時建立）→ 合併進 User。

User 與 UserIdentity（身分證字號、銀行帳號，屬敏感資料，需要獨立的存取權限）→ 拆成獨立實體。
拆分理由：存取權限不同，敏感資料需要隔離。
````

## Bad Example

- 這個例子是壞的，因為它只因為「概念上是兩件事」就把 1:1 拆開，沒有對到任何一條拆分理由，徒增一次 join。

````md
User 與 UserProfile（只有暱稱、頭像兩個欄位）→ 拆成兩個實體。
理由：帳號和個人資料概念不同，分開比較清楚。
````

# Rule 4 - 值物件預設嵌入主實體

- Level: `SHOULD`
- 像地址、金額、經緯度這種沒有獨立身分、只依附在主實體上的值物件，預設**嵌入主實體成為欄位**（例如 `shipping_city`、`amount` 加 `currency`）。
- 只有在這個值物件需要被多個實體共享，或需要被獨立查詢與維護（例如一本標準地址簿）時，才升格成獨立實體。
- 金額一律拆成「金額」與「幣別」兩個欄位，不可以只存一個數字。

## Good Example

- 這個例子是好的，因為它把只依附訂單的收件地址嵌成欄位，金額也拆成了金額與幣別兩欄。

````md
訂單收件地址 → 嵌入 Order：shipping_city、shipping_district、shipping_address。
訂單金額 → 嵌入 Order：amount（數值）+ currency（幣別代碼）。
````

## Bad Example

- 這個例子是壞的，因為它把只用在一個地方的地址升格成獨立實體，而且金額只存了一個數字，看不出是哪一種幣別。

````md
Address → 獨立實體，被 Order 以外鍵引用（系統中只有訂單會用到地址）。
Order.amount → 數值欄位。
````

# Rule 5 - 同義詞要合併、一詞多義要拆分

- Level: `MUST`
- 需求文件裡用不同稱呼指同一個真實事物時（會員 / 用戶 / 客戶），**合併成一個 entity**，並把其他稱呼當成別名，寫進實體目錄表的「來源」欄位。
- 同一個詞在不同情境指的是不同事物時，**拆成不同的 entity** 並各自命名。例如「訂單」在「下單」情境指的是購物車結帳的結果，在「出貨」情境指的是物流單位，這兩者應拆成 Order 與 Shipment。
- 不可以讓同義重複或一詞多義殘留到產出裡：前者會讓同一份資料被存兩次，後者會讓一個實體被塞進互相矛盾的屬性。

## Good Example

- 這個例子是好的，因為它把三個同義稱呼收斂成一個實體並留下別名紀錄，也把語意不同的「訂單」拆成了兩個各自命名的實體。

````md
會員 / 用戶 / 客戶 → 合併為 entity「Member」，來源欄記：別名「用戶」「客戶」。

訂單（下單情境：購物車結帳結果）→ entity「Order」
訂單（出貨情境：物流單位）→ entity「Shipment」
````

## Bad Example

- 這個例子是壞的，因為它照著需求文件的字面各開一個實體，同一份會員資料被拆成三個，出貨與下單的屬性又全被塞進同一個「訂單」。

````md
會員 → entity Member
用戶 → entity User
客戶 → entity Customer
訂單 → entity Order（同時放結帳金額與物流追蹤號碼）
````

# Rule 6 - 帶屬性的 N:M 關係要拆成 associative entity

- Level: `MUST`
- 兩個實體之間是多對多關係、而且這個關係本身帶有屬性時（選課帶成績與選課時間、訂單明細帶數量與單價、標籤關聯），一律拆出 **associative entity（junction）**。
- 關係上的屬性要掛在這個 junction 上，不可以硬塞進關係的任何一端。

## Good Example

- 這個例子是好的，因為它把關係本身的屬性掛在 junction 上，兩端實體都維持自己原本的語意。

````md
Student 與 Course 是 N:M，關係帶成績與選課時間
→ associative entity「Enrollment」，屬性：student、course、grade、enrolled_at。
````

## Bad Example

- 這個例子是壞的，因為它把屬於「某人修某課」的成績硬塞進 Course，一門課有多個學生時這個欄位根本放不下。

````md
Student 與 Course 是 N:M
→ Course 增加欄位 grade（學生的成績）、enrolled_at（選課時間）。
````

# Rule 7 - 階層資料在本層只標注查詢需求，實作形式交給 db_table

- Level: `MUST`
- 階層或樹狀資料（分類目錄、組織架構）若層數很淺、查詢也單純，在本層判成 **self-referencing FK**（例如 `parent_id`）即可。
- 若需求是頻繁查詢整條祖先鏈或子孫鏈，本層只標注「這是階層資料 + 有整條鏈的查詢需求」，不要在本層決定實作方式。
- closure table、path enumeration 這類做法屬於物理層的選項，由 db_table 根據本層標注的需求去決定，本層不預設答案。

## Good Example

- 這個例子是好的，因為它清楚區分了兩種情況，並且把需要整條鏈查詢的那筆留成「標注需求、交給 db_table」而不是自己選定實作。

````md
商品分類（最多三層，只查直接子分類）→ self-referencing FK：parent_category。

組織架構（需要查某個人的所有上層主管與所有下屬）
→ 標注：階層資料 + 需要查整條祖先鏈與子孫鏈；實作形式交給 db_table 決定。
````

## Bad Example

- 這個例子是壞的，因為它在概念/邏輯層就直接指定了物理層的實作方式，越過了 db_table 的職責。

````md
組織架構 → 建一張 closure table，欄位 ancestor_id、descendant_id、depth。
````

# Rule 8 - 多型與變體在本層只用一個 type 欄位表示

- Level: `MUST`
- 多型或變體的情境（付款方式、通知管道），在概念/邏輯層一律表示成「一個 entity 加上一個 type 欄位」，type 的值是一個封閉集合，例如 `Payment(type, ...)`。
- 不要在 data_model 做物件導向的介面抽象，那是 class_diagram（物件設計）的職責。
- 本層只負責交代兩件事：這裡有一個變化點、這個變化點的值集合是什麼。物件要怎麼抽介面、怎麼分類別，留給下游決定。

## Good Example

- 這個例子是好的，因為它只交代了變化點與封閉值集合，把類別怎麼拆留給 class_diagram。

````md
Payment → entity，屬性 type（enum：CREDIT_CARD / BANK_TRANSFER / CONVENIENCE_STORE）、amount、paid_at。
備註：各付款方式的差異欄位待 class_diagram 決定如何承載。
````

## Bad Example

- 這個例子是壞的，因為它在概念/邏輯層就設計了繼承結構，做了屬於 class_diagram 的物件抽象。

````md
Payment → 抽象介面
CreditCardPayment implements Payment
BankTransferPayment implements Payment
````

# Rule 9 - 歷史需求在本層只標注保留需求與讀取樣式

- Level: `MUST`
- 需求提到「要看某個時間點的狀態」或「要看變更軌跡」時，本層要標注的是兩件事：哪個實體需要保留歷史、以及是哪一種讀取需求。
- history 表（每次變更存一列）、快照表（定期存全量）、事件表（只新增不修改）是可能的落地形式，屬於下游決定的範圍；本層可以把建議寫在 handoff 裡，但不要在本層定案。

## Good Example

- 這個例子是好的，因為它標清楚了「哪個實體、保留什麼、為了什麼讀取需求」，落地形式只以建議的形式留在 handoff。

````md
Order.status → 需保留歷史。
讀取需求：客服要查某張訂單在任一時間點的狀態，以及完整的狀態變更軌跡。
（handoff 建議：可用每次變更存一列的 history 表承載，最終形式由 db_table 決定。）
````

## Bad Example

- 這個例子是壞的，因為它只寫了一句「要留歷史」，既沒說是哪種讀取需求，也沒說要保留哪些內容，下游無從判斷該用哪種落地形式。

````md
Order → 要留歷史。
````

# Rule 10 - 命名慣例（團隊有既有規範時以團隊為準）

- Level: `MAY`
- 以下是通用的預設建議，不是團隊定論；團隊若已有自己的命名規範，一律以團隊規範為準。
- 實體名建議用單數名詞；概念/邏輯層用中文或英文命名都可以，實際落地的命名交給 db_table 決定。
- junction 建議用兩端實體的組合來命名，例如用 `Enrollment` 表示選課，或直接命名為 `Student_Course`。
- enum 的值建議用大寫 `SNAKE_CASE`、語意明確、避免使用縮寫。

## Good Example

- 這個例子是好的，因為實體用單數名詞、junction 名稱看得出兩端是誰、enum 值也完整不縮寫。

````md
entity：Member、Course
junction：Enrollment（Student × Course）
enum：PAYMENT_PENDING / PAYMENT_COMPLETED / PAYMENT_REFUNDED
````

## Bad Example

- 這個例子是壞的，因為實體用了複數、junction 名稱看不出關聯哪兩端、enum 值又用了讀不懂的縮寫。

````md
entity：Members、Courses
junction：Rel1
enum：PP / PC / PR
````
