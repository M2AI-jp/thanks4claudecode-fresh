# new-repo

Purpose: a minimal, doc-only knowledge base for rebuilding the framework from scratch.

## Structure

```
new-repo/
├── README.md              # This file (entry point)
├── PROJECT-STORY.md       # Background narrative
├── v2-design/             # SSOT: Consolidated design documents
│   ├── GLOSSARY.md
│   ├── HARNESS-ANALYSIS.md
│   ├── IMPLEMENTATION-PLAN-V2.md
│   ├── REVIEW-PROTOCOL.md
│   ├── TEST-PROTOCOL.md
│   └── FAILURE-CATALOG.md
└── archive/               # Legacy documents (for reference only)
    ├── REBUILD-DESIGN-SPEC.md
    ├── BUILD-FROM-SCRATCH.md
    ├── EXAMPLE-FRAMEWORK-BUILD.md
    └── EXAMPLE-CHATGPT-CLONE.md
```

## Reading Order (v2-design)

1. **GLOSSARY.md** - 用語定義（前提知識）
2. **HARNESS-ANALYSIS.md** - 外部分析結果（harness との比較）
3. **IMPLEMENTATION-PLAN-V2.md** - 実装計画（Phase -1〜4, Layer 0-5）
4. **REVIEW-PROTOCOL.md** - レビュー手順（5観点, 3点検証, 時間的達成可能性）
5. **TEST-PROTOCOL.md** - テスト手順（5種別）
6. **FAILURE-CATALOG.md** - 失敗カタログ（過去の教訓）
7. **PROJECT-STORY.md** - 背景物語（コンテキスト補完）

## SSOT Policy

- **v2-design/** が設計の唯一の真実源（SSOT）
- **archive/** は参照用のみ（更新しない）
- 内容が重複する場合は **v2-design/** を優先

## Notes

- This folder is intentionally doc-only; no runtime assets.
- Each doc header references this README for reading order.
- v2-design documents are self-contained and can be understood in Context-0.
