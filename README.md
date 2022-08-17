# Tang_Nano_1k_RISC-V_Project


Tang Nano 1kで遊ぶRISC-V的なCPU
======================================

一応、[RISC-V](http://riscv.org/)の仕様に基づいて実装した、RISC-V32Eコアになります。

ただし、RISC-Vの互換チェックを行うプログラムでの試験は実施していないので、完全なRISC-V32E仕様の適合は、保証しません。

Tang Nano 1kに搭載するために、無駄な仕様の一部を削減しています。
- プログラムカウンタ　32bit　→　16bit
- J-immの有効長　21bit → 18bit
- FENCEはNOPとして実装

GW1NZ-LV1が持つBSRAMの４個の内、２ブロックは汎用レジスタ、一部のCSRレジスタとして使用しています。

残りの２ブロックがメインメモリになります。

メインメモリは、1kワード（4096Byte）しかないので、プログラムカウンタは10bitあれば、十分です。



Tang Nano と Tang Nano 1kの違い
------------------------
Tang NanoはGW1N-LV1というICを搭載いているのに対して、

Tang Nano 1kはGW1NZ-LV1というICを使っています。

また、各々の基板でピンアサインが異なるで、

本プロジェクトを、そのままTang Nanoに書き込んでも動作しません。



Gowin IDE
------------------------
Gowin_V1.9.8.07にてGW1NZ-LV1用のDual Port RAMのIP作成および論理合成。配置・配線。

Sipeedの[Programmer](https://dl.sipeed.com/shareURL/TANG/programmer)にて書き込み。



サンプルプログラム
------------------------
動作するプログラムはタイマ割込みにてLEDを点滅するプログラムです。

ボタンＡで発光する色の変更。ボタンＢはリセットです。



その他
------------------------
公式のテストプログラムでの動作確認はしてませんので、RISC-V32Eとして正常に動作する保証はありません。

本プロジェクトを使用する際は、自己責任でお願いします。

また、上記理由により、再配布、転載、商用利用は禁止とします。



以上
