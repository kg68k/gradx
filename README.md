# GRADX
GORRYさんの作成された
[RAM DISK DRIVER 「ＧＲＡＤ．ｒ」](https://gorry.haun.org/x68index.html#ARC_X68_GRAD)
の改造版です。

無保証につき各自の責任で使用して下さい。


## Build
PCやネット上での取り扱いを用意にするために、src/内のファイルはUTF-8で記述されています。
X68000上でビルドする際には、UTF-8からShift_JISへの変換が必要です。

### u8tosjを使用する方法

あらかじめ、[u8tosj](https://github.com/kg68k/u8tosj)をビルドしてインストールしておいてください。

トップディレクトリで`make`を実行してください。以下の処理が行われます。
1. build/ディレクトリの作成。
2. src/内の各ファイルをShift_JISに変換してbuild/へ保存。

次に、カレントディレクトリをbuild/に変更し、`make`を実行してください。
実行ファイルが作成されます。

### u8tosjを使用しない方法

ファイルを適当なツールで適宜Shift_JISに変換してから`make`を実行してください。
UTF-8のままでは正しくビルドできませんので注意してください。


## License
[GRAD130.LZH](archives/GRAD130.LZH)内の「使用許諾規定.doc」ファイルを参照してください。


## Author
TcbnErik / 立花@桑島技研  
https://github.com/kg68k/gradx
