# MENTA 関数リファレンス

このドキュメントでは、MENTA 本体が提供する「呼び出し可能な関数」を整理します。

対象:

- コントローラから直接呼べる関数
- テンプレートから直接呼べる関数
- テンプレート専用の構文的ヘルパー

対象外:

- `plugins/*.pl` で提供されるプラグイン関数
- `MENTA::Util` や `MENTA::Request` などの内部実装向け関数
- `MENTA->create_app` などアプリ起動用のクラスメソッド

## 利用可能な関数一覧

### コントローラで使える関数

`use MENTA::Controller;` を書いた `.pl` コントローラでは、次の関数が使えます。

- `escape_html`
- `unescape_html`
- `raw_string`
- `config`
- `render`
- `param`
- `query_param`
- `param_json`
- `env`
- `cookie`
- `mobile_agent`
- `uri_for`
- `static_file_path`
- `docroot`
- `redirect`
- `is_post_request`
- `respond`
- `render_and_print`
- `render_and_print_as`
- `finalize`
- `finalize_json`
- `upload`
- `current_url`
- `wants_json`
- `set_cookie`
- `debug_run`

### テンプレートで使える関数

`.mt` テンプレートでは次の関数が使えます。

- `escape_html`
- `unescape_html`
- `raw_string`
- `config`
- `render`
- `param`
- `env`
- `cookie`
- `mobile_agent`
- `uri_for`
- `static_file_path`
- `docroot`
- `redirect`
- `current_url`
- `wants_json`

### テンプレート専用ヘルパー

`.mt` テンプレートでは、上記に加えて次の構文用ヘルパーが使えます。

- `extends`
- `block`

## 使える場所の対応表

| 関数 | コントローラ | テンプレート | 用途 |
| --- | --- | --- | --- |
| `escape_html` | ○ | ○ | HTML エスケープ |
| `unescape_html` | ○ | ○ | HTML アンエスケープ |
| `raw_string` | ○ | ○ | エスケープ済み文字列として扱う |
| `config` | ○ | ○ | 設定参照 |
| `render` | ○ | ○ | 部分テンプレート描画 |
| `param` | ○ | ○ | リクエストパラメータ取得 |
| `query_param` | ○ | × | クエリ文字列パラメータ取得 |
| `param_json` | ○ | × | JSON リクエスト本文取得 |
| `env` | ○ | ○ | PSGI 環境取得 |
| `cookie` | ○ | ○ | リクエスト cookie 取得 |
| `mobile_agent` | ○ | ○ | モバイル端末情報取得 |
| `uri_for` | ○ | ○ | URL 組み立て |
| `static_file_path` | ○ | ○ | 静的ファイル URL 作成 |
| `docroot` | ○ | ○ | アプリのベース URL 取得 |
| `redirect` | ○ | ○ | リダイレクト応答 |
| `is_post_request` | ○ | × | POST 判定 |
| `respond` | ○ | × | 任意のステータス、ヘッダ、本文で応答 |
| `render_and_print` | ○ | × | テンプレート描画してレスポンス確定 |
| `render_and_print_as` | ○ | × | Content-Type を指定してテンプレート描画 |
| `finalize` | ○ | × | 任意レスポンス本文で応答確定 |
| `finalize_json` | ○ | × | Perl データを JSON にして返す |
| `upload` | ○ | × | アップロードファイル取得 |
| `current_url` | ○ | ○ | 現在 URL を取得 |
| `wants_json` | ○ | ○ | JSON を期待するリクエストか判定 |
| `set_cookie` | ○ | × | レスポンスに cookie を追加 |
| `debug_run` | ○ | × | 例外を簡易 HTML で表示するデバッグ実行 |
| `extends` | × | ○ | レイアウト継承 |
| `block` | × | ○ | ブロック定義・展開 |

## 各関数の説明とサンプル

### `escape_html($text)`

HTML 特殊文字をエスケープします。

主な変換対象:

- `&`
- `<`
- `>`
- `"`
- `'`

サンプル:

```perl
my $safe = escape_html(param('body'));
```

```mt
<p><?= escape_html(param('q')) ?></p>
```

### `unescape_html($text)`

HTML エンティティを元の文字に戻します。

