# jp-slot / tools

## generate_placeholders.sh

`html/assets/` に仮の PNG / WebM を生成します。**FFmpeg は必須**です。ラベル付き PNG には ImageMagick（`magick` または ImageMagick の `convert`）があると便利です。無い場合は単色 PNG になります。

### Windows（Git Bash）

事前に `ffmpeg` が PATH に入っていることを確認してください（例: `C:\ffmpeg\bin` をユーザー環境変数 PATH に追加）。

```bash
cd jp-slot/tools
chmod +x generate_placeholders.sh
./generate_placeholders.sh
```
