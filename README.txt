・このコアについて

18erのCPU実験余興でOSを動かすために書かれたRISC-Vベースのコアです。
3班の1stコアをベースにATPがメインに書きました。
ベースのコアはmoratorium氏が書きました。
乗算器はdai氏が書きました。
fadd、fmul、fdivはinn氏が書いた組み合わせ回路をATPがステージ分けしました。



・命令
32bitのRISC-Vの基本命令セット、M拡張、レイトレを動かすために必要な浮動小数点数演算がサポートされています。
トラップやアドレス変換等を実現するために一部のCSRがサポートされています。
CPUのモードはU-modeとS-modeをサポートしています。本来トラップが発生するとM-modeに遷移するのですが、単純化するためにS-modeに遷移するようになっています。



・レジスタ
レジスタは基本的に32bit幅です。
汎用レジスタが32個、浮動小数点数レジスタが32個あります。汎用レジスタの0番は0レジスタです。
そのほかにSupervisorのみが読み書きできるCSRが存在します。
サポートされているCSRは以下のものです。
sstatus :
	SPP、SPIE、SIEフィールドを割込みネスト等に使います。
sie :
	SEIEはUARTの受信割込み許可、STIEをタイマー割込み許可に使っています。
stvec :
	Directモードのみサポートしています。トラップ時のジャンプアドレスを入れておきます。
sscratch :
	トラップ時の退避先アドレスを格納することを想定しています。
sepc :
	トラップが起きた時のプログラムカウンタの値が保存されます。
scause :
	トラップ時にトラップの原因が格納されます。現在サポートされている原因は次のものがあります。
	Instruction access fault
	Load access fault
	Store/AMO access fault
	Instruction page fault
	Load page fault
	Store/AMO page fault
	Illegal instruction
	Environment call from U-mode
	Environment call from S-mode
	その他例外(16番)
	Supervisor timer interrupt
	Supervisor external interrupt
	その他割込み(10番)
stval :
	ページフォルトのときそのアドレスが格納されます。それ以外のときは0が格納されます。
sip : 
	割込み要因発生時に対応するbitが立てられます。ソフトウェアがクリアするまで立てられたbitは1のままです。
satp :
	アドレス変換のモードとページディレクトリのアドレスを格納します。
本来これらのレジスタの読み書き可能なフィールドは一部ですが、簡単化のために全領域をS-modeで読み書きできます。



・メモリ
今回OSを積むにあたって大きいメモリが必要となりました。そこでMIGでラッパーされた2GBのSDRAMを使用しています。
問題となるのはメモリアクセスにかかる時間です。Block RAMには数クロックでアクセスできますがSDRAMにアクセスするには数十クロックかかります。
これを緩和するためにキャッシュを実装しました。キャッシュサイズは1MBでBlock RAMを用いて実装されています。アドレスタグ、dirty bit、valid bitは分散RAMに実装しています。



・MMU
アドレス変換を実現するためにMMUが実装されています。satpレジスタを参照してアドレス変換をします。
またUART、mtimeレジスタ、mtimecmpレジスタをメモリマップしています。
0x000000000～0x07fffffff : メモリ
0x800000000～0x80000ffff : UART
0x800001000～0x80001ffff : mtime、mtimecmp



