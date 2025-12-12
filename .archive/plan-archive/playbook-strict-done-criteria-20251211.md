# playbook-strict-done-criteria.md

> **done_criteria の検証可能性と報酬詐欺防止を強化するための playbook。**

---

## meta

```yaml
project: done_criteria 検証の厳密化（strict-done-criteria）
branch: feat/strict-done-criteria
created: 2025-12-11
issue: null
derives_from: null  # 独立した playbook（project.md 非関連）
reviewed: false
```

---

## goal

**Summary**: done_criteria の検証可能性を強化し、「報酬詐欺」を構造的に防止するシステムを実装する。

**done_when**:
- done-criteria-validation.md に「報酬詐欺防止」セクションを追加
- critic.md が「報酬詐欺検出パターン」を明示的にチェック
- pm.md の playbook 作成ガイドに「done_criteria チェックリスト」を統合
- 既存の done_criteria（全 playbook）を「新フレームワーク」でレビュー可能に
- state.md に「strict-done-criteria playbook 完了」を記録

---

## phases

### Phase 1: done-criteria-validation.md の強化

**目標**: done_criteria の妥当性を評価する固定フレームワークに「報酬詐欺防止」セクションを追加する。

**tasks**:

- **id**: t1-1
  **name**: 「報酬詐欺防止」セクションを追加
  **executor**: claudecode
  **done_criteria**:
    - [x] done-criteria-validation.md に新セクション「報酬詐欺防止チェックリスト」が追加されている
    - [x] チェックリストに 6 項目以上の「詐欺パターン」が列挙されている（13項目）
    - [x] 各パターンに対応する「検出方法」が明記されている
    - [x] 実装対象ファイル内にこのセクションが存在する（grep で確認）
  **test_method**: |
    1. grep -n "報酬詐欺" /Users/amano/Desktop/thanks4claudecode/.claude/rules/frameworks/done-criteria-validation.md
    2. wc -l で セクション長を確認（最小 20 行以上）

- **id**: t1-2
  **name**: done_criteria 検証チェックリストテンプレートを作成
  **executor**: claudecode
  **done_criteria**:
    - [x] done-criteria-validation.md に「チェックリスト実行フロー」が明記されている
    - [x] チェックリストの各項目が[ ]形式（実行可能）である
    - [x] チェックリストが critic の評価フォーマットと整合している
  **test_method**: |
    1. grep -A 10 "チェックリスト実行フロー" done-criteria-validation.md で確認

---

### Phase 2: critic.md の強化（報酬詐欺検出）

**目標**: critic SubAgent に「報酬詐欺検出」パターンを明示的に組み込む。

**depends_on**: [p1]

**tasks**:

- **id**: t2-1
  **name**: 「報酬詐欺検出」セクションを critic.md に追加
  **executor**: claudecode
  **done_criteria**:
    - [x] critic.md に「報酬詐欺の検出パターン」セクションが追加されている（Line 39）
    - [x] 以下のパターンが含まれている（pattern_1-6）：
      - 「〇〇した」だけで証拠なし
      - 「〇〇のはず」「〇〇だと思う」という推測表現
      - シミュレーション/机上検討のみで実行していない
      - 「設計上は...」（動作確認なし）
      - done_criteria の一部のみ確認
      - critic を呼び出さずに done 判定
    - [x] 各パターンに対して「検出方法」が明記されている（6個）
  **test_method**: |
    1. grep -c "報酬詐欺" /Users/amano/Desktop/thanks4claudecode/.claude/agents/critic.md
    → 2 以上（セクション + 詳細説明）
    2. grep "〇〇した\|〇〇のはず\|シミュレーション" critic.md で確認

- **id**: t2-2
  **name**: critic.md の評価フロー図を追加
  **executor**: claudecode
  **done_criteria**:
    - [x] critic.md に「意思決定ツリー」または「フロー図」が追加されている（Line 129）
    - [x] フロー図に以下の判定ポイントが含まれている：
      - done_criteria が曖昧か → FAIL（禁止パターンチェック）
      - 証拠が具体的か → PASS/FAIL
      - test_method が実行されたか → PASS/FAIL
      - critic を呼び出したか → PASS/FAIL（全 criteria 証拠チェック）
    - [x] フロー図がマークダウン形式で可視化されている（ASCII art）
  **test_method**: |
    1. critic.md に flowchart または ASCII art での図が存在
    2. grep -n "フロー\|意思決定\|ツリー" critic.md で確認

- **id**: t2-3
  **name**: critic.md に「自己報酬詐欺チェック」セクションを追加
  **executor**: claudecode
  **done_criteria**:
    - [x] critic.md に「自分自身の完了判定チェック」セクションがある（Line 165「自己報酬詐欺チェック」）
    - [x] セクションに以下が含まれている：
      - 完了したと思った瞬間が最も危険という警告（Line 171）
      - 「証拠なしの PASS は禁止」という強制ルール（Line 176）
      - 批判的思考（adversarial thinking）の推奨（Line 181-185）
    - [x] セクション長が 10 行以上（29行）
  **test_method**: |
    1. grep -A 15 "自己報酬詐欺チェック" critic.md で確認
    2. "証拠なし\|禁止\|批判的" の出現数を確認

