<div align="center">

# CC Switch Fork

[English](README.md) | [中文](README_ZH.md) | 日本語

このリポジトリは `cc-switch` の fork です。README には、この fork で現在も有効な内容だけを残しています。主にローカル開発、ビルド、実行方法を説明します。

</div>

## 位置づけ

この fork はローカルカスタマイズと継続的な開発用です。現在のコードベースは次を扱います。

- Claude Code、Codex、Gemini、OpenCode、OpenClaw の設定管理
- MCP、Prompts、Skills、プロキシ、フェイルオーバー、使用量関連機能
- Tauri デスクトップ版と単一ポートの Web モード

## スクリーンショット

|                  メイン画面                   |                  プロバイダ追加                  |
| :-------------------------------------------: | :----------------------------------------------: |
| ![Main Interface](assets/screenshots/main-en.png) | ![Add Provider](assets/screenshots/add-en.png) |

## ローカル開発

### 必要環境

- Node.js 18+
- pnpm 8+
- Rust 1.85+
- Tauri CLI 2.8+

### よく使うコマンド

```bash
# 依存関係をインストール
pnpm install

# デスクトップ開発
pnpm dev

# 型チェック
pnpm typecheck

# フロントエンド単体テスト
pnpm test:unit

# デスクトップ版をビルド
pnpm build
```

### Rust バックエンド

```bash
cd src-tauri

cargo fmt
cargo clippy
cargo test
```

## Web モード

### 単一ポート起動

```bash
./start-web.sh
```

起動後のアクセス先：

```text
http://localhost:17666
```

停止：

```bash
./stop-web.sh
```

実行時ファイルは既定で `./.run/web/` に書き込まれます。

- ログ：`backend.log`
- PID：`backend.pid`

別ディレクトリを使う場合：

```bash
CC_SWITCH_RUNTIME_DIR=/tmp/cc-switch-web ./start-web.sh
```

### 手動デバッグ

```bash
# Web バックエンドを起動
pnpm dev:server

# フロントエンド開発サーバーを起動（ホットリロード）
pnpm dev:web
```

補足：

- `17666`：バックエンド、Web UI、`/api`、`/api/ws`
- `3000`：手動フロントエンド開発時だけ使う Vite dev server

### 手動で Web ビルド

```bash
pnpm build:web
cargo build --release --manifest-path crates/server/Cargo.toml
./crates/server/target/release/cc-switch-web
```

## 技術スタック

- フロントエンド：React 18、TypeScript、Vite、TailwindCSS、TanStack Query
- バックエンド：Tauri 2、Rust、tokio、serde
- テスト：vitest、MSW、@testing-library/react

## ディレクトリ構成

```text
src/                 フロントエンドコード
src-tauri/           Tauri デスクトップバックエンド
crates/server/       Web サーバー
crates/core/         共通コアロジック
tests/               フロントエンドテスト
assets/              スクリーンショットなどの素材
docs/                補助ドキュメント
```

## ライセンス

[LICENSE](LICENSE) を参照してください。