サンプル:

```perl
my $raw = unescape_html('&lt;b&gt;test&lt;/b&gt;');
```

### `raw_string($text)`

文字列を「すでに安全な文字列」として扱い、テンプレート側の自動エスケープを避けたいときに使います。

用途は限定的です。ユーザー入力に対して安易に使うべきではありません。

サンプル:

```perl
my $html = raw_string('<strong>OK</strong>');
```

```mt
<?= raw_string('<span class="ok">done</span>') ?>
```

### `config()`

`config.pl` の内容を取得します。

サンプル:

```perl
my $title = config->{application}->{title};
```

```mt
<title><?= config->{application}->{title} ?></title>
```

### `render($template, @args)`

テンプレートの一部を描画して、その結果を返します。

`render_and_print` と違い、レスポンスは確定しません。レイアウトや部品テンプレートの埋め込みに向きます。

サンプル:

```perl
my $body = render('parts/menu.mt', $items);
```

```mt
<aside>
<?= render('shared/sidebar.mt', $user) ?>
</aside>
```

### `param($name)`

リクエストパラメータを取得します。

特徴:

- スカラコンテキストでは単一値を返す
- 配列コンテキストでは複数値を返す
- 文字コードは MENTA 側でデコードされる

サンプル:

```perl
my $name = param('name');
my @tags = param('tag');
```

```mt
<p><?= param('user') ?></p>
```

### `query_param($name)`

クエリ文字列だけからパラメータを取得します。

コントローラ専用です。

`param()` と違い、POST 本文を読まないため、`POST + application/json` で `param_json()` より先に URL の `mode` などを判定したい場合に使えます。

サンプル:

```perl
my $mode = query_param('mode') || '';

if ($mode eq 'json' && ($req_env->{REQUEST_METHOD} || '') eq 'POST') {
    my $payload = param_json();
    finalize_json({ ok => 1, payload => $payload });
}
```

補足:

- `+` は空白に変換されます
- `%xx` 形式の URL エンコードはデコードされます
- 値が空の場合は空文字列、存在しない場合は `undef` を返します
- 同じ名前のパラメータが複数ある場合は最後の値を返します

### `param_json()`

`application/json` のリクエスト本文を Perl のデータ構造にデコードして返します。

コントローラ専用です。

サンプル:

```perl
my $payload = param_json();
my $name = $payload->{name};
```

JSON POST の `mode` などをクエリ文字列から取得する場合は、`param()` より先に `query_param()` を使ってください。

```perl
my $req_env = env();
my $mode = query_param('mode') || '';

if ($mode eq 'json' && ($req_env->{REQUEST_METHOD} || '') eq 'POST') {
    my $payload = param_json();
    finalize_json({ ok => 1, payload => $payload });
}
```

補足:

- 本文が空なら `undef`
- 不正な JSON の場合は例外になります
- `POST + application/json` では、先に `param()` や `upload()` を呼ぶと `CGI::Simple` がリクエスト本文を読むため、その後の `param_json()` が空になることがあります
- JSON 本文を読む処理では、クエリ文字列の判定に `param()` ではなく `query_param()` を使うと安全です
- CGI/PSGI 環境によっては、JSON POST の本文を読まずに応答するとレスポンス本文が期待どおり返らないことがあります。JSON POST を扱う処理では、本文を使わない場合でも先に `param_json()` で読み切ってから応答すると安全です

### `env()`

PSGI の `env` をそのまま返します。

サンプル:

```perl
my $method = env()->{REQUEST_METHOD};
my $path   = env()->{PATH_INFO};
```

または、複数回参照する場合は変数に受けます。

```perl
my $req_env = env();
my $method = $req_env->{REQUEST_METHOD};
my $query  = $req_env->{QUERY_STRING};
```

```mt
<p><?= env()->{HTTP_HOST} ?></p>
```

### `cookie($name?)`

リクエスト cookie を取得します。

引数を渡した場合はその cookie の値を返し、省略した場合は cookie 一覧を返します。

省略時に返る一覧は、cookie 名をキー、`CGI::Simple::Cookie` オブジェクトを値にしたハッシュリファレンスです。

サンプル:

```perl
my $sid = cookie('sid');
```

