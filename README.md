# Raspberry Pi 2B + pi_video_looper (hello_video) 手順

Raspberry Pi 2Bで`pi_video_looper`を`hello_video`エンジンで動かすための手順です。`hello_video`はBroadcomのLegacyスタック前提のため、Raspberry Pi OS (Legacy) 32-bitを使用します。

## 前提

- 対象: Raspberry Pi 2B (armv7)
- OS: Raspberry Pi OS (Legacy) 32-bit (Buster系)
- 再生動画: H.264の.mp4推奨

## 1. OSイメージの取得

1. 公式サイトからRaspberry Pi OS (Legacy) 32-bit Liteをダウンロード
   - 例: 2022-01-28 (Buster) のLiteイメージ
   - wget例:

     ```bash
     wget -O 2022-01-28-raspios-buster-armhf-lite.zip \
       https://downloads.raspberrypi.com/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2022-01-28/2022-01-28-raspios-buster-armhf-lite.zip
     ```
2. Raspberry Pi ImagerまたはbalenaEtcherでSDカードへ書き込み

### 1-1. 初回起動前の準備 (任意)

SDカードの`boot`パーティションに以下を追加:

- SSH有効化: `ssh`という空ファイルを作成

## 2. 初回起動と基本設定

user: pi, password=raspberry

```bash
sudo raspi-config
```

- Locale/Timezone/Keyboardの設定
- パスワード変更
- SSHを有効化 (Interface Options)
- 再起動

## 3. Legacy aptリポジトリの確認

`/etc/apt/sources.list`に以下があるか確認 (Busterはレガシーのため`legacy.raspbian.org`を使用):

```
deb http://legacy.raspbian.org/raspbian/ buster main contrib non-free rpi
```

`/etc/apt/sources.list.d/raspi.list`に以下があるか確認:

```
deb http://archive.raspberrypi.org/debian/ buster main
```

無い場合は追加してから更新:

```bash
sudo apt update
```

改めてVNC有効化など

```bash
sudo raspi-config
```

## 4. 必要パッケージの導入

```bash
sudo apt install -y git python3 python3-pip omxplayer vim
```

## 5. pi_video_looperの導入

```bash
cd ~
git clone https://github.com/adafruit/pi_video_looper.git
cd pi_video_looper
sudo ./install.sh
```

`hello_video`を使うため、`no_hello_video`オプションは付けません。

`hello_video`が見つからない場合は、以下で再ビルドし、コピーします:

```bash
cd /opt/vc/src/hello_pi
sudo ./rebuild.sh
cd hello_video
sudo make
sudo cp hello_video.bin /usr/local/bin/
sudo chmod +x /usr/local/bin/hello_video.bin
```

## 6. hello_videoエンジンの設定

設定ファイルを作成してエンジンを`hello_video`に変更:

```bash
sudo cp ./assets/video_looper.ini /boot/video_looper.ini
sudo vim /boot/video_looper.ini
```

`/boot/video_looper.ini`:

```
[video_looper]
video_player = hello_video
is_random = true
#is_random_unique = true
```

## 7. 動画配置方法の選択

2つの方法があります：

### 7-1. ローカルディレクトリから再生 (directoryモード)

SD内の固定パスから再生する場合:

```bash
mkdir -p /home/pi/video
```

`/boot/video_looper.ini`で以下を指定:

```ini
[video_looper]
file_reader = directory

[directory]
path = /home/pi/video
```

動画を`/home/pi/video`に配置して再生します。

### 7-2. USBフラッシュメモリから再生 (usb_driveモード・推奨)

`pi_video_looper`の`usb_drive`モードを使うと、USBを挿した時に`/mnt/usbdrive0`や`/mnt/usbdrive1`のように自動マウントされます。
ラベル指定は不要で、複数のUSBでも動作します。
この自動マウントは`pi_video_looper`側の仕組みなので、OS側に追加のマウント設定は不要です。

