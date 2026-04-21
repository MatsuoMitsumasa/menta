# MENTA 仕様メモ

## 概要

MENTA は、CGI 環境でも軽快に動かすことを意識した Perl 製の軽量 Web アプリケーションフレームワークです。

主な特徴:

- CGI と PSGI の両方で動作できる
- URL をコントローラやテンプレートへ単純に対応付ける
- ビューには `Text::MicroTemplate` を使う
- 関数名の接頭辞をもとにプラグインを自動ロードする
- アプリケーション設定は `config.pl` にまとめる

## ディレクトリ構成

このリポジトリで主要なディレクトリは次のとおりです。

- `app/controller/`: アプリケーションのコントローラとテンプレート
- `app/data/`: SQLite やセッションなどのデータ置き場
- `app/static/`: 画像、CSS、JavaScript などの静的ファイル
- `lib/`: MENTA 本体
- `plugins/`: プラグイン実装
- `cgi-extlib-perl/extlib/`: 同梱される外部 Perl ライブラリ

## エントリポイント

MENTA の入口は主に 2 つあります。

- `menta.cgi`
  - `MENTA->run_menta(do 'config.pl')` を呼び出す
  - CGI での実行を想定
- `menta.psgi`
  - `MENTA->create_app(do "$base/config.pl")` を呼び出す
  - PSGI/Plack での実行を想定

どちらも `config.pl` を読み込んでアプリケーションを起動します。

## リクエスト処理の流れ

リクエスト処理の中心は `MENTA->create_app` です。

基本的な流れ:

1. PSGI の `env` を受け取る
2. `MENTA::Request` を生成する
3. `MENTA::Context` を生成し、そのリクエスト専用のコンテキストとして保持する
4. `BEFORE_DISPATCH` トリガーを実行する
5. `MENTA::Dispatch->dispatch($env)` に処理を渡す
6. コントローラやテンプレートからレスポンスを確定する

実装上の重要な特徴:

- MENTA は通常の `return` でレスポンスを返す設計ではありません
- `render_and_print`、`redirect`、`finalize` は内部で `_finish` を呼び、PSGI のレスポンス配列を `die` して処理を抜けます

## 設定

設定は `config.pl` に Perl のハッシュリファレンスとして定義します。

トップレベルの主なキー:

- `menta`: フレームワーク自体の設定
- `application`: アプリケーション固有の設定

このリポジトリにある主な設定項目:

- `menta.fatals_to_browser`
  - 有効な場合、例外をブラウザに HTML のスタックトレースとして表示する
- `menta.max_post_body`
  - POST ボディの最大サイズとして想定されている値
- `menta.support_mobile`
  - モバイル端末向けの文字コード処理を有効にする
- `menta.base_dir`
  - コントローラ、データ、プラグインを探す基準ディレクトリ
- `application.sql.dsn`
  - SQL プラグインが使う DBI の DSN
- `application.counter.file`
  - counter プラグインが使うデータファイル

## ルーティング

ルーティングは `lib/MENTA/Dispatch.pm` に実装されています。

### 通常ルート

リクエストパスの扱い:

- `PATH_INFO` を取り出す
- 空パスは `index` とみなす
- 末尾が `/` のときは `/index` に変換する

対応例:

- `/` -> `app/controller/index.pl` または `app/controller/index.mt`
- `/manual/install` -> `app/controller/manual/install.pl` または `.mt`
- `/nopaste/` -> `app/controller/nopaste/index.pl`

### 解決順序

正規化したパスに対して次の順で探します。

1. `app/controller/<path>.pl`
2. `app/controller/<path>.mt`
3. `static/...` の場合は静的ファイルとして配信

どちらも存在しない場合はエラーになります。

### プラグインルート

次の形式の URL はプラグインのアクションとして処理されます。

- `/plugin/<plugin_name>/<action>`

内部では次のように変換されます。

- 対象ファイル: `plugins/<plugin_name>.pl`
- 呼び出すメソッド: `do_<action>`

例:

- `/plugin/session/logout` -> `MENTA::Plugin::Session->do_logout()`

### 静的ファイル

`static/` で始まるパスは `app/static/` 配下から配信します。

セキュリティ上の挙動:

- 実際のファイルパスを解決して `app/static/` 配下にあることを確認する
- これによりディレクトリトラバーサルを防ぐ

## コントローラ

コントローラは `app/controller/` 配下の Perl ファイルで、通常は先頭で次を読み込みます。

```perl
use MENTA::Controller;
```

`MENTA::Controller` はソースフィルタを使って各 `.pl` を一時的な package に包み、ヘルパー関数を自動で使えるようにします。

コントローラ内でよく使うヘルパー:

- `param`
- `render`
- `render_and_print`
- `redirect`
- `finalize`
- `uri_for`
- `static_file_path`
- `docroot`
- `upload`
- `is_post_request`
- `mobile_agent`