```mt
? if (cookie('theme') eq 'dark') {
<body class="dark">
? }
```

### `mobile_agent()`

`HTTP::MobileAgent` オブジェクトを返します。

モバイル端末判定やキャリア判定に使います。

サンプル:

```perl
if (mobile_agent->is_docomo) {
    # docomo 向け処理
}
```

```mt
? if (mobile_agent->is_non_mobile) {
<p>PC 向け表示</p>
? }
```

### `uri_for($path, \%query)`

アプリケーションの相対 URL を生成します。

サンプル:

```perl
my $url = uri_for('manual/install', { step => 1 });
```

```mt
<a href="<?= uri_for('demo/hello', { user => 'kazuhooku' }) ?>">Hello</a>
```

補足:

- ベースは `docroot()` が使われる
- クエリ文字列は簡易的に URL エンコードされる

### `static_file_path($path)`

`app/static/` 配下のファイル URL を生成します。

サンプル:

```perl
my $css = static_file_path('style-sites.css');
```

```mt
<img src="<?= static_file_path('menta-logo.png') ?>" alt="MENTA">
```

### `docroot()`

アプリケーションのベース URL を返します。

`SCRIPT_NAME` をもとに末尾 `/` 付きで返します。

サンプル:

```perl
my $root = docroot();
```

```mt
<a href="<?= docroot() ?>">トップへ</a>
```

### `redirect($location)`

指定 URL へ 302 リダイレクトします。

この関数を呼ぶと、その場でレスポンスが確定します。

サンプル:

```perl
redirect(uri_for('index'));
```

```mt
? if (!param('token')) {
?     redirect(uri_for('login'));
? }
```

補足:

- テンプレートからも呼べますが、通常はコントローラで使う方が自然です

### `is_post_request()`

現在のリクエストが POST かどうかを返します。

コントローラ専用です。

サンプル:

```perl
if (is_post_request()) {
    # 保存処理
} else {
    # 表示処理
}
```

### `respond($status, $headers, $body)`

任意のステータスコード、ヘッダ、本文でレスポンスを返します。

コントローラ専用です。

サンプル:

```perl
respond(204, [], []);
```

```perl
respond(201, ['Content-Type' => 'text/plain; charset=UTF-8'], 'created');
```

補足:

- `$headers` は通常 `['Header-Name' => 'value', ...]`
- `$body` は文字列または PSGI レスポンス本文用の配列リファレンスを渡せます
- `Content-Type` は自動では付きません。必要な場合は `$headers` に明示してください
- `set_cookie` で追加した `Set-Cookie` も自動でマージされます

### `render_and_print($template, @args)`

テンプレートを描画し、その結果を HTML レスポンスとして返します。

この関数を呼ぶとレスポンスが確定し、以降の処理は続きません。

コントローラ専用です。

サンプル:

```perl
render_and_print('index.mt');
```

```perl
render_and_print('nopaste/tmpl/show.mt', $row);
```

### `render_and_print_as($content_type, $template, @args)`

テンプレートを描画し、指定した `Content-Type` でレスポンスを返します。

`render_and_print` の拡張版で、HTML 以外を返したい場合に使います。

コントローラ専用です。

サンプル:

```perl
render_and_print_as('text/plain; charset=UTF-8', 'api/version.mt');
```

```perl
render_and_print_as('application/json; charset=UTF-8', 'api/user.mt', $user);
```

JSON テンプレート例:

```mt
? my ($user) = @_;
{
  "id": "<?= $user->{id} ?>",
  "name": "<?= $user->{name} ?>"
}
```

補足:

- テンプレート出力そのものを返すので、JSON の組み立てはテンプレート側で行う
- 既存の `render_and_print` は従来どおり `text/html` を返す

### `finalize($body, $content_type?)`

テンプレートを使わずにレスポンス本文を直接返します。

第 2 引数を省略した場合、`text/html; charset=...` が使われます。

コントローラ専用です。

サンプル:

```perl
finalize('OK');
```

```perl
finalize('plain text', 'text/plain; charset=UTF-8');
```

### `finalize_json($data, $status?, $headers?)`

Perl のハッシュリファレンスや配列リファレンスを JSON にエンコードして返します。