1. `/boot/video_looper.ini`で`usb_drive`を指定:

```
[video_looper]
file_reader = usb_drive
```

2. 既定のマウント先(`/mnt/usbdrive`)を使う場合はそのままでOKです。
複数挿すと`/mnt/usbdrive0`, `/mnt/usbdrive1`が順に作成されます。

USBは **デフォルトで読み取り専用** でマウントされます（信頼性のため推奨）。  
書き込み可能にしたい場合や、マウント先を変更したい場合は `/boot/video_looper.ini` で調整できます:

```ini
[usb_drive]
mount_path = /mnt/usbdrive
readonly = true
```

## 8. 動作確認

`./install.sh`を実行すると、supervisorでサービスとして自動起動するように設定されます。
再起動後、自動的に動画再生が始まります。

手動で起動する場合:

```bash
sudo python3 -m Adafruit_Video_Looper.video_looper
```

またはsupervisorを通じて:

```bash
sudo supervisorctl restart video_looper
```

ログの確認:

```bash
sudo tail -f /var/log/supervisor/video_looper-stdout*
```

## 9. 自動起動の制御

`./install.sh`でsupervisorによる自動起動が設定済みです。

自動起動を無効化する場合:

```bash
sudo supervisorctl stop video_looper
sudo systemctl disable supervisor
```

再度有効化する場合:

```bash
sudo systemctl enable supervisor
sudo systemctl start supervisor
```

サービスの状態確認:

```bash
sudo supervisorctl status video_looper
```

## 10. イメージの作成と複製

動作確認済みのRaspberry PiからSDカードイメージを作成すれば、他のSDカードに複製して即座にセットアップ完了状態で使えます。

### 10-1. イメージの作成 (macOS/Linux)

1. Raspberry Piをシャットダウン:

```bash
sudo shutdown -h now
```

2. SDカードをPCに挿入し、デバイス名を確認:

**macOS:**
```bash
diskutil list
```

**Linux:**
```bash
lsblk
```

デバイス名の例: `/dev/disk2` (macOS) / `/dev/sdb` (Linux)

3. イメージを作成:

**macOS:**
```bash
sudo dd if=/dev/disk2 of="$HOME/pi-videolooper-image.img" bs=1m
```

**Linux:**
```bash
sudo dd if=/dev/sdb of="$HOME/pi-videolooper-image.img" bs=1M status=progress
```

**注意:** `dd`は空き領域を含めてディスク全体サイズ分コピーします。

4. 圧縮して保存:

```bash
gzip "$HOME/pi-videolooper-image.img"
```

作成される `pi-videolooper-image.img.gz` を保管します。

### 10-2. イメージからの複製

1. 圧縮イメージを解凍（balenaEtcherなら不要）:

```bash
gunzip pi-videolooper-image.img.gz
```

2. balenaEtcherまたはRaspberry Pi Imagerで新しいSDカードに書き込み

3. SDカードをRaspberry Piに挿入して起動すれば、セットアップ済み状態で動作します

**注意:** 複製したイメージのホスト名やSSH鍵は元のものと同じなので、必要に応じて`raspi-config`で変更してください。

## 11. mp4をhello_video用のh264 (Annex B) に変換

`hello_video`はAnnex B形式のH.264ストリームが必要です。
既にH.264エンコード済みの.mp4を、音声を除外して`.h264`に変換します。

入力ディレクトリ配下の`.mp4`を再帰的に処理し、出力先はフラットに保存します:

```bash
SRC=/path/to/mp4; DIR=/path/to/out; find "$SRC" -type f -name '*.mp4' -exec sh -c 'ffmpeg -hide_banner -loglevel error -y -i "$1" -c:v copy -an -bsf:v h264_mp4toannexb "$2/$(basename "${1%.*}").h264"' _ {} "$DIR" \;
```

同名ファイルがあると上書きされるため、上書きしたくない場合は`-y`を`-n`に変更してください。