典型的な書き方:

```perl
use MENTA::Controller;

sub run {
    if (is_post_request()) {
        redirect(uri_for('index'));
    } else {
        render_and_print('index.mt');
    }
}
```

期待される役割:

- コントローラは `run` を定義する
- `run` の中で処理を行い、最後は `render_and_print`、`redirect`、`finalize` のいずれかで応答を確定する

## テンプレート

テンプレートは `.mt` ファイルで、`Text::MicroTemplate` により描画されます。

### 基本構文

- `? ...` で Perl 文を書く
- `<?= ... ?>` で値を出力する

例:

```mt
<!doctype html>
<p>Hello to <?= param('user') ?></p>
```

### レイアウト継承

MENTA では `extends` と `block` を使って簡単なレイアウト継承のような構造を作れます。

例:

```mt
? extends "base.mt";
? block content => sub {
<p>Hello</p>
? }
```

ベーステンプレート側では名前付きブロックを定義します。

```mt
<? block title => "MENTA" ?>
<? block content => "" ?>
```

### テンプレートキャッシュ

コンパイル済みテンプレートは `MENTA::mt_cache_dir()` が返すディレクトリに保存されます。

挙動:

- キャッシュファイルが存在し、元テンプレートより新しければキャッシュを使う
- そうでなければ再コンパイルしてキャッシュを更新する

## プラグイン

MENTA のプラグインは `plugins/*.pl` に置かれます。

プラグインは、呼び出した関数名の接頭辞に応じて自動でロードされます。

例:

- `sql_select_all(...)` を呼ぶと `plugins/sql.pl` をロード
- `session_get(...)` を呼ぶと `plugins/session.pl` をロード
- `openid_get_user(...)` を呼ぶと `plugins/openid.pl` をロード

この仕組みは `MENTA::AUTOLOAD` で実現されています。

### 命名規則

関数名が `<prefix>_` で始まる場合、MENTA は次のファイルを探します。

- `plugins/<prefix>.pl`

ロード後、そのプラグイン package に定義された関数を `MENTA` 側へ取り込みます。

### プラグインルート

プラグインは URL 経由で呼ばれるアクションも公開できます。

その場合は次の名前のメソッドを定義します。

- `do_<action>`

これは `/plugin/<plugin>/<action>` という URL に対応します。

## リクエストとレスポンスの補助機能

### リクエストアクセス

`MENTA::Request` は PSGI 環境を包み、次の機能を提供します。

- `env`
- `param`
- `upload`
- `header`
- `headers`

入力値は `MENTA::decode_input` を通してデコードされます。`support_mobile` が有効な場合は端末に応じて文字コード処理が変わります。

### レスポンス補助

主なレスポンス用メソッド:

- `render_and_print($template, @args)`
- `redirect($location)`
- `finalize($body, $content_type?)`

いずれも内部では `_finish` を通して処理を終了します。

## 文字コードとモバイル対応

`menta.support_mobile` が有効な場合:

- 入力のデコードが端末向け文字コードに応じて切り替わる
- 出力時のエンコードも端末向け文字コードに応じて切り替わる
- `charset` は `UTF-8` または `Shift_JIS` になる

この挙動は `MENTA::Util` と `MENTA::MobileAgent` に実装されています。

## アプリケーション実装の基本パターン

サンプルの `nopaste` コントローラは MENTA の典型的な使い方になっています。

基本パターン:

1. 必要ならテーブルや保存先を初期化する
2. `is_post_request` で GET/POST を分岐する
3. `param` でフォーム入力を読む
4. `sql_*` のようなプラグイン関数で保存や検索を行う
5. テンプレートを返すか、別 URL へリダイレクトする

つまり MENTA の基本設計は、薄いルーティング、単純なコントローラ、プラグインによる補助機能、という構成です。

## 拡張時の指針

新しいページを追加する場合:

1. 単純なページなら `app/controller/<name>.mt` を追加する
2. ロジックが必要なら `app/controller/<name>.pl` を追加して `run` を定義する

再利用できる機能を追加する場合:

1. `plugins/<name>.pl` を作る
2. `<name>_*` 形式の関数を定義する
3. 必要なら `do_<action>` も定義する

アプリ設定を追加する場合:

1. `config.pl` の `application` セクションに項目を足す
2. `config->{application}->{...}` で参照する

## まず読むべきファイル

MENTA の理解や拡張を進める際は、まず次のファイルを見るのが効率的です。

- `lib/MENTA.pm`
- `lib/MENTA/Dispatch.pm`
- `lib/MENTA/Controller.pm`
- `lib/MENTA/TemplateLoader.pm`
- `config.pl`
- `app/controller/nopaste/index.pl`
- `app/controller/base.mt`
