# GPIO ボタン制御

`pi_video_looper` には GPIO 制御機能が組み込まれています。ボタンを接続して、動画の再生制御を行えます。

## 概要

v1.0.14以降、pi_video_looperはGPIOピンを読み込んで、以下のアクションをトリガーできます：

- 特定のファイルを再生
- プレイリスト内をジャンプ
- キーボードコマンド送信（一時停止、シャットダウンなど）

## 設定方法

`/boot/video_looper.ini` の `[control]` セクションで `gpio_pin_map` を設定します。

### ピン番号について

ピン番号は **BOARD 番号（物理ピン番号）** で指定します（BCM番号ではありません）。詳細は[Raspberry Pi GPIO 公式ドキュメント](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#gpio)を参照。

### 配線方法

- GPIO ピンとグラウンドピン間にボタンを接続
- ボタンを押すとそのピンがGNDに接続される
- 複数ピンを同じGNDに接続可能

### ini 設定例

```ini
[control]
keyboard_control = true
gpio_pin_map = 
    "11" : 1
    "13" : "4"
    "16" : "+2"
    "18" : "-1"
    "19" : "K_SPACE"
    "21" : "K_p"
```

## アクション タイプ

### 1. ファイルインデックス指定

```ini
"11" : 1
```

- プレイリストの **2 番目のファイルを再生**（0ベース）
- **必ず整数（文字列でない）で指定**

### 2. ファイル名指定

```ini
"15" : "video.mp4"
```

- 名前が `video.mp4` のファイルを再生
- ファイル路径内に存在する必要あり
- `_repeat_Nx` は自動削除される

### 3. 相対ジャンプ

```ini
"16" : "+2"
"18" : "-1"
```

- `+2`: 2ファイル先へジャンプ
- `-1`: 1ファイル戻る

### 4. キーボードコマンド

```ini
"19" : "K_SPACE"
"21" : "K_p"
```

`keyboard_control = true` が必須です。

**利用可能なコマンド:**
- `K_SPACE`: 一時停止/再開（omxplayer, image_player）
- `K_k`: スキップ
- `K_b`: 前のファイル
- `K_s`: 停止/開始
- `K_p`: シャットダウン
- `K_o`: 次チャプター（omxplayer）
- `K_i`: 前チャプター（omxplayer）

詳細は [pygame key constants](https://www.pygame.org/docs/ref/key.html) を参照。

### 5. M3Uプレイリスト トリガー

v1.0.21以降、M3Uファイルをトリガー可能：

```ini
"11" : "playlist.m3u"
```

## 実装例

一般的な操作パターン：

```ini
[control]
keyboard_control = true
gpio_pin_map = 
    "11" : "K_SPACE"      # play/pause
    "13" : "K_k"          # skip
    "15" : "-1"           # previous
    "16" : "+1"           # next
    "21" : "K_p"          # shutdown
```

## 注意事項

### keyboard_control との関係

- GPIO で **キーボードコマンド**（`K_*` 形式）を使う場合、`keyboard_control = true` が必須
- `keyboard_control = false` 時は、キーボードコマンド、GPIO 両方が無視される
- **セキュリティ**: 不正な再生を防ぐため、本番環境では必要な GPIO ピンのみマップして、不要なコマンドは登録しない

### 再生画面中の無効化

`keyboard_control_disabled_while_playing = true` で、動画再生中にキーボード・GPIO入力を無効化可能

### v1.0.20 以降の機能

GPIO ピンの pull-up/pull-down 設定が可能：

```ini
[control]
gpio_pin_modes =
    "11" : "PUD_UP"
    "13" : "PUD_DOWN"
```

詳細は公式ドキュメントを参照。

## トラブルシューティング

**GPIO が反応しない場合:**

1. `console_output = true` でログを確認
2. `gpio_pin_map` の構文チェック（整数値は文字列でない）
3. ピン番号が BOARD 番号か確認（BCM 番号ではない）
4. グラウンド接続を確認
5. supervisor を再起動：

   ```bash
   sudo supervisorctl restart video_looper
   ```

**キーボードコマンドが動作しない場合:**

- `keyboard_control = true` が設定されているか確認
- `omxplayer` または `image_player` を使用しているか確認
  （`hello_video` はキーボード入力をサポートしない）

## 参考

- [pi_video_looper GitHub - GPIO Control](https://github.com/adafruit/pi_video_looper#gpio-control)
- [Raspberry Pi GPIO Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#gpio)