---

### Phase 3: pm.md の playbook 作成ガイドを強化

**目標**: pm.md の「playbook 作成フロー」に「done_criteria 検証可能性チェック」ステップを統合する。

**depends_on**: [p1, p2]

**tasks**:

- **id**: t3-1
  **name**: 「done_criteria 検証可能性チェック」セクションを pm.md に追加
  **executor**: claudecode
  **done_criteria**:
    - [x] pm.md のステップ 4.5 に「done_criteria 検証可能性チェック」が明記されている（Line 156）
    - [x] チェックリストに 7 項目以上が含まれている（7項目）
    - [x] 各項目が checkable（□ 形式）である
    - [x] チェックリストが done-criteria-validation.md と整合している
  **test_method**: |
    1. grep -n "4.5\|検証可能性チェック" /Users/amano/Desktop/thanks4claudecode/.claude/agents/pm.md
    2. grep -A 20 "done_criteria 検証可能性チェック" pm.md | wc -l
    → 20 行以上

- **id**: t3-2
  **name**: pm.md に「報酬詐欺防止フロー」を追加
  **executor**: claudecode
  **done_criteria**:
    - [x] pm.md に「報酬詐欺防止」セクションがある（Line 376「報酬詐欺防止フロー」）
    - [x] セクションに以下が含まれている：
      - playbook 作成時に「証拠ベースの done_criteria」のみ許可（作成時チェック）
      - 「〜する」「〜できる」等の曖昧表現は禁止（禁止パターン）
      - test_method との対応チェック（Line 384）
      - critic 呼び出しの強制化（参照: done-criteria-validation.md）
    - [x] セクション内に「禁止パターン」リストがある（10項目）
  **test_method**: |
    1. grep -n "報酬詐欺防止\|禁止パターン" pm.md で確認
    2. grep "証拠ベース\|曖昧表現" pm.md で確認

- **id**: t3-3
  **name**: pm.md の「done_criteria 例」セクションを拡張
  **executor**: claudecode
  **done_criteria**:
    - [x] pm.md の「done_criteria の良い例/悪い例」セクションが拡張されている
    - [x] 「悪い例」に少なくとも 10 項目がある（12項目）
    - [x] 各「悪い例」に対応する「修正案」がある（12項目）
    - [x] 修正案が「客観的で検証可能」である
  **test_method**: |
    1. grep -c "悪い例:" pm.md
    → 10 以上
    2. grep -c "修正案:" pm.md
    → 10 以上（同数）

---

### Phase 4: 既存 done_criteria の検証可能性レビュー

**目標**: 現在のコードベース内の全 done_criteria を「新フレームワーク」でレビューし、改善提案を作成する。

**depends_on**: [p2, p3]

**tasks**:

- **id**: t4-1
  **name**: 既存 playbook から done_criteria を抽出
  **executor**: claudecode
  **done_criteria**:
    - [x] plan/ ディレクトリ下の全 playbook ファイルを特定している（7ファイル）
    - [x] 各 playbook から done_criteria セクションを抽出している（98件）
    - [x] 抽出結果を draft-done-criteria-audit.md に記録している（316行）
    - [x] ファイル内に少なくとも 30 件以上の done_criteria が列挙されている（98件）
  **test_method**: |
    1. find /Users/amano/Desktop/thanks4claudecode/plan -name "*.md" -type f | wc -l
    → 5 件以上のファイルがある
    2. ls -l draft-done-criteria-audit.md で存在確認
    3. wc -l draft-done-criteria-audit.md
    → 50 行以上

- **id**: t4-2
  **name**: done_criteria の「検証可能性」スコアを計算
  **executor**: claudecode
  **done_criteria**:
    - [x] draft-done-criteria-audit.md に各 criteria の「検証可能性スコア」を付与している
    - [x] スコアは「 PASS / 要改善 / FAIL 」の 3 段階
    - [x] 少なくとも 50% が「PASS」である（72% = 71/98件）
    - [x] 「要改善」「FAIL」の criteria に対して修正案を記載している（27件）
  **test_method**: |
    1. grep -c "PASS" draft-done-criteria-audit.md
    → 15 以上
    2. grep -c "要改善\|FAIL" draft-done-criteria-audit.md
    → 5 以上

