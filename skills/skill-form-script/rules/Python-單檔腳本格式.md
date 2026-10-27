# Rule 1 - Skill script 必須維持單檔且聚焦單一自動化目的

- Level: `MUST`
- `scripts/` 下的 Python script 應維持為單一檔案，負責單一步驟中的單一自動化職責。
- 若腳本已需要多個本地模組、共享套件結構或專案級設定，表示它已超出單檔 script 邊界，不應繼續假裝是最小 script。
- 不可為了維持「單檔」表面形式，把大量隱含規則、硬編碼路徑或多種不相關責任塞進同一支 script。

## Good Example

- 這個例子是好的，因為 script 只處理單一輸入檔並產出單一結果，責任邊界清楚。

```python
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

from pathlib import Path
import json
import sys


def main() -> int:
    source = Path(sys.argv[1])
    data = source.read_text(encoding="utf-8")
    print(json.dumps({"chars": len(data)}, ensure_ascii=False))
    return 0
```

## Bad Example

- 這個例子是壞的，因為同一支 script 同時負責解析需求、產圖、上傳檔案與通知外部服務，已不是單一步驟的最小自動化腳本。

```python
def main():
    collect_user_requirements()
    generate_diagram()
    upload_to_drive()
    notify_slack()
    update_database()
```

# Rule 2 - 第三方相依必須直接寫在 script 檔頭的 PEP 723 metadata

- Level: `MUST`
- 只要 script 依賴第三方套件，就必須在檔頭使用 `# /// script` 區塊宣告 `requires-python` 與 `dependencies`。
- `dependencies` 應直接寫在 script 內，即使沒有第三方套件，也應明確寫成 `dependencies = []`。
- 不可把單檔 script 的依賴改放在旁邊的 `requirements.txt`、聊天補充說明或執行者自行猜測的安裝步驟中。

## Good Example

- 這個例子是好的，因為 Python 版本與第三方套件都由 script 自身宣告，不需要額外 sidecar 檔案。

```python
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "httpx>=0.27,<1",
#   "rich>=13,<14",
# ]
# ///

import httpx
from rich.console import Console
```

## Bad Example

- 這個例子是壞的，因為 script 本身看不出需要哪些相依套件，執行者只能靠外部說明或 import error 反推。

```python
import httpx
from rich.console import Console

# 依賴請另外看 requirements.txt
```

# Rule 3 - 腳本介面應清楚揭露輸入、輸出與失敗訊號

- Level: `SHOULD`
- script 應讓執行者清楚知道輸入從哪裡來、成功時輸出什麼、失敗時如何辨識。
- 若腳本需要參數，應使用明確的 CLI 參數、stdin 或固定格式輸入，而不是依賴執行者手動改碼。
- 若腳本可能失敗，應輸出可理解的錯誤訊息，並以非零 exit code 結束。

## Good Example

- 這個例子是好的，因為它把輸入、輸出與失敗路徑都顯式化，方便 Skill 執行者穩定呼叫。

```python
import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    args = parser.parse_args()

    path = Path(args.input)
    if not path.exists():
        print(f"Input not found: {path}", file=sys.stderr)
        return 2

    print(json.dumps({"path": str(path)}, ensure_ascii=False))
    return 0
```

## Bad Example

- 這個例子是壞的，因為輸入依賴硬編碼與人工改檔，失敗時也沒有可依賴的訊號。

```python
source = "/tmp/input.txt"
data = open(source).read()
print("done")
```
