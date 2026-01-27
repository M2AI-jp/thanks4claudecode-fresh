---                                                                                                                     
  new-repo 完璧実装計画                                                                                                   
                                                                                                                          
  0. 設計原則（二の轍を踏まないために）                                                                                   
                                                                                                                          
  今のリポジトリの失敗要因                                                                                                
  ┌───────────────────────────┬───────────────────────────────────────┬──────────────────────────────┐                    
  │           失敗            │                 原因                  │             対策             │                    
  ├───────────────────────────┼───────────────────────────────────────┼──────────────────────────────┤                    
  │ Hook チェーンが複雑化     │ Hook を第一層として自動強制を目指した │ Hook は Phase 4 まで使わない │                    
  ├───────────────────────────┼───────────────────────────────────────┼──────────────────────────────┤                    
  │ playbook が人間に読めない │ JSON のみで設計                       │ JSON + Markdown 二層化       │                    
  ├───────────────────────────┼───────────────────────────────────────┼──────────────────────────────┤                    
  │ 長期タスクで破綻          │ セッション永続化なし                  │ Phase 1 で永続化導入         │                    
  ├───────────────────────────┼───────────────────────────────────────┼──────────────────────────────┤                    
  │ コンテキスト0で再現不能   │ 暗黙の前提が多い                      │ 全ての前提を明示化           │                    
  ├───────────────────────────┼───────────────────────────────────────┼──────────────────────────────┤                    
  │ 検証が後回し              │ 作りっぱなし                          │ 各 Phase にテストを含める    │                    
  └───────────────────────────┴───────────────────────────────────────┴──────────────────────────────┘                    
  新設計の原則                                                                                                            
                                                                                                                          
  principles:                                                                                                             
    1_self_containment:                                                                                                   
      rule: 各ドキュメントは単独で意味を持つ                                                                              
      test: コンテキスト0で読んで理解できるか                                                                             
                                                                                                                          
    2_explicit_over_implicit:                                                                                             
      rule: 暗黙の前提を排除、全て明文化                                                                                  
      test: 「なぜ？」に対する答えがドキュメントにあるか                                                                  
                                                                                                                          
    3_testable_specification:                                                                                             
      rule: 全ての仕様に対応するテストが存在                                                                              
      test: 仕様変更時にテストが失敗するか                                                                                
                                                                                                                          
    4_incremental_construction:                                                                                           
      rule: Phase N は Phase N-1 の上に構築                                                                               
      test: Phase N-1 だけで動作するか                                                                                    
                                                                                                                          
    5_human_readable:                                                                                                     
      rule: 機械可読（JSON）と人間可読（Markdown）の両立                                                                  
      test: 非技術者が Markdown を読んで理解できるか                                                                      
                                                                                                                          
  ---                                                                                                                     
  1. リポジトリ構造                                                                                                       
                                                                                                                          
  new-repo/                                                                                                               
  ├── README.md                          # エントリーポイント（必読）                                                     
  ├── CLAUDE.md                          # Core Contract（必読）                                                          
  │                                                                                                                       
  ├── docs/                                                                                                               
  │   ├── GLOSSARY.md                    # 用語定義（SSOT）                                                               
  │   ├── ARCHITECTURE.md                # アーキテクチャ設計                                                             
  │   ├── SPECIFICATION.md               # 仕様書（厳密な定義）                                                           
  │   ├── IMPLEMENTATION-PLAN.md         # 実装計画（Phase別）                                                            
  │   ├── REVIEW-PROTOCOL.md             # レビュー手順                                                                   
  │   ├── TEST-PROTOCOL.md               # テスト手順                                                                     
  │   └── FAILURE-CATALOG.md             # 失敗カタログ（過去の失敗と対策）                                               
  │                                                                                                                       
  ├── contracts/                                                                                                          
  │   ├── schemas/                                                                                                        
  │   │   ├── state.schema.json          # state.md のスキーマ                                                            
  │   │   ├── session.schema.json        # session.json のスキーマ                                                        
  │   │   ├── playbook.schema.json       # playbook のスキーマ                                                            
  │   │   └── safety.schema.json         # 安全設定のスキーマ                                                             
  │   └── templates/                                                                                                      
  │       ├── PLAYBOOK.template.md       # playbook のテンプレート                                                        
  │       └── REVIEW-REPORT.template.md  # レビューレポートのテンプレート                                                 
  │                                                                                                                       
  ├── .claude/                                                                                                            
  │   ├── commands/                      # Phase 0                                                                        
  │   │   ├── plan.md                                                                                                     
  │   │   ├── work.md                                                                                                     
  │   │   └── review.md                                                                                                   
  │   ├── workflows/                     # Phase 0                                                                        
  │   │   └── golden-path.yaml                                                                                            
  │   ├── skills/                        # Phase 2+                                                                       
  │   ├── state/                         # Phase 1                                                                        
  │   │   ├── session.json                                                                                                
  │   │   └── session.events.jsonl                                                                                        
  │   └── hooks/                         # Phase 4                                                                        
  │                                                                                                                       
  ├── play/                                                                                                               
  │   ├── template/                                                                                                       
  │   │   ├── plan.json                                                                                                   
  │   │   └── PLAYBOOK.md                                                                                                 
  │   └── archive/                                                                                                        
  │                                                                                                                       
  ├── tests/                                                                                                              
  │   ├── structure/                     # 構造検証                                                                       
  │   │   ├── test-file-exists.sh                                                                                         
  │   │   ├── test-references.sh                                                                                          
  │   │   └── test-schemas.sh                                                                                             
  │   ├── scenarios/                     # シナリオテスト                                                                 
  │   │   ├── scenario-01-basic-task.md                                                                                   
  │   │   ├── scenario-02-resume.md                                                                                       
  │   │   └── scenario-03-review.md                                                                                       
  │   └── run-all-tests.sh                                                                                                
  │                                                                                                                       
  └── state.md                           # 現在状態（SSOT）                                                               
                                                                                                                          
  ---                                                                                                                     
  2. ドキュメント依存関係                                                                                                 
                                                                                                                          
                      ┌─────────────┐                                                                                     
                      │  README.md  │  ← エントリーポイント                                                               
                      └──────┬──────┘                                                                                     
                             │                                                                                            
                ┌────────────┼────────────┐                                                                               
                ▼            ▼            ▼                                                                               
          ┌──────────┐ ┌──────────┐ ┌──────────────┐                                                                      
          │ CLAUDE.md│ │GLOSSARY.md│ │ARCHITECTURE.md│                                                                    
          └────┬─────┘ └─────┬────┘ └───────┬──────┘                                                                      
               │             │              │                                                                             
               └─────────────┼──────────────┘                                                                             
                             ▼                                                                                            
                    ┌─────────────────┐                                                                                   
                    │ SPECIFICATION.md │  ← 仕様の SSOT                                                                   
                    └────────┬────────┘                                                                                   
                             │                                                                                            
           ┌─────────────────┼─────────────────┐                                                                          
           ▼                 ▼                 ▼                                                                          
  ┌──────────────────┐ ┌───────────────┐ ┌──────────────┐                                                                 
  │IMPLEMENTATION-   │ │REVIEW-        │ │TEST-         │                                                                 
  │PLAN.md           │ │PROTOCOL.md    │ │PROTOCOL.md   │                                                                 
  └──────────────────┘ └───────────────┘ └──────────────┘                                                                 
                                                                                                                          
  読み順序: README → GLOSSARY → ARCHITECTURE → SPECIFICATION → 目的別（実装/レビュー/テスト）                             
                                                                                                                          
  ---                                                                                                                     
  3. レビューの厳密な定義                                                                                                 
                                                                                                                          
  3.1 レビューとは何か                                                                                                    
                                                                                                                          
  review:                                                                                                                 
    definition: |                                                                                                         
      成果物が仕様を満たしているかを、                                                                                    
      コンテキスト0（過去の議論を知らない状態）で検証する行為                                                             
                                                                                                                          
    input:                                                                                                                
      - 成果物（コード、ドキュメント、設定ファイル）                                                                      
      - 仕様書（SPECIFICATION.md + 関連スキーマ）                                                                         
                                                                                                                          
    output:                                                                                                               
      status: PASS | FAIL | CONDITIONAL_PASS                                                                              
      issues:                                                                                                             
        - id: R-001                                                                                                       
          severity: critical | major | minor | suggestion                                                                 
          location: ファイルパス:行番号                                                                                   
          description: 問題の説明                                                                                         
          spec_reference: 違反している仕様への参照                                                                        
                                                                                                                          
    constraint:                                                                                                           
      - レビュアーは過去のチャット履歴を参照してはならない                                                                
      - 判断はドキュメントとコードのみから行う                                                                            
      - 「意図」ではなく「実装」を評価する                                                                                
                                                                                                                          
  3.2 レビュー観点（5観点）                                                                                               
                                                                                                                          
  review_aspects:                                                                                                         
    1_spec_compliance:                                                                                                    
      question: 仕様書の要件を全て満たしているか？                                                                        
      method:                                                                                                             
        - SPECIFICATION.md の各要件を抽出                                                                                 
        - 成果物が各要件を満たすか検証                                                                                    
        - 満たさない場合は FAIL + 要件番号を記録                                                                          
      evidence: 要件対応表（Traceability Matrix）                                                                         
                                                                                                                          
    2_self_containment:                                                                                                   
      question: このドキュメント/コードは単独で理解可能か？                                                               
      method:                                                                                                             
        - 外部参照を全て列挙                                                                                              
        - 各参照が存在し、アクセス可能か確認                                                                              
        - 未定義の用語がないか確認（GLOSSARY.md と照合）                                                                  
      evidence: 参照整合性レポート                                                                                        
                                                                                                                          
    3_internal_consistency:                                                                                               
      question: 内部矛盾がないか？                                                                                        
      method:                                                                                                             
        - 同じ概念に対する記述を全て抽出                                                                                  
        - 矛盾する記述がないか確認                                                                                        
        - 型定義とスキーマの整合性確認                                                                                    
      evidence: 矛盾検出レポート                                                                                          
                                                                                                                          
    4_completeness:                                                                                                       
      question: 必要な情報が全て揃っているか？                                                                            
      method:                                                                                                             
        - テンプレートの必須項目と照合                                                                                    
        - TODO/FIXME/TBD が残っていないか確認                                                                             
        - エラーケースの定義があるか確認                                                                                  
      evidence: 完全性チェックリスト                                                                                      
                                                                                                                          
    5_testability:                                                                                                        
      question: この仕様/実装はテスト可能か？                                                                             
      method:                                                                                                             
        - 各仕様に対応するテストケースが存在するか                                                                        
        - テストケースが実行可能か                                                                                        
        - 合否判定基準が明確か                                                                                            
      evidence: テスト対応表                                                                                              
                                                                                                                          
  3.3 レビュー手順                                                                                                        
                                                                                                                          
  review_procedure:                                                                                                       
    phase_1_preparation:                                                                                                  
      duration: 10%                                                                                                       
      actions:                                                                                                            
        - 新しい Claude Code セッションを開始（コンテキスト0）                                                            
        - README.md を読む                                                                                                
        - GLOSSARY.md を読む                                                                                              
        - SPECIFICATION.md を読む                                                                                         
        - レビュー対象の範囲を確認                                                                                        
                                                                                                                          
    phase_2_systematic_check:                                                                                             
      duration: 60%                                                                                                       
      actions:                                                                                                            
        - 5観点それぞれについて順番に検証                                                                                 
        - 発見した問題を即座に記録                                                                                        
        - 判断に迷う場合は「要確認」として記録                                                                            
                                                                                                                          
    phase_3_cross_check:                                                                                                  
      duration: 20%                                                                                                       
      actions:                                                                                                            
        - 発見した問題の重複を排除                                                                                        
        - 問題間の関連性を確認                                                                                            
        - 根本原因の特定                                                                                                  
                                                                                                                          
    phase_4_report:                                                                                                       
      duration: 10%                                                                                                       
      actions:                                                                                                            
        - REVIEW-REPORT.template.md に従ってレポート作成                                                                  
        - 総合判定（PASS/FAIL/CONDITIONAL_PASS）                                                                          
        - 次のアクションを明記                                                                                            
                                                                                                                          
  3.4 レビューレポートテンプレート                                                                                        
                                                                                                                          
  # Review Report                                                                                                         
                                                                                                                          
  ## メタ情報                                                                                                             
  - レビュー対象: {対象の範囲}                                                                                            
  - レビュー日時: {YYYY-MM-DD HH:MM}                                                                                      
  - レビュアー: Claude Code (Context-0)                                                                                   
  - 参照仕様: SPECIFICATION.md v{version}                                                                                 
                                                                                                                          
  ## 総合判定                                                                                                             
  **{PASS | FAIL | CONDITIONAL_PASS}**                                                                                    
                                                                                                                          
  ## 観点別結果                                                                                                           
                                                                                                                          
  | 観点 | 結果 | 問題数 |                                                                                                
  |------|------|--------|                                                                                                
  | Spec Compliance | {PASS/FAIL} | {N} |                                                                                 
  | Self-Containment | {PASS/FAIL} | {N} |                                                                                
  | Internal Consistency | {PASS/FAIL} | {N} |                                                                            
  | Completeness | {PASS/FAIL} | {N} |                                                                                    
  | Testability | {PASS/FAIL} | {N} |                                                                                     
                                                                                                                          
  ## 検出された問題                                                                                                       
                                                                                                                          
  ### Critical（修正必須）                                                                                                
  | ID | 場所 | 説明 | 仕様参照 |                                                                                         
  |----|------|------|---------|                                                                                          
  | R-001 | {path:line} | {description} | SPEC §{section} |                                                               
                                                                                                                          
  ### Major（修正推奨）                                                                                                   
  ...                                                                                                                     
                                                                                                                          
  ### Minor（軽微）                                                                                                       
  ...                                                                                                                     
                                                                                                                          
  ## 次のアクション                                                                                                       
  1. {具体的なアクション}                                                                                                 
  2. {具体的なアクション}                                                                                                 
                                                                                                                          
  ---                                                                                                                     
  4. テストの厳密な定義                                                                                                   
                                                                                                                          
  4.1 テストとは何か                                                                                                      
                                                                                                                          
  test:                                                                                                                   
    definition: |                                                                                                         
      実装が期待動作するかを、                                                                                            
      コンテキスト0（実装意図を知らない状態）で検証する行為                                                               
                                                                                                                          
    input:                                                                                                                
      - 実装（コード、設定ファイル、Hook スクリプト）                                                                     
      - テストケース（期待動作の定義）                                                                                    
                                                                                                                          
    output:                                                                                                               
      status: PASS | FAIL                                                                                                 
      evidence:                                                                                                           
        - 実行ログ                                                                                                        
        - 期待値と実際値の比較                                                                                            
        - スクリーンショット（該当する場合）                                                                              
                                                                                                                          
    constraint:                                                                                                           
      - テスト実行者は実装の詳細を知らない前提                                                                            
      - 期待動作はドキュメントから導出                                                                                    
      - 「動いた」ではなく「仕様通りに動いた」を検証                                                                      
                                                                                                                          
  4.2 テスト種別（5種別）                                                                                                 
                                                                                                                          
  test_types:                                                                                                             
    1_structure_test:                                                                                                     
      purpose: ファイル構造が仕様通りか検証                                                                               
      scope: ディレクトリ構造、必須ファイルの存在                                                                         
      method: スクリプトで自動検証                                                                                        
      example: |                                                                                                          
        # test-file-exists.sh                                                                                             
        assert_file_exists "README.md"                                                                                    
        assert_file_exists "CLAUDE.md"                                                                                    
        assert_file_exists "docs/SPECIFICATION.md"                                                                        
        assert_dir_exists ".claude/commands"                                                                              
                                                                                                                          
    2_schema_test:                                                                                                        
      purpose: JSON/YAML がスキーマに準拠しているか検証                                                                   
      scope: 設定ファイル、状態ファイル、playbook                                                                         
      method: JSON Schema Validator で自動検証                                                                            
      example: |                                                                                                          
        # test-schemas.sh                                                                                                 
        validate_json "state.md" "contracts/schemas/state.schema.json"                                                    
        validate_json ".claude/state/session.json" "contracts/schemas/session.schema.json"                                
                                                                                                                          
    3_reference_test:                                                                                                     
      purpose: ファイル参照の整合性を検証                                                                                 
      scope: ドキュメント間の参照、コード内の参照                                                                         
      method: スクリプトで参照先の存在を確認                                                                              
      example: |                                                                                                          
        # test-references.sh                                                                                              
        # CLAUDE.md 内の全ての参照が存在するか                                                                            
        extract_references "CLAUDE.md" | while read ref; do                                                               
          assert_file_exists "$ref"                                                                                       
        done                                                                                                              
                                                                                                                          
    4_scenario_test:                                                                                                      
      purpose: E2E シナリオが期待通り動作するか検証                                                                       
      scope: ユーザーストーリー、ワークフロー                                                                             
      method: シナリオ文書に従って手動実行、結果を記録                                                                    
      example: |                                                                                                          
        # scenario-01-basic-task.md                                                                                       
        ## 前提条件                                                                                                       
        - 新しい Claude Code セッション                                                                                   
        - playbook なし                                                                                                   
                                                                                                                          
        ## 手順                                                                                                           
        1. 「ログイン機能を作って」と入力                                                                                 
        2. playbook が作成されることを確認                                                                                
        3. /work で実装が開始されることを確認                                                                             
                                                                                                                          
        ## 期待結果                                                                                                       
        - playbook が play/{id}/ に作成される                                                                             
        - state.md の playbook.active が更新される                                                                        
                                                                                                                          
    5_regression_test:                                                                                                    
      purpose: 既存機能が壊れていないか検証                                                                               
      scope: 過去に動作していた機能                                                                                       
      method: 以前のテスト結果と比較                                                                                      
      example: |                                                                                                          
        # 全てのテストを実行し、以前の結果と比較                                                                          
        ./tests/run-all-tests.sh > current_results.txt                                                                    
        diff previous_results.txt current_results.txt                                                                     
                                                                                                                          
  4.3 テスト手順                                                                                                          
                                                                                                                          
  test_procedure:                                                                                                         
    phase_1_preparation:                                                                                                  
      actions:                                                                                                            
        - 新しい Claude Code セッションを開始（コンテキスト0）                                                            
        - テスト対象の Phase を確認                                                                                       
        - 必要なテストケースを特定                                                                                        
                                                                                                                          
    phase_2_automated_tests:                                                                                              
      actions:                                                                                                            
        - ./tests/run-all-tests.sh を実行                                                                                 
        - Structure Test → Schema Test → Reference Test の順                                                              
        - 失敗したテストを記録                                                                                            
                                                                                                                          
    phase_3_scenario_tests:                                                                                               
      actions:                                                                                                            
        - tests/scenarios/ のシナリオを順番に実行                                                                         
        - 各ステップの結果を記録                                                                                          
        - 期待結果との差異を記録                                                                                          
                                                                                                                          
    phase_4_report:                                                                                                       
      actions:                                                                                                            
        - テスト結果サマリーを作成                                                                                        
        - PASS/FAIL の判定                                                                                                
        - 失敗したテストの原因分析                                                                                        
                                                                                                                          
  4.4 テスト結果テンプレート                                                                                              
                                                                                                                          
  # Test Report                                                                                                           
                                                                                                                          
  ## メタ情報                                                                                                             
  - テスト対象: Phase {N}                                                                                                 
  - テスト日時: {YYYY-MM-DD HH:MM}                                                                                        
  - テスト実行者: Claude Code (Context-0)                                                                                 
                                                                                                                          
  ## 総合結果                                                                                                             
  **{PASS | FAIL}**                                                                                                       
                                                                                                                          
  ## 自動テスト結果                                                                                                       
                                                                                                                          
  | テスト種別 | 実行数 | 成功 | 失敗 | スキップ |                                                                        
  |-----------|--------|------|------|---------|                                                                          
  | Structure | {N} | {N} | {N} | {N} |                                                                                   
  | Schema | {N} | {N} | {N} | {N} |                                                                                      
  | Reference | {N} | {N} | {N} | {N} |                                                                                   
                                                                                                                          
  ## シナリオテスト結果                                                                                                   
                                                                                                                          
  | シナリオ | 結果 | 備考 |                                                                                              
  |---------|------|------|                                                                                               
  | scenario-01-basic-task | {PASS/FAIL} | {備考} |                                                                       
  | scenario-02-resume | {PASS/FAIL} | {備考} |                                                                           
                                                                                                                          
  ## 失敗したテスト                                                                                                       
                                                                                                                          
  ### {テスト名}                                                                                                          
  - **期待値**: {expected}                                                                                                
  - **実際値**: {actual}                                                                                                  
  - **原因分析**: {analysis}                                                                                              
                                                                                                                          
  ## 次のアクション                                                                                                       
  1. {具体的なアクション}                                                                                                 
                                                                                                                          
  ---                                                                                                                     
  5. 実装計画（Phase 別）                                                                                                 
                                                                                                                          
  Phase 0: 基盤（手動運用のみ）                                                                                           
                                                                                                                          
  phase_0:                                                                                                                
    name: 基盤構築                                                                                                        
    goal: コマンド起点の手動運用が動作する                                                                                
    duration: 1セッション                                                                                                 
                                                                                                                          
    deliverables:                                                                                                         
      - README.md                                                                                                         
      - CLAUDE.md                                                                                                         
      - docs/GLOSSARY.md                                                                                                  
      - docs/ARCHITECTURE.md                                                                                              
      - docs/SPECIFICATION.md（Phase 0 部分）                                                                             
      - .claude/commands/plan.md                                                                                          
      - .claude/commands/work.md                                                                                          
      - .claude/commands/review.md                                                                                        
      - state.md（最小構成）                                                                                              
                                                                                                                          
    validation:                                                                                                           
      review:                                                                                                             
        - SPECIFICATION.md §Phase0 の全要件を満たすか                                                                     
        - ドキュメント間の参照が整合するか                                                                                
      test:                                                                                                               
        - Structure Test: 必須ファイルが存在するか                                                                        
        - Reference Test: 参照が全て解決するか                                                                            
        - Scenario Test: /plan → /work → /review が動作するか                                                             
                                                                                                                          
    done_criteria:                                                                                                        
      - コンテキスト0で README を読み、基本操作ができる                                                                   
      - /plan でタスク計画を作成できる                                                                                    
      - /work でタスクを実行できる                                                                                        
      - /review でコードレビューができる                                                                                  
                                                                                                                          
  Phase 1: 状態管理                                                                                                       
                                                                                                                          
  phase_1:                                                                                                                
    name: 状態管理                                                                                                        
    goal: セッション永続化と Resume/Fork が動作する                                                                       
    duration: 1セッション                                                                                                 
    depends_on: Phase 0                                                                                                   
                                                                                                                          
    deliverables:                                                                                                         
      - contracts/schemas/state.schema.json                                                                               
      - contracts/schemas/session.schema.json                                                                             
      - .claude/state/session.json                                                                                        
      - .claude/state/session.events.jsonl                                                                                
      - .claude/skills/session-control/SKILL.md                                                                           
      - docs/SPECIFICATION.md（Phase 1 追記）                                                                             
                                                                                                                          
    validation:                                                                                                           
      review:                                                                                                             
        - session.json が session.schema.json に準拠するか                                                                
        - state.md との二層運用が明確か                                                                                   
      test:                                                                                                               
        - Schema Test: session.json のスキーマ検証                                                                        
        - Scenario Test: セッション中断 → Resume が動作するか                                                             
        - Scenario Test: Fork でブランチ分岐できるか                                                                      
                                                                                                                          
    done_criteria:                                                                                                        
      - セッション中断後、別セッションで Resume できる                                                                    
      - Fork で作業を分岐できる                                                                                           
      - session.events.jsonl から状態を復元できる                                                                         
                                                                                                                          
  Phase 2: 計画管理                                                                                                       
                                                                                                                          
  phase_2:                                                                                                                
    name: 計画管理                                                                                                        
    goal: playbook の二層化（JSON + Markdown）が動作する                                                                  
    duration: 1セッション                                                                                                 
    depends_on: Phase 1                                                                                                   
                                                                                                                          
    deliverables:                                                                                                         
      - contracts/schemas/playbook.schema.json                                                                            
      - contracts/templates/PLAYBOOK.template.md                                                                          
      - play/template/plan.json                                                                                           
      - play/template/PLAYBOOK.md                                                                                         
      - .claude/skills/playbook-creator/SKILL.md                                                                          
      - .claude/skills/playbook-sync/SKILL.md                                                                             
      - docs/SPECIFICATION.md（Phase 2 追記）                                                                             
                                                                                                                          
    validation:                                                                                                           
      review:                                                                                                             
        - plan.json が playbook.schema.json に準拠するか                                                                  
        - PLAYBOOK.md が人間可読か                                                                                        
        - 同期ロジックが明確か                                                                                            
      test:                                                                                                               
        - Schema Test: plan.json のスキーマ検証                                                                           
        - Scenario Test: playbook 作成 → 進捗更新 → 完了 が動作するか                                                     
        - Sync Test: JSON 変更 → MD 同期、MD 変更 → JSON 同期                                                             
                                                                                                                          
    done_criteria:                                                                                                        
      - /plan で playbook（JSON + MD）が作成される                                                                        
      - 進捗更新が両方に反映される                                                                                        
      - コンテキスト0で PLAYBOOK.md を読んでタスクが理解できる                                                            
                                                                                                                          
  Phase 3: 品質保証                                                                                                       
                                                                                                                          
  phase_3:                                                                                                                
    name: 品質保証                                                                                                        
    goal: レビュー・テストのスキルが動作する                                                                              
    duration: 1セッション                                                                                                 
    depends_on: Phase 2                                                                                                   
                                                                                                                          
    deliverables:                                                                                                         
      - .claude/skills/review/SKILL.md                                                                                    
      - .claude/skills/test/SKILL.md                                                                                      
      - .claude/skills/quality-gate/SKILL.md                                                                              
      - docs/REVIEW-PROTOCOL.md                                                                                           
      - docs/TEST-PROTOCOL.md                                                                                             
      - tests/structure/*                                                                                                 
      - tests/scenarios/*                                                                                                 
      - docs/SPECIFICATION.md（Phase 3 追記）                                                                             
                                                                                                                          
    validation:                                                                                                           
      review:                                                                                                             
        - レビュースキルが 5 観点を網羅しているか                                                                         
        - テストスキルが 5 種別を網羅しているか                                                                           
      test:                                                                                                               
        - Scenario Test: /review が正しくレビューを実行するか                                                             
        - Scenario Test: テストスイートが正しく動作するか                                                                 
                                                                                                                          
    done_criteria:                                                                                                        
      - /review でコンテキスト0レビューが実行できる                                                                       
      - テストスイートが自動実行できる                                                                                    
      - 品質ゲートが PASS/FAIL を正しく判定する                                                                           
                                                                                                                          
  Phase 4: 自動化（Hook 統合）                                                                                            
                                                                                                                          
  phase_4:                                                                                                                
    name: 自動化                                                                                                          
    goal: Hook による補助的な自動化が動作する                                                                             
    duration: 1セッション                                                                                                 
    depends_on: Phase 3                                                                                                   
                                                                                                                          
    deliverables:                                                                                                         
      - .claude/hooks/session.sh                                                                                          
      - .claude/hooks/pre-tool.sh（最小限）                                                                               
      - .claude/hooks/post-tool.sh（最小限）                                                                              
      - contracts/schemas/safety.schema.json                                                                              
      - docs/SPECIFICATION.md（Phase 4 追記）                                                                             
                                                                                                                          
    validation:                                                                                                           
      review:                                                                                                             
        - Hook が「検出・通知」に限定されているか                                                                         
        - 「強制」は Workflow で行っているか                                                                              
      test:                                                                                                               
        - Scenario Test: SessionStart で状態が復元されるか                                                                
        - Scenario Test: PreToolUse でガードが発火するか                                                                  
                                                                                                                          
    done_criteria:                                                                                                        
      - Hook がトリガーされる                                                                                             
      - Hook は通知のみ、強制は Workflow で行う                                                                           
      - Phase 0-3 の機能が引き続き動作する（回帰テスト）                                                                  
                                                                                                                          
  ---                                                                                                                     
  6. コンテキスト0検証プロトコル                                                                                          
                                                                                                                          
  検証の実行方法                                                                                                          
                                                                                                                          
  context_0_verification:                                                                                                 
    preparation:                                                                                                          
      - 新しい Claude Code セッションを開始                                                                               
      - 「私は新しいセッションです。このリポジトリを理解して、{タスク}を実行してください」と入力                          
                                                                                                                          
    verification_points:                                                                                                  
      1_can_understand:                                                                                                   
        question: README を読んで目的を理解できるか                                                                       
        method: Claude に「このリポジトリの目的を説明して」と聞く                                                         
        pass_criteria: SPECIFICATION.md の目的と一致する回答                                                              
                                                                                                                          
      2_can_navigate:                                                                                                     
        question: 必要なドキュメントを見つけられるか                                                                      
        method: 「Phase 2 を実装するにはどのファイルを読むべきか」と聞く                                                  
        pass_criteria: IMPLEMENTATION-PLAN.md の Phase 2 を参照する回答                                                   
                                                                                                                          
      3_can_execute:                                                                                                      
        question: 指示に従って実行できるか                                                                                
        method: 「Phase 2 を実装して」と依頼する                                                                          
        pass_criteria: IMPLEMENTATION-PLAN.md の通りに実装が進む                                                          
                                                                                                                          
      4_can_review:                                                                                                       
        question: レビューを正しく実行できるか                                                                            
        method: 「Phase 2 をレビューして」と依頼する                                                                      
        pass_criteria: REVIEW-PROTOCOL.md の通りにレビューが進む                                                          
                                                                                                                          
      5_can_test:                                                                                                         
        question: テストを正しく実行できるか                                                                              
        method: 「Phase 2 をテストして」と依頼する                                                                        
        pass_criteria: TEST-PROTOCOL.md の通りにテストが進む                                                              
                                                                                                                          
  ---                                                                                                                     
  7. 失敗カタログ（FAILURE-CATALOG.md）                                                                                   
                                                                                                                          
  # Failure Catalog                                                                                                       
                                                                                                                          
  このドキュメントは、過去の失敗とその対策を記録します。                                                                  
  新しい実装やレビュー時に参照し、同じ失敗を繰り返さないようにします。                                                    
                                                                                                                          
  ## F-001: Hook チェーンの複雑化                                                                                         
                                                                                                                          
  **発生状況**: Hook を第一層として自動強制を目指した                                                                     
  **症状**: Hook 間の依存関係が暗黙的になり、デバッグ不能に                                                               
  **根本原因**: LLM の非決定性を Hook で「強制」しようとした                                                              
  **対策**: Hook は Phase 4 まで使わない、Hook は「検出・通知」のみ                                                       
  **検証方法**: Hook のコードに「強制」ロジックがないことを確認                                                           
                                                                                                                          
  ## F-002: playbook が人間に読めない                                                                                     
                                                                                                                          
  **発生状況**: JSON のみで playbook を設計                                                                               
  **症状**: コンテキスト0で playbook を理解できない                                                                       
  **根本原因**: 機械可読性のみを優先した                                                                                  
  **対策**: JSON + Markdown 二層化、同期スクリプト                                                                        
  **検証方法**: 非技術者が PLAYBOOK.md を読んで理解できるか                                                               
                                                                                                                          
  ## F-003: セッション永続化なし                                                                                          
                                                                                                                          
  **発生状況**: 長期タスクで Claude Code セッションがリセット                                                             
  **症状**: 作業状態が失われ、最初からやり直し                                                                            
  **根本原因**: セッション永続化を設計しなかった                                                                          
  **対策**: Phase 1 で session.json + session.events.jsonl を導入                                                         
  **検証方法**: Resume/Fork が動作するか                                                                                  
                                                                                                                          
  ## F-004: 暗黙の前提                                                                                                    
                                                                                                                          
  **発生状況**: ドキュメントに書かれていない前提知識が必要                                                                
  **症状**: コンテキスト0で再現不能                                                                                       
  **根本原因**: 「分かっているはず」という思い込み                                                                        
  **対策**: 全ての前提を明文化、GLOSSARY.md で用語定義                                                                    
  **検証方法**: コンテキスト0で理解・実行できるか                                                                         
                                                                                                                          
  ## F-005: 検証の後回し                                                                                                  
                                                                                                                          
  **発生状況**: 作ってから検証しようとした                                                                                
  **症状**: 作りっぱなし、品質が不明                                                                                      
  **根本原因**: テスト設計が実装より後だった                                                                              
  **対策**: 各 Phase に検証を含める、仕様先行                                                                             
  **検証方法**: Phase 完了前にレビュー・テストが PASS するか                                                              
                                                                                                                          
  ---                                                                                                                     
  8. 実装スケジュール                                                                                                     
                                                                                                                          
  Week 1: Phase 0（基盤）                                                                                                 
    Day 1-2: ドキュメント作成                                                                                             
    Day 3: コマンド定義                                                                                                   
    Day 4: コンテキスト0レビュー                                                                                          
    Day 5: コンテキスト0テスト + 修正                                                                                     
                                                                                                                          
  Week 2: Phase 1（状態管理）                                                                                             
    Day 1-2: スキーマ + スキル実装                                                                                        
    Day 3: セッション永続化実装                                                                                           
    Day 4: コンテキスト0レビュー                                                                                          
    Day 5: コンテキスト0テスト + 修正                                                                                     
                                                                                                                          
  Week 3: Phase 2（計画管理）                                                                                             
    Day 1-2: playbook 二層化実装                                                                                          
    Day 3: 同期スクリプト実装                                                                                             
    Day 4: コンテキスト0レビュー                                                                                          
    Day 5: コンテキスト0テスト + 修正                                                                                     
                                                                                                                          
  Week 4: Phase 3（品質保証）                                                                                             
    Day 1-2: レビュー/テストスキル実装                                                                                    
    Day 3: テストスイート作成                                                                                             
    Day 4: コンテキスト0レビュー                                                                                          
    Day 5: コンテキスト0テスト + 修正                                                                                     
                                                                                                                          
  Week 5: Phase 4（自動化）+ 総合検証                                                                                     
    Day 1-2: Hook 最小実装                                                                                                
    Day 3: 回帰テスト                                                                                                     
    Day 4: 総合コンテキスト0レビュー                                                                                      
    Day 5: 総合コンテキスト0テスト + 最終修正                                                                             
                                                                                                                          
  ---                                                                                                                     
  9. 成功基準                                                                                                             
                                                                                                                          
  success_criteria:                                                                                                       
    overall:                                                                                                              
      - コンテキスト0で README を読み、全 Phase を実装できる                                                              
      - コンテキスト0でレビューを実行し、問題を検出できる                                                                 
      - コンテキスト0でテストを実行し、PASS/FAIL を判定できる                                                             
      - Phase 4 完了後、回帰テストが全て PASS                                                                             
                                                                                                                          
    per_phase:                                                                                                            
      phase_0:                                                                                                            
        - 手動コマンドで /plan /work /review が動作                                                                       
      phase_1:                                                                                                            
        - Resume/Fork が動作                                                                                              
      phase_2:                                                                                                            
        - playbook 二層化が動作、同期が正しい                                                                             
      phase_3:                                                                                                            
        - レビュー/テストスキルが動作                                                                                     
      phase_4:                                                                                                            
        - Hook が発火、回帰テスト PASS                                                                                    
                                                                                                                          
  ---                                                                                                                     
  この計画に従って new-repo                                                                                               
  を新規展開すれば、コンテキスト0からでも完璧に実装・レビュー・テス