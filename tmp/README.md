# Temporary Files (テンポラリファイル)

> **このフォルダは一時ファイル（テンポラリファイル）専用です。playbook 完了時に自動削除されます。**

## What goes here

- Test results and scenarios
- Temporary analysis files
- Debug outputs
- Intermediate artifacts

## What does NOT go here

- Configuration files
- Permanent documentation
- Playbook/project files

## Cleanup

Files in this directory are automatically deleted when:
1. A playbook is completed
2. A milestone is achieved
3. The `cleanup-hook.sh` is triggered

## Warning

**This folder is NOT tracked by git.** Do not store important files here.
