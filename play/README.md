# play/ (Playbook v2)

playbook の **計画/進捗/証拠** を分離して管理するためのディレクトリ。
旧 `plan/playbook-*.md` は使用禁止。

## 構造

- `play/<id>/plan.json` : 計画（レビュー後は変更不可）
- `play/<id>/progress.json` : 進捗と検証結果（final_tasks/critic 含む）
- `play/<id>/evidence/` : 証拠ファイル（コマンド出力/引用/ログ）
- `play/archive/<id>/` : 完了後のアーカイブ

## 基本ルール

1. **plan と progress を分離**  
   plan は「何をするか」、progress は「どう検証したか」を記録する。

2. **証拠はファイルで残す**  
   progress の evidence にはファイルパスを記録し、内容は `evidence/` に保存する。

3. **reviewed 後の plan は固定**  
   reviewed: true の plan は原則編集禁止（修正は新 playbook）。

4. **review_profile でレビュー深度を指定**  
   standard は通常レビュー、system-test は構造チェック中心（内容の細部は扱わない）。

5. **done 判定は progress + critic 依存**  
   progress の validations と critic 結果が揃わない限り完了不可。

6. **final_tasks は progress で管理**  
   plan の final_tasks と同数のステータスを progress に記録する。

## 参照テンプレート

- `play/template/plan.json`
- `play/template/progress.json`
