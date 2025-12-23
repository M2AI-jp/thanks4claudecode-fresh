# completion-criteria.md

> **playbook 完了時の検証基準**
>
> アーカイブ前に満たすべき条件を定義する。

---

## Purpose

playbook をアーカイブする前に、全ての完了条件が満たされていることを確認する。
「完了したつもり」でアーカイブされることを防止する。

---

## 完了条件チェックリスト

### 1. Phase レベル

```yaml
必須条件:
  - [ ] 全 Phase の **status** が done
  - [ ] 各 Phase の goal が達成されている
  - [ ] Phase 間の依存関係が満たされている

検証方法:
  - grep '^\*\*status\*\*:' playbook.md
  - 全て done であることを確認
```

### 2. subtask レベル

```yaml
必須条件:
  - [ ] 全 subtask が完了（- [x]）
  - [ ] 全 subtask に validations がある
  - [ ] validations が全て PASS
  - [ ] validated タイムスタンプがある

検証方法:
  - grep -c '\- \[ \]' playbook.md  # 0 であること
  - grep -c '\- \[x\]' playbook.md  # 全 subtask 数と一致
```

### 3. final_tasks レベル

```yaml
必須条件:
  - [ ] final_tasks セクションが存在（存在する場合）
  - [ ] 全 final_tasks が完了（- [x]）

検証方法:
  - grep -A 100 '## final_tasks' playbook.md
  - 全てのタスクが [x] であること
```

### 4. p_final レベル

```yaml
必須条件:
  - [ ] p_final Phase が存在
  - [ ] p_final の全 subtask が完了
  - [ ] done_when の各項目が検証済み
  - [ ] 証拠が提示されている

検証方法:
  - p_final セクション内の subtask を確認
  - validations が全て PASS であること
```

---

## 完了禁止条件

```yaml
以下がある場合、アーカイブ不可:
  - 未完了の subtask（- [ ]）がある
  - p_final が done でない
  - validations に FAIL がある
  - 証拠なしで PASS と記述されている
  - reviewed: false のまま
```

---

## アーカイブ前の最終確認

```yaml
確認項目:
  1. state.md の playbook.active がこの playbook を指しているか
  2. 全 Phase, subtask, final_tasks が完了しているか
  3. p_final の検証が完了しているか
  4. 関連ドキュメントが更新されているか

アーカイブ後の作業:
  1. mv plan/playbook-*.md plan/archive/
  2. state.md の playbook.active を null に更新
```

---

## 参照

- docs/archive-operation-rules.md - アーカイブ操作ルール
- plan/template/playbook-format.md - playbook フォーマット
- .claude/skills/completion-review/SKILL.md - Skill 仕様
