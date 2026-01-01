#!/usr/bin/env python3
"""
process.py - JSON入力を処理して出力するPythonスクリプト

stdin から JSON を読み込み、加工して stdout に JSON 出力する。
オーケストレーション練習用のパイプライン第1段階。
"""
import json
import sys
from datetime import datetime


def process_input(data: dict) -> dict:
    """入力データを加工して返す"""
    return {
        "original": data,
        "processed_by": "python",
        "timestamp": datetime.now().isoformat(),
        "added_fields": {
            "uppercase_input": data.get("input", "").upper() if isinstance(data.get("input"), str) else None,
            "step": 1
        }
    }


def main():
    try:
        # stdin から JSON を読み込む
        raw_input = sys.stdin.read()
        if not raw_input.strip():
            raise ValueError("Empty input received")

        data = json.loads(raw_input)

        # データを処理
        result = process_input(data)

        # 結果を stdout に JSON 出力
        print(json.dumps(result, ensure_ascii=False, indent=2))

    except json.JSONDecodeError as e:
        error_result = {
            "error": "Invalid JSON input",
            "details": str(e),
            "processed_by": "python"
        }
        print(json.dumps(error_result, ensure_ascii=False), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        error_result = {
            "error": "Processing failed",
            "details": str(e),
            "processed_by": "python"
        }
        print(json.dumps(error_result, ensure_ascii=False), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
