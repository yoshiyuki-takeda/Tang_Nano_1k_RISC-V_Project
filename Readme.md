# [Tang Nano 1k](https://ja.aliexpress.com/item/1005002551785169.html?channel=twinner)(FPGA:GW1NZ-LV1 QN48C6/I5)用のRISC-Vプロジェクト

[RISC-V](http://riscv.org/)の仕様に基づいて実装した、RISC-V32Iコアです。  
GW1NZ-LV1へRV32Iを搭載するために、実用上問題ない範囲で仕様から一部を変更してます。
- プログラムカウンタ　32bit　→　16bit
- J-immの有効長　21bit → 18bit
- FENCEはNOPとして実装
- リソースが少ないので、シフトは、１ビットシフトを回数分実行（遅い）

FPGAの使用リソース
------------------------
４入力LUT：1012/1152  
FF：116/957  
BlockRAM：4/4（2個：汎用レジスタ、2個：メインメモリ(4096バイト)）


プロジェクトのコンパイル
------------------------
論理合成。配置・配線ツール：[Gowin_V1.9.8.07](http://www.gowinsemi.com.cn/solution_view.aspx?FId=n25:25:25&Id=563)(ページの下の方)  
FPGAへの書き込みツール：[Programmer](https://dl.sipeed.com/shareURL/TANG/Nano/IDE)  
Gowin標準のProgrammerではデバイスを認識しません。


サンプルプログラム(mem.hex)
------------------------
動作するプログラムはタイマ割込みにてLEDを点滅するプログラムです。  
ボタンＡで発光する色の変更。ボタンＢはリセットです。


ライセンス
------------------------
BSDライセンス  
本プロジェクトを使用する際は、自己責任でお願いします。

その他
------------------------
[riscv-tests](https://github.com/riscv-software-src/riscv-tests)のrv32uiのテストは通ってます。  
FENCEはNOPでもパスしてくれるみたい。


以上