`Content-Type` は `application/json; charset=UTF-8` です。

コントローラ専用です。

サンプル:

```perl
finalize_json({
    ok   => 1,
    user => {
        id   => 10,
        name => 'matsuo',
    },
});
```

```perl
finalize_json([
    { id => 1, name => 'A' },
    { id => 2, name => 'B' },
]);
```

ステータスコードや追加ヘッダも指定できます。

```perl
finalize_json({ error => 'not found' }, 404);
finalize_json({ ok => 1 }, 201, ['X-App' => 'menta']);
```

使い分け:

- JSON を Perl データから安全に返したいなら `finalize_json`
- JSON 文字列をテンプレートで自分で組み立てたいなら `render_and_print_as('application/json; charset=UTF-8', ...)`

### `upload($name)`

アップロードされたファイルハンドルを取得します。

コントローラ専用です。

サンプル:

```perl
my $fh = upload('image');
```

注意:

- 実際の取り回しは `CGI::Simple` ベースです
- 使う前に multipart/form-data のフォームになっていることを確認する必要があります

### `current_url()`

現在の URL を返します。

実装上は `Host`、`docroot()`、`PATH_INFO`、`QUERY_STRING` を組み合わせて作られます。

サンプル:

```perl
my $url = current_url();
```

```mt
<p>現在の URL: <?= current_url() ?></p>
```

### `wants_json()`

クライアントが JSON を期待しているかを判定します。

現在は主に次を見ています。

- `Accept: application/json`
- `Content-Type: application/json`

サンプル:

```perl
if (wants_json()) {
    finalize_json({ ok => 1 });
}
```

```mt
? if (wants_json()) {
<p>JSON クライアントです</p>
? }
```

### `set_cookie($name, $value, %options)`

レスポンスに `Set-Cookie` ヘッダを追加します。

コントローラ専用です。

指定できる主なオプション:

- `path`
- `domain`
- `expires`
- `secure`

サンプル:

```perl
set_cookie('sid', 'abc123', path => '/', secure => 1);
finalize('ok');
```

補足:

- `respond`、`redirect`、`finalize`、`finalize_json`、`render_and_print` 系の応答時に一緒に返されます

### `debug_run($code)`

コードリファレンスを実行し、通常の例外が発生した場合にエラーメッセージを HTML エスケープして表示します。

コントローラ専用です。

サンプル:

```perl
debug_run(sub {
    my $payload = param_json();
    finalize_json({ ok => 1, payload => $payload });
});
```

補足:

- `finalize` や `respond` などのレスポンス確定は PSGI レスポンス配列を `die` する仕組みなので、その場合は捕捉せずにそのまま返します
- エラー本文は `text/html; charset=UTF-8` で返します
- デバッグ用途の補助関数です。利用範囲は必要な診断処理に限定してください

## テンプレート専用ヘルパー

### `extends($template)`

テンプレートに親レイアウトを指定します。

サンプル:

```mt
? extends "base.mt";
```

### `block($name => $value_or_code)`

ブロックを定義または展開します。

子テンプレートで定義し、親テンプレートで展開する使い方が基本です。

子テンプレート側:

```mt
? extends "base.mt";
? block title => "一覧";
? block content => sub {
<p>本文です</p>
? }
```

親テンプレート側:

```mt
<title><? block title => "MENTA" ?></title>
<body><? block content => "" ?></body>
```

## 最小サンプル

### コントローラの最小例

```perl
use MENTA::Controller;

sub run {
    if (is_post_request()) {
        my $name = param('name');
        redirect(uri_for('hello', { name => $name }));
    } else {
        render_and_print('hello.mt');
    }
}
```

### テンプレートの最小例

```mt
? extends "base.mt";
? block title => "Hello";
? block content => sub {
<p>Hello <?= param('name') || 'guest' ?></p>
<p><a href="<?= uri_for('index') ?>">戻る</a></p>
? }
```

## 補足

`use MENTA::Controller;` を使ったコントローラに `AUTOLOAD` も注入されていますが、これは主にプラグイン自動ロードのための仕組みです。このドキュメントではプラグイン関数を対象外としているため、個別の関数一覧には含めていません。