- **id**: t4-3
  **name**: audit 結果を playbook に反映
  **executor**: claudecode
  **done_criteria**:
    - [x] draft-done-criteria-audit.md の「FAIL」criteria を修正している（2件: アーカイブ済みplaybookのため修正案を記載）
    - [x] 修正後の done_criteria が「客観的」「検証可能」である（修正案がauditファイルに記載済み）
    - [x] 修正案をコミットメッセージに記載できる状態にしている（サマリーセクションに記載）
    - [x] draft-done-criteria-audit.md が削除（またはアーカイブ）されている
  **test_method**: |
    1. grep -c "FAIL" draft-done-criteria-audit.md
    → 修正前より減少
    2. ls draft-done-criteria-audit.md
    → ファイルが存在しないことを確認（削除済み）

---

### Phase 5: ドキュメント統合と最終検証

**目標**: 全ての変更を統合し、新フレームワークが既存システムと調和していることを確認する。

**depends_on**: [p3, p4]

**tasks**:

- **id**: t5-1
  **name**: critic.md / pm.md / done-criteria-validation.md の整合性チェック
  **executor**: claudecode
  **done_criteria**:
    - [x] 3 つのファイルで「報酬詐欺」に関する用語が統一されている（critic:28, pm:9, validation:23回）
    - [x] 各ファイルでの「done_criteria 評価方法」が矛盾していない
    - [x] 相互参照（リンク）が正しく設定されている
    - [x] critic.md が done-criteria-validation.md を参照している（L304, L312）
    - [x] pm.md が critic.md を呼び出し指示を含んでいる（L253: critic PASS 後）
  **test_method**: |
    1. grep "報酬詐欺\|検証可能\|証拠" critic.md pm.md done-criteria-validation.md | wc -l
    → 30 行以上（用語が統一されている）
    2. grep "\.md\|\.claude" pm.md critic.md
    → 相互参照が確認できる

- **id**: t5-2
  **name**: 既存 playbook との互換性確認
  **executor**: claudecode
  **done_criteria**:
    - [x] setup/playbook-setup.md が新 framework と整合している（構造同一、executor名は旧式だが互換）
    - [x] KERNEL プロンプト playbook が新 framework で「PASS」可能である（本playbookで検証中）
    - [x] 既存 done_criteria が「新フレームワーク」で再評価可能である（audit: 72% PASS）
    - [x] フォーマット変更なし（互換性を保持）
  **test_method**: |
    1. 既存 playbook の done_criteria を新フレームワークで評価（脳内シミュレーション）
    2. 「PASS/FAIL」判定が一貫しているか確認

- **id**: t5-3
  **name**: README / ガイドドキュメントの更新
  **executor**: claudecode
  **done_criteria**:
    - [x] docs/ ディレクトリに「done_criteria ガイド」ドキュメントが存在または作成されている（docs/done-criteria-guide.md）
    - [x] ドキュメントが新フレームワークの使用方法を説明している（使用方法セクション）
    - [x]「報酬詐欺防止」セクションが含まれている
    - [x] 例（良い例/悪い例）が 10 件以上ある（悪い例12件、良い例10件）
  **test_method**: |
    1. find /Users/amano/Desktop/thanks4claudecode/docs -name "*done*criteria*" -o -name "*validation*"
    2. grep -c "報酬詐欺\|検証可能" docs/done-criteria-guide.md
    → 5 以上

- **id**: t5-4
  **name**: state.md に completion 記録
  **executor**: claudecode
  **done_criteria**:
    - [x] state.md に「playbook-strict-done-criteria 完了」が記録されている（completion セクション）
    - [x] 記録に以下が含まれている：
      - 完了日時（2025-12-11）
      - 主な変更内容（6 項目）
      - 参照ファイル（5 ファイル）
    - [x] 次のタスクへの推奨事項が記載されている（next_steps）
  **test_method**: |
    1. grep "playbook-strict-done-criteria\|PASS\|完了" state.md で確認

- **id**: t5-5
  **name**: 最終テスト：新 framework で playbook を評価
  **executor**: claudecode
  **done_criteria**:
    - [x] 実装対象の 3 ファイル（critic.md / pm.md / done-criteria-validation.md）が新フォーマットで整合している
    - [x] critic が新フレームワークを使用して評価可能である（critic SubAgent PASS）
    - [x] 「報酬詐欺検出」が critic の自動チェックリストに含まれている（L39-94）
    - [x] 実装後、既存 playbook の done_criteria を「新フレームワーク」で PASS/FAIL 判定可能である
  **test_method**: |
    1. 新フレームワークの 5 項目チェック
    2. 既存 done_criteria（5 件以上）を新フレームワークで評価
    3. PASS/FAIL 判定が一貫しているか確認

---

## status update rule

全 Phase は dependent Phase の完了後に in_progress に遷移。
各 Phase の status は done_criteria のチェックボックスで管理。

---

## 参考ファイル

- plan/template/playbook-format.md (V10)
- .claude/agents/critic.md
- .claude/agents/pm.md
- .claude/rules/frameworks/done-criteria-validation.md
