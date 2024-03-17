*	RAM DISK DRIVER
*	90/08/30 Programmed by GORRY.
*	2024-03-18  modified by TcbnErik

	.cpu	68000
	.include	doscall.mac
	.include	iocscall.mac



bcl	macro	n1
	beq	n1
	endm

bst	macro	n1
	bne	n1
	endm

__HUMANV2__


＿media_change_flag		equ	media_change_flag-PSTART
＿VERIFY_MODE			equ	VERIFY_MODE-PSTART
＿RAM_MEMORY_MODE		equ	RAM_MEMORY_MODE-PSTART
＿max_sector_no			equ	max_sector_no-PSTART
＿max_capacity			equ	max_capacity-PSTART
＿GRAM_MEMORY_MODE		equ	GRAM_MEMORY_MODE-PSTART
＿dirtime			equ	dirtime-PSTART
＿dirdate			equ	dirdate-PSTART
＿DPB_TABLE			equ	DPB_TABLE-PSTART
＿SYS_MODE			equ	SYS_MODE-PSTART
＿RAM_SIZE			equ	RAM_SIZE-PSTART
＿DRIVE_INFORMATION_TABLE	equ	DRIVE_INFORMATION_TABLE-PSTART
＿WriteEnableSw			equ	WriteEnableSw-PSTART
＿AccessLampSw			equ	AccessLampSw-PSTART
＿RAM_START			equ	RAM_START-PSTART
＿CONTROL_MAIN_HOOK		equ	CONTROL_MAIN_HOOK-PSTART



＠＠command_code	equ	2
＠＠errorcode_lo	equ	3
＠＠errorcode_hi	equ	4
＠＠exchange_flag	equ	14
＠＠drive_condition	equ	13
＠＠access_address	equ	14
＠＠start_sector_no	equ	22
＠＠access_length	equ	18


＃sector_len	equ	1024


Ｈmemory_end		equ	$1c00
Ｈdrive_info_ptr	equ	$1c38
Ｈdrive_assign_table	equ	$1c7e
Ｈnum_of_drive		equ	$1c75

SizeOfAssignInfo	=	130

ESC:		equ	$1b


PSTART::
		jmp	EXEC_START(pc)
CONTROL_MAIN_HOOK::
		jmp	CONTROL_MAIN(pc)


DEVICE_HEADER::
		dc.l	-1		*次のデバイスドライバへのリンクポインタ
		dc.w	0		*デバイスの属性
		dc.l	0		*strategy	*ストラテジルーチン
		dc.l	0		*interrupt	*割り込みルーチン
		dc.b	1,'_GRAD__'	*デバイス名
VERSION::				*ここからはデバイスヘッダではない
		dc.l	'1.29'
Reserved
		ds.l	1

*	*	*

DPB_TABLE::
		dc.b	0		*00.b	登録時のドライブ番号
		dc.b	0		*01.b	ユニット番号
		dc.l	0		*DEVICE_HEADER	*02.l	デバイスドライバのエントリアドレス
		dc.l	-1		*06.l	次のＤＰＢへのリンクポインタ（－１で終了）
		dc.w	＃sector_len	*0a.w	１セクタ当たりのバイト数（１０２４で固定）
		dc.b	1-1		*0c.b	１クラスタ当たりのセクタ数－１（０で固定）
		dc.b	0		*0d.b	先頭クラスタのセクタ番号
		dc.w	0		*0e.w	ＦＡＴ領域のセクタ番号
		dc.b	1		*10.b	ＦＡＴ領域の個数
		dc.b	6		*11.b	ＦＡＴに使用するセクタ数
		dc.w	96		*12.w	ルートディレクトリに作成できるファイル数
		dc.w	9		*14.w	データ領域の先頭セクタ番号
		dc.w	256-9+3		*16.w	全ディスク容量＋３
		dc.w	6		*18.w	ルートディレクトリ領域の先頭セクタ番号
		dc.b	$f9		*1a.b	メディアバイト
		dc.b	$0a		*1b.b	不明（$0aで固定）
		dc.w	$0002		*1c.w	不明（$0002で固定）

*BPB_TABLE
*		dc.w	＃sector_len	*１セクタ当たりのバイト数
*		dc.b	1		*１クラスタ当たりのセクタ数
*		dc.b	1		*ＦＡＴ領域の個数
*		dc.w	0		*予約領域のセクタ数
*		dc.w	92		*ルートディレクトリに入るエントリ数
*		dc.w	512		*全領域のセクタ数
*		dc.b	$f9		*メディアバイト
*		dc.b	6		*１個のＦＡＴ領域に使用するセクタ数

DRIVE_INFORMATION_TABLE::
		dc.b	"A:",9
		dcb.b	69-3,0
		dc.b	$40
		dc.l	0		*DPB_TABLE
		dc.w	$ffff
		dc.w	2

*	*	*

RAMDISK_MEMORY_TABLE::
		dc.l	$c00000		*G-RAM
		dc.w	512		*セクタ数
		dc.w	0		*メモリモード（上位バイトが０で小方向、１で大方向から。下位バイトはドライブタイプ）
		dc.l	0
		dc.w	0
		dc.w	0
max_sector_no::	dc.w	512		*最大セクタ番号＋１
media_change_flag::
		dc.w	$0100		*実際はバイトアクセス
max_capacity::	dc.w	512		*最大セクタ番号＋１

*	*	*

request_header::
		dc.l	0
jump_table::
dev_jpt	macro	l1
	dc.w	l1-jump_table
	endm
		dev_jpt	not_command	*initialize	*0 イニシャライズ　ここには飛ばないはず。
		dev_jpt	media_change	*1 ディスク交換チェック
		dev_jpt	not_command	*2 
		dev_jpt	not_command	*3 
		dev_jpt	disk_read	*4 ディスク読み込み
		dev_jpt	disk_control	*5 ドライブコントロール＆センス
		dev_jpt	not_command	*6 
		dev_jpt	not_command	*7 
		dev_jpt	disk_write	*8 ディスク書き込み
		dev_jpt	disk_write_v	*9 ディスク書き込み（ベリファイつき）
		dev_jpt	not_command	*10 
		dev_jpt	not_command	*11
		dev_jpt	not_command	*12

*	*	*	*	*	*	*	*	*

strategy::		*ストラテジルーチン
		move.l	a0,-(sp)
		lea	request_header(pc),a0
		move.l	a5,(a0)
		move.l	(sp)+,a0
ret::
		rts

*	*	*	*	*	*	*	*	*

interrupt::		*割り込みルーチン
		movem.l	a4-a6,-(sp)
		lea	PSTART(pc),a6
		movea.l	request_header(pc),a5
		lea	jump_table(pc),a4

		moveq.l	#0,d0
		move.b	＠＠command_code(a5),d0
		add.w	d0,d0
		move.w	(a4,d0.w),d0
		jsr	(a4,d0.w)

		move.b	d0,＠＠errorcode_lo(a5)
		move.w	d0,-(sp)
		move.b	(sp)+,＠＠errorcode_hi(a5)
		movem.l	(sp)+,a4-a6
		rts

*	*	*	*	*	*	*	*	*

not_command::		*コマンドコードが異常
		move.w	#$5003,d0		*コマンドコードが不正です。
		move.b	#$03,＠＠errorcode_lo(a5)
		move.b	#$50,＠＠errorcode_lo(a5)
		rts

*	*	*	*	*	*	*	*	*

media_change::		*ディスクが交換されたかどうかをチェック
		move.b	media_change_flag(pc),＠＠exchange_flag(a5)
		move.b	#1,＿media_change_flag(a6)
		moveq.l	#0,d0
		rts

*	*	*	*	*	*	*	*	*

disk_read::		*ディスクから読み込む
		movem.l	d1-d7/a0-a4,-(sp)
		bsr	TurnAccessLamp
		lea	read_sub(pc),a0
		bsr	disk_access_r
		bsr	TurnAccessLamp
		movem.l	(sp)+,d1-d7/a0-a4
		rts

*	*	*	*	*	*	*	*	*

disk_write::		*ディスクへ書き込む
		tst.w	＿WriteEnableSw(a6)
		bcl	disk_write_protected
		movem.l	d1-d7/a0-a4,-(sp)
		bsr	TurnAccessLamp
		lea	write_sub(pc),a0
		bsr	disk_access_w
		bsr	TurnAccessLamp
		movem.l	(sp)+,d1-d7/a0-a4
		rts

*	*	*	*	*	*	*	*	*

disk_write_protected::		*プロテクトONのときに書き込みを行なった
		move.w	#$700e,d0
		rts

*	*	*	*	*	*	*	*	*

disk_write_v::		*ディスクへ書き込む（ベリファイつき）
		tst.w	＿WriteEnableSw(a6)
		bcl	disk_write_protected
		movem.l	d1-d7/a0-a4,-(sp)
		bsr	TurnAccessLamp
		lea	write_sub(pc),a0
		bsr	disk_access_w
		tst.w	d0
		@ifeq	{
			tst.w	＿VERIFY_MODE(a6)
			bne	>
			lea	verify_sub(pc),a0
			bsr	disk_access_w
		}
		bsr	TurnAccessLamp
		movem.l	(sp)+,d1-d7/a0-a4
		rts

*	*	*	*	*	*	*	*	*

disk_control::		*ディスクコントロールを行う
		movem.l	d1/a0,-(sp)
		moveq.l	#$42,d0			*eject禁止、メディア挿入されている
		movea.l	FAT_ADDRESS(pc),a0
		move.l	(a0),d1
		rol.l	#8,d1
		andi.w	#$ff,d1
		move.l	d1,-(sp)
		move.b	$1a+DPB_TABLE(pc),d1
		cmp.b	#$f9,d1
		movem.l	(sp)+,d1
		@ifne	{
			move.b	#$F9,d1
		}
		ror.l	#8,d1
		cmpi.l	#$F9FFFF00,d1		*FATが正常か？
		@ifne	{
			moveq.l	#$46,d0			*上＋Not ready
		}
		tst.w	＿WriteEnableSw(a6)
		@ifcl	{
			bset	#3,d0
		}
		move.b	d0,＠＠drive_condition(a5)
		moveq.l	#0,d0
		movem.l	(sp)+,d1/a0
		rts

*	*	*	*	*	*	*	*	*

TurnAccessLamp::
*		アクセスランプを反転する。
*		in	なし
*		out	なし

		tst.w	＿AccessLampSw(a6)
		@ifcl	{
			bset	#0,$e8a01b
			eori.b	#%0000_0111,($e8a001)
		}

		rts

*	*	*	*	*	*	*	*	*

disk_access_r::		*ディスクアクセス　読み込み用エントリ
		movea.l	FAT_ADDRESS(pc),a1
		move.l	(a1),d0
		rol.l	#8,d0
		andi.w	#$ff,d0
		move.l	d0,-(sp)
		move.b	$1a+DPB_TABLE(pc),d0
		cmp.b	#$f9,d0
		movem.l	(sp)+,d0
		@ifne	{
			move.b	#$F9,d0
		}
		ror.l	#8,d0
		cmpi.l	#$F9FFFF00,d0		*FATが正常か？
		bne	bad_drive
disk_access_w::		*ディスクアクセス　書き込み用エントリ
		movea.l	＠＠access_address(a5),a1
		lea	RAMDISK_MEMORY_TABLE(pc),a2
		moveq.l	#0,d0
		moveq.l	#0,d1
		move.w	＠＠start_sector_no+2(a5),d0
		add.w	＠＠access_length+2(a5),d0
		cmp.w	max_sector_no(pc),d0
		bhi	bad_sector
		move.w	＠＠start_sector_no+2(a5),d0
		cmp.w	4(a2),d0
		bcc	disk_access_1			*スタートセクタが第２領域
		add.w	＠＠access_length+2(a5),d0
		cmp.w	4(a2),d0
		bhi	disk_access_2			*エンドセクタが第２領域

		move.l	＠＠access_length(a5),d0
		move.l	＠＠start_sector_no(a5),d1
disk_access_::
		subq.w	#1,d0				*DBRAでできるようにしておく
		clr.w	d2
		tst.b	6(a2)				*メモリモード
		@ifst	{
			move.w	$0a+DPB_TABLE(pc),d2
			add.w	d2,d2
		}
		moveq.l	#0,d3

		movea.l	(a2),a2				*領域のスタートアドレス
		mulu	$0a+DPB_TABLE(pc),d1
		tst.w	d2
		@ifeq	{
			adda.l	d1,a2
		}else
		{
			suba.l	d1,a2
		}

		move.l	a1,d1
		move.l	a2,-(sp)
		or.l	(sp)+,d1
		andi.w	#1,d1				*どちらかのアドレスが奇数から始まると立つ
		jmp	(a0)

disk_access_2::		*セクタが２領域をまたがっている
		moveq.l	#0,d0
		move.w	4(a2),d0			*第１領域の大きさ
		move.l	＠＠start_sector_no(a5),d1
		sub.w	d1,d0				*第１領域のアクセス分
		movem.l	d0/a0/a2,-(sp)
		bsr	disk_access_
		movem.l	(sp)+,d1/a0/a2
		move.l	＠＠access_length(a5),d0
		sub.w	d1,d0				*第２領域のアクセス分
		moveq.l	#0,d1				*スタートセクタ＝０
		lea	8(a2),a2			*第２領域
		bra	disk_access_

disk_access_1::		*スタートセクタが第２領域
		move.l	＠＠access_length(a5),d0
		move.l	＠＠start_sector_no(a5),d1
		sub.w	4(a2),d1			*第１領域の大きさ
		lea	8(a2),a2			*第２領域
		bra	disk_access_


bad_drive::		*ドライブが異常
		move.w	#$5007,d0			*無効なメディア
		rts
bad_sector::		*レコード番号が異常
		move.w	#$5008,d0			*セクタが見つかりません
		rts

*	*	*	*
read_sub::		*ディスクアクセス　読み込み
rw_sub::
		tst.w	d1
		@ifeq	{

memory_move_1	macro	adr	*３２バイト移動
		movem.l	(a2)+,d4-d7/a0/a3-a4/a6
		movem.l	d4-d7/a0/a3-a4/a6,(adr*32)(a1)
		endm
			move.l	a6,-(sp)
			{
				movem.l	(a2)+,d4-d7/a0/a3-a4/a6
				movem.l	d4-d7/a0/a3-a4/a6,(a1)
				memory_move_1	1
				memory_move_1	2
				memory_move_1	3
				memory_move_1	4
				memory_move_1	5
				memory_move_1	6
				memory_move_1	7
				memory_move_1	8
				memory_move_1	9
				memory_move_1	10
				memory_move_1	11
				memory_move_1	12
				memory_move_1	13
				memory_move_1	14
				memory_move_1	15
				memory_move_1	16
				memory_move_1	17
				memory_move_1	18
				memory_move_1	19
				memory_move_1	20
				memory_move_1	21
				memory_move_1	22
				memory_move_1	23
				memory_move_1	24
				memory_move_1	25
				memory_move_1	26
				memory_move_1	27
				memory_move_1	28
				memory_move_1	29
				memory_move_1	30
*	*	*	*	memory_move_1	31
				movem.l	(a2)+,d4-d7/a0/a3-a4		*こーしないと$C7FFE0から
				movem.l	d4-d7/a0/a3-a4,31*32(a1)	*アクセスした時に飛んでしまう
				move.l	(a2),32*32-4(a1)
				addq.w	#4,a2
				lea	1024(a1),a1

				suba.w	d2,a2				
				suba.w	d3,a1

				dbra	d0,<
			}
			movea.l	(sp)+,a6
		}else
		{

memory_move_2	macro	adr	*８バイト移動
		movep.l	adr+0(a2),d4
		movep.l	d4,adr+0(a1)
		movep.l	adr+1(a2),d4
		movep.l	d4,adr+1(a1)
		endm

			moveq.l	#$40,d5
			{
				moveq.l	#16-1,d1
				{
					memory_move_2	$00
					memory_move_2	$08
					memory_move_2	$10
					memory_move_2	$18
					memory_move_2	$20
					memory_move_2	$28
					memory_move_2	$30
					memory_move_2	$38

					adda.w	d5,a1
					adda.w	d5,a2
					dbra	d1,<
				}
				suba.w	d2,a2				
				suba.w	d3,a1

				dbra	d0,<
			}
		}

		moveq.l	#0,d0
		rts

*	*	*	*
write_sub::		*ディスクアクセス　書き込み
		exg.l	a1,a2		*ソースとディスティネーションを入れ替える
		exg.l	d2,d3
		bsr	rw_sub
		exg.l	a1,a2		*ソースとディスティネーションを入れ替える
		rts

*	*	*	*
verify_sub::		*ディスクアクセス　ベリファイ

		tst.w	d1
		@ifeq	{

memory_cmp_1	macro
		cmpm.l	(a2)+,(a1)+
		bne	verify_sub_err
		endm

			{
				moveq.l	#16-1,d1
				{
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1	*
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
					memory_cmp_1
*					memory_cmp_1	*
					move.l	(a2),d4
					cmp.l	(a1),d4
					bne	verify_sub_err
					addq.w	#4,a1	*これもこーしないと$C7FFFCから
					addq.w	#4,a2	*アクセスした時に飛んでしまう

					dbra	d1,<
				}
				suba.w	d2,a2
				suba.w	d3,a1

				dbra	d0,<
			}
		}else
		{

memory_cmp_2	macro	adr
		movep.l	adr+0(a1),d4
		movep.l	adr+0(a2),d5
		cmp.l	d4,d5
		bne	verify_sub_err
		endm
			{
				moveq.l	#16-1,d1
				{
					memory_cmp_2	$00
					memory_cmp_2	$01
					memory_cmp_2	$08
					memory_cmp_2	$09
					memory_cmp_2	$10
					memory_cmp_2	$11
					memory_cmp_2	$18
					memory_cmp_2	$19
					memory_cmp_2	$20
					memory_cmp_2	$21
					memory_cmp_2	$28
					memory_cmp_2	$29
					memory_cmp_2	$30
					memory_cmp_2	$31
					memory_cmp_2	$38
					memory_cmp_2	$39
					lea	$40(a1),a1
					lea	$40(a2),a2

					dbra	d1,<
					}
				suba.w	d2,a2
				suba.w	d3,a1

				dbra	d0,<
			}
		}
		moveq.l	#0,d0
		rts

verify_sub_err::
		move.w	#$700b,d0		*読み込みエラー
		rts

*	*	*	*	*	*	*	*	*
RAM_START::
		dc.l	0	* +0	*ＲＡＭＤＩＳＫに使用するメモリのスタート番地
					*（小方向から見て）
RAM_SIZE::
		dc.l	0	* +4	*ＲＡＭＤＩＳＫに使用するメモリサイズ
RAM_MEMORY_MODE::
		dc.w	$ffff	* +8	*０でアドレス小方向から、１で大方向から
FAT_ADDRESS::
		dc.l	0	* +10	*ＦＡＴ領域の存在するアドレス
RAM_ACCESS_START::
		dc.l	0	* +14	*ＲＡＭＤＩＳＫに使用するメモリのスタート番地
					*（各方向から見て）
GRAM_MEMORY_MODE::
		dc.w	0	* +18	*１でＧ－ＲＡＭ使用
VERIFY_MODE::
		dc.w	1	* +20	*０でベリファイする
SYS_MODE::
		dc.w	0	* +22	*１でCONFIG.SYSからの起動（外せなくなる）
WriteEnableSw::
		dc.w	1	* +24	*０で書き込み不可、１で可能
AccessLampSw::
		dc.w	1	* +26	*０でアクセスランプ使用、１で無使用

		ds.b	4	* +28	*予約


RAMDISK_MANAGE::	*メモリの確保・変更を行う
*		in	d1.w	容量・セクタ数で指定（マイナスでドライバ解除）
*				Ｇ－ＲＡＭ分は含まない
*			d2.w	メモリモードスイッチ（０でアドレス小方向、１で大方向から）
*			d3.w	Ｇ－ＲＡＭ使用スイッチ（１で使用）
*			d4.w	ベリファイスイッチ（０で無視、１でする、２でしない）
*			d5.w	容量指定形スイッチ（０で絶対、１で＋ｎ、－１で－ｎ）
*			d6.w	プロテクトスイッチ（０で無視、１でする、２でしない）
*		out	d0.l	エラーコード（マイナスでエラー）
*				1	メモリを新規に確保
*				2	メモリを変更
*				3	メモリを解放

		move.b	#-1,＿media_change_flag(a5)
		tst.w	d1
		bmi	MEMORY_REMOVE

		lea	RAM_START(pc),a0

		subq.b	#1,d4
		@ifpl	{
			move.w	d4,20(a0)		*VERIFY_MODE
		}
		subq.b	#1,d6
		@ifpl	{
			move.w	d6,24(a0)		*WriteEnableSw
		}

		tst.w	8(a0)			*RAM_MEMORY_MODE
		bmi	RAMDISK_MANAGE_NEW
		cmp.w	18(a0),d3		*GRAM_MEMORY_MODE
		bne	RAMDISK_MANAGE_ERR1	*ＲＡＭＤＩＳＫの管理方法が異なる

		bsr	USED_FAT_CHECK
		cmp.w	d0,d1
		bcs	RAMDISK_MANAGE_ERR6	*最大セクタ番号を超えるファイルができる

		mulu	#1024,d1

		tst.b	8(a0)			*RAM_MEMORY_MODE
		@ifeq	{
			move.l	d1,-(sp)
			move.l	(a0),-(sp)
			moveq.l	#0,d7			*Human68k V2.01 BUG.
			dc.w	_SETBLOCK
			addq.w	#8,sp
			tst.l	d0
			bmi	RAMDISK_MANAGE_ERR3	*メモリが足りない

			cmp.l	RAM_SIZE(pc),d1
			@ifgt	{
				pea	1024*64				* 64KB空きメモリを残しておく
				move.w	#1,-(sp)
				dc.w	_MALLOC2
				addq.w	#6,sp
				tst.l	d0
				@ifmi	{				* 残らない
					move.l	RAM_SIZE(pc),-(sp)	* 容量を元に戻す
					move.l	(a0),-(sp)
					moveq.l	#0,d7			*Human68k V2.01 BUG.
					dc.w	_SETBLOCK
					addq.w	#8,sp
					bra	RAMDISK_MANAGE_ERR3	*メモリが足りない
				}
				move.l	a0,-(sp)
				lea	MemSafeBufPtr(pc),a0
				move.l	d0,(a0)
				move.l	(sp)+,a0
			}
			moveq.l	#2,d0			*領域変更
		}else
		{
			move.l	(Ｈmemory_end),a1
			move.l	a1,d0
			cmp.l	(a0),d0			*RAM_START
			bne	RAMDISK_MANAGE_ERR2	*メモリの中間位置にあるため変更できない

			move.l	d1,d0
			sub.l	RAM_SIZE(pc),d0
			@ifgt	{
				move.l	d1,-(sp)
				move.l	d0,d1
				bsr	RAMDISK_MANAGE_NEW_sub1	* 広げる
				move.l	(sp)+,d1
				tst.l	d0
				bne	RAMDISK_MANAGE_ERR3_	* メモリが取れない
			}
			move.l	14(a0),d0		*RAM_ACCESS_START
			sub.l	d1,d0
			move.l	d0,(Ｈmemory_end)
			move.l	d0,(a0)			*RAM_START

			moveq.l	#2,d0			*領域変更
		}
		move.l	d1,4(a0)		*RAM_SIZE
		rts

*RAMDISK_MANAGE_NEWは非常駐部分に置く。

RAMDISK_MANAGE_NEW_sub1::	*後ろからメモリが取れるかどうか調べる
		*out	d0=status	0	取れた
		*			負	メモリが足りない
		*			正	_MALLOC2に邪魔されている

		move.l	d2,-(sp)

		movem.l	a0-a1,-(sp)		*malloc2ヘッダで消される分のバックアップを取る
		suba.l	d1,a1
		move.l	a1,d2
		lea	malloc_back(pc),a0
		move.l	-(a1),(a0)+
		move.l	-(a1),(a0)+
		move.l	-(a1),(a0)+
		move.l	-(a1),(a0)+
		movem.l	(sp)+,a0-a1

		move.l	d1,-(sp)
		move.w	#2,-(sp)
		dc.w	_MALLOC2
		addq.w	#6,sp

		tst.l	d0
		@ifpl	{			*メモリは取れた
			cmp.l	d0,d2
			@ifne	{		* MALLOC2でメモリを確保している常駐プロセスがあると同じ値にならない
				moveq.l	#1,d2
			} else
			{
				moveq.l	#0,d2
			}
			move.l	d0,-(sp)
			dc.w	_MFREE			*ので戻す。
			addq.w	#4,sp

			movem.l	a0-a1,-(sp)		*バックアップを元に戻す
			suba.l	d1,a1
			lea	malloc_back(pc),a0
			move.l	(a0)+,-(a1)
			move.l	(a0)+,-(a1)
			move.l	(a0)+,-(a1)
			move.l	(a0)+,-(a1)
			movem.l	(sp)+,a0-a1

			move.l	d2,d0
		}

		move.l	(sp)+,d2
		rts


MEMORY_REMOVE::		*メモリーを解放する
		lea	RAM_START(pc),a0
		tst.w	8(a0)			*RAM_MEMORY_MODE
		bmi	RAMDISK_MANAGE_ERR4	*常駐していない

		tst.w	18(a0)			*GRAM_MEMORY_MODE
		@ifne	{
			moveq.l	#0,d1
			moveq.l	#0,d2
			moveq.l	#_TGUSEMD,d0
			trap	#15			*未使用にする
		}

		tst.b	8(a0)			*RAM_MEMORY_MODE
		@ifeq	{
			move.l	(a0),-(sp)		*RAM_START
			dc.w	_MFREE
			addq.w	#4,sp
		}else
		{
			move.l	(Ｈmemory_end),d0

			cmp.l	(a0),d0			*RAM_START
			bne	RAMDISK_MANAGE_ERR2

			add.l	4(a0),d0		*RAM_SIZE
			move.l	d0,(Ｈmemory_end)

			moveq.l	#0,d0
		}
		rts


RAMDISK_MANAGE_ERR1::	*ＲＡＭＤＩＳＫの管理方法が異なる
		moveq.l	#1,d7
		moveq.l	#-1,d0
		rts
RAMDISK_MANAGE_ERR2::	*メモリの中間位置にあるため変更できない
		moveq.l	#2,d7
		moveq.l	#-1,d0
		rts
RAMDISK_MANAGE_ERR3_::	*MALLOC2しているプロセスがある
		tst.l	d0
		bmi	RAMDISK_MANAGE_ERR3
		moveq.l	#30,d7
		moveq.l	#-1,d0
		rts
RAMDISK_MANAGE_ERR3::	*メモリが足りない
		moveq.l	#3,d7
		moveq.l	#-1,d0
		rts
RAMDISK_MANAGE_ERR4::	*常駐していない
		moveq.l	#4,d7
		moveq.l	#-1,d0
		rts
RAMDISK_MANAGE_ERR5::	*システム／アプリケーション、他のＧＲＡＤでＧ－ＲＡＭが使用されている。
		moveq.l	#16-1,d7
		add.l	d0,d7
		moveq.l	#-1,d0
		rts
RAMDISK_MANAGE_ERR6::	*最大セクタ番号を超えるＦＡＴができる1
		moveq.l	#19,d7
		moveq.l	#-1,d0
		rts
RAMDISK_MANAGE_ERR7::	*容量が大きすぎる
		moveq.l	#19,d7
		moveq.l	#-1,d0
		rts
RAMDISK_MANAGE_ERR8::	*容量が小さすぎる
		moveq.l	#19,d7
		moveq.l	#-1,d0
		rts

*	*	*	*	*	*	*	*	*
RAMDISK_MEMORY_SET::	*RAMDISK_MEMORY_TABLEその他ワークエリアへのセットを行う

		lea	RAM_START(pc),a0
		lea	RAMDISK_MEMORY_TABLE(pc),a1
		tst.w	18(a0)			*GRAM_MEMORY_MODE
		@ifne	{
			move.l	#$c00000,(a1)+
			move.w	#512,(a1)+
			clr.w	(a1)+
		}
		move.l	RAM_ACCESS_START(pc),d0
		tst.b	＿RAM_MEMORY_MODE(a5)
		@ifne	{
			move.l	d1,-(sp)
			moveq.l	#0,d1
			move.w	$0a+DPB_TABLE(pc),d1
			sub.l	d1,d0
			move.l	(sp)+,d1
		}
		move.l	d0,(a1)+
		move.l	RAM_SIZE(pc),d0
		divu	$0a+DPB_TABLE(pc),d0
		move.w	d0,(a1)+
		move.w	RAM_MEMORY_MODE(pc),(a1)+

		lea	DPB_TABLE(pc),a0
		lea	RAMDISK_MEMORY_TABLE(pc),a1
		move.w	4(a1),d0		*第一領域のフリーエリア
		add.w	8+4(a1),d0		*第二領域のフリーエリア
		move.w	d0,＿max_sector_no(a5)
		sub.w	$14(a0),d0		* データセクタ番号
		addq.w	#3,d0
		move.w	d0,$16(a0)		*Human2.01 最大セクタ番号

		rts

*	*	*	*	*	*	*	*	*
RAMDISK_FORMAT::		*フォーマットを行う
*		in	d1.w	フォーマット実行フラグ（０で強制実行、それ以外で破壊時のみ実行）
*		out	d1.l	０で実行された

		move.l	d2,-(sp)
		moveq.l	#0,d2
		move.w	$0a+DPB_TABLE(pc),d2		* sector_len

		movea.l	FAT_ADDRESS(pc),a0		*ＦＡＴ＆ディレクトリの開始アドレス
		move.w	$18+DPB_TABLE(pc),d0		* ルートディレクトリセクタ番号
		sub.w	$0e+DPB_TABLE(pc),d0		* FATセクタ番号
		mulu	d2,d0
		lea	(a0,d0.l),a1			*ディレクトリの先頭セクタ
		moveq.l	#0,d0

		tst.w	d1
		@ifne	{
			move.l	(a0),d0
			rol.l	#8,d0
			andi.w	#$ff,d0
			move.l	d0,-(sp)
			move.b	$1a+DPB_TABLE(pc),d0
			cmp.b	#$f9,d0
			movem.l	(sp)+,d0
			@ifne	{
				move.b	#$F9,d0
			}
			ror.l	#8,d0
			cmpi.l	#$F9FFFF00,d0		*FATが正常か？
			bne	>
			bsr	RAMDISK_FORMAT_work_write	*ＦＡＴ＆ディレクトリの情報を残しておく
			bra	RAMDISK_FORMAT_e
		}
		move.b	RAM_MEMORY_MODE(pc),d0
*		tst.b	d0
		@ifne	{
			tst.w	＿GRAM_MEMORY_MODE(a5)
			bne	>
			move.w	$18+DPB_TABLE(pc),d0		* ルートディレクトリセクタ番号
			sub.w	$0e+DPB_TABLE(pc),d0		* FATセクタ番号
			mulu	d2,d0
			move.l	a0,a1
			sub.l	d0,a1				*ディレクトリの開始セクタ
			move.w	$14+DPB_TABLE(pc),d0		* データセクタ番号
			subq.w	#1,d0
			mulu	d2,d0
			sub.l	d0,a0				*ディレクトリの開始セクタ
		}

		moveq.l	#0,d0
		move.w	$14+DPB_TABLE(pc),d1
		mulu	d2,d1
		lsr.w	#2,d1
		subq.w	#1,d1
		{	*ＦＡＴ＆ディレクトリのクリア
			move.l	d0,(a0)+
			dbra	d1,<
		}

		movea.l	FAT_ADDRESS(pc),a0
		move.l	#$f9ffff00,(a0)
		move.b	#-1,＿media_change_flag(a5)

		dc.w	_GETTIME
		ror.w	#8,d0
		move.w	d0,＿dirtime(a5)
		dc.w	_GETDATE
		ror.w	#8,d0
		move.w	d0,＿dirdate(a5)

		lea	dirdata(pc),a0
		moveq.l	#(32/4)-1,d0
		{
			move.l	(a0)+,(a1)+
			dbra	d0,<
		}

		bsr	RAMDISK_FORMAT_work_write	*ＦＡＴ＆ディレクトリの情報を残しておく

		moveq.l	#0,d1
		moveq.l	#5,d0

RAMDISK_FORMAT_e::
		move.l	(sp)+,d2
		rts


RAMDISK_FORMAT_work_write::	*ワークエリアにＦＡＴ＆ディレクトリ情報のワークを書き込む

		movem.l	d0/a0/a2,-(sp)
		movea.l	FAT_ADDRESS(pc),a0		*ＦＡＴ＆ディレクトリの開始アドレス
		move.w	$18+DPB_TABLE(pc),d0		* ルートディレクトリセクタ番号
		sub.w	$0e+DPB_TABLE(pc),d0		* FATセクタ番号
		mulu	$0a+DPB_TABLE(pc),d0		* sector_len
		lea	(a0,d0.l),a2			*空いているのでフラグを置かせてもらう
		move.b	RAM_MEMORY_MODE(pc),d0
*		tst.b	d0
		@ifne	{
			tst.w	＿GRAM_MEMORY_MODE(a5)
			bne	>
			move.w	$18+DPB_TABLE(pc),d0		* ルートディレクトリセクタ番号
			sub.w	$0e+DPB_TABLE(pc),d0		* FATセクタ番号
			subq.w	#2,d0
			mulu	$0a+DPB_TABLE(pc),d0		* sector_len
			neg.l	d0
			lea	(a0,d0.l),a2			*空いているのでフラグを置く。
		}
		move.l	RAM_SIZE(pc),d0
		divu	$0a+DPB_TABLE(pc),d0
		move.w	d0,-8(a2)			*ＦＡＴの空き部分　RAM_SIZEを置いておく
		move.l	RAM_ACCESS_START(pc),-6(a2)	*ＦＡＴの空き部分　RAM_ACCESS_STARTを置いておく
		move.w	RAM_MEMORY_MODE(pc),-2(a2)	*ＦＡＴの空き部分　メモリモードを置いておく

		movem.l	(sp)+,d0/a0/a2
		rts


dirdata::
		dc.b	'RAM_DISK   ',8,0,0,0,0
		dc.b	0,0,0,0,0,0
dirtime::
		dc.b	$a0,$60
dirdate::
		dc.b	$e7,$0a
		dc.b	0,0,0,0,0,0



*	*	*	*	*	*	*	*	*
*DEVICE_INSERTは非常駐部分に置く

DEVICE_DELETE::
*		out	d0.l	エラーフラグ（マイナスでエラー）

		lea	DPB_TABLE(pc),a1

		bsr	first_dpb_get

		{
			tst.l	6(a0)			*Human2.01 次のＤＰＢへのリンクポインタ
			bmi	DEVICE_DELETE_ERR1	*ＤＰＢが存在しません
			cmpa.l	6(a0),a1		*Human2.01 次のＤＰＢへのリンクポインタ
			beq	>			*次のＤＰＢが自分自身だったら抜ける
			movea.l	6(a0),a0		*Human2.01 次のＤＰＢへのリンクポインタ
			bra	<
		}

		move.l	6(a1),6(a0)		*Human2.01 自分自身のＤＰＢをＫＩＬＬ

		movea.l	2(a0),a0		*Human2.01 デバイスヘッダへのポインタ
		moveq.l	#-2,d0
		lea	DEVICE_HEADER(pc),a1
		{
			cmpa.l	a0,a1			*自分自身のデバイスヘッダか？
			beq	>
			move.l	a0,d0			*現在のデバイスヘッダをキープ
			tst.l	(a0)			*次のデバイスヘッダへのリンクポインタ
			movea.l	(a0),a0			*フラグは変わらない
			bpl	<
			bra	DEVICE_DELETE_ERR2
		}
		movea.l	d0,a0
		move.l	(a1),(a0)		*自分自身のデバイスヘッダをＫＩＬＬ

		bsr	drive_information_table_exchange
		subq.b	#1,(Ｈnum_of_drive)

		moveq.l	#0,d0
		rts

DEVICE_DELETE_ERR1::	*ＤＰＢが存在しません。
		moveq.l	#7,d7
		moveq.l	#-1,d0
		rts
DEVICE_DELETE_ERR2::	*デバイスドライバが存在しません。
		moveq.l	#8,d7
		moveq.l	#-1,d0
		rts


first_dpb_get::
		lea	Ｈdrive_assign_table,a0
		moveq.l	#0,d1
		{
			addq.w	#1,d1
			tst.b	(a0)+
			bne	<
		}
		lea	DPB_buffer(pc),a0
		move.l	a0,-(sp)
		move.w	d1,-(sp)
		dc.w	_GETDPB
		addq.w	#6,sp
		movea.l	24(a0),a0		*次のＤＰＢへのリンクポインタ
		rts


drive_information_table_exchange::

		lea	DRIVE_INFORMATION_TABLE(pc),a0
		move.w	10(a6),d0		*ドライブ名
		lea	Ｈdrive_assign_table,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		mulu	#$4e,d0
		movea.l	(Ｈdrive_info_ptr),a1	*Human2.01 DRIVE_INFORMATION_TABLEへのポインタ
		adda.w	d0,a1

		addq.w	#1,a0
		addq.w	#1,a1			*どうやら最初の１バイトは動かさない方がいい？(V1.13)
		moveq.l	#$4e-1-1,d0
		{
			move.b	(a0),d1
			move.b	(a1),(a0)+
			move.b	d1,(a1)+
			dbra	d0,<
		}
		rts



*	*	*	*	*	*	*	*	*
CONTROL_MAIN::		*常駐部コントローラ
*		in	a6	command table
*			0.w	command code	0=登録＆変更
*						1=ステータス
*						2=フォーマット
*						-1=常駐解除
*			2.w	容量。ＫＢ単位。
*			4.w	メモリモード。上位バイトが０で小方向、１で大方向から。下位バイトはドライブタイプ。
*			6.w	グラフィックＲＡＭ使用フラグ。1で使用。
*			8.w	フォーマットフラグ。com=0の時に使う。1で強制フォーマット、
*				2で強制ノンフォーマット、それ以外はアンフォーマット時のみ。
*			10.w	ドライブ名。0=A: 1=B:･･･
*			12.w	ベリファイスイッチ。０で無視。１でする。２でしない。
*			14.w	強制常駐フラグ　≠０でする。
*			16.w	強制フォーマット・解放実行フラグ　≠０でする。
*			18.w	容量指定形スイッチ。=0で絶対、1で+n、-1で-n。
*			20.w	再登録時メモリデータ優先スイッチ。１で優先する。
*			22.w	GRADLOADERからの登録スイッチ。１でGRADLOADERから。
*			24.w	書き込み禁止スイッチ。０で無視。１で禁止。２で許可。
*			26.w	アクセスランプスイッチ。０で無視。１で無使用。２で使用。
*		out	d0	return status
*				command code=	０	マイナスでエラー
*							1	メモリを新規に確保
*							2	メモリを変更
*							3	メモリを解放
*						１	4	ステータスを取り込んだ
*						２	5	フォーマットした	
*			d1	フォーマットフラグ	1	フォーマットを行った
*			d2	最高ＦＡＴ番号
*			d7	エラーコード
		lea	PSTART(pc),a5
		move.w	(a6),d0
		cmpi.w	#-1,d0
		beq	CONTROL_MAIN_ff
		cmpi.w	#3,d0
		bcc	CONTROL_MAIN_ERR1	*コマンドコードが異常です。
		add.w	d0,d0
		move.w	CONTROL_MAIN_JPT(pc,d0.w),d0
		jsr	CONTROL_MAIN_JPT(pc,d0.w)
		rts
CONTROL_MAIN_JPT::
		dc.w	CONTROL_MAIN_0-CONTROL_MAIN_JPT	*容量設定＆変更
		dc.w	CONTROL_MAIN_1-CONTROL_MAIN_JPT	*ステータス
		dc.w	CONTROL_MAIN_2-CONTROL_MAIN_JPT	*フォーマット

*	*	*	*

CONTROL_MAIN_0::	*容量設定＆変更

		bsr	CONTROL_MAIN_sub2
		move.w	2(a6),d1		*容量
		move.l	RAM_SIZE(pc),d0
		divu	$0a+DPB_TABLE(pc),d0
		tst.w	18(a6)			*容量指定形スイッチ
		@ifne	{
			@ifmi	{			*-nのパラメータ
				sub.w	d1,d0
				@ifmi	{
					moveq.l	#0,d0
				}
				move.w	d0,d1
			}else
			{				*+nのパラメータ
				add.w	d0,d1
			}
		}

		tst.w	＿DPB_TABLE(a5)
		@ifeq	{			*新規登録
			tst.w	6(a6)			*Ｇ－ＲＡＭ使用フラグ
		}else
		{				*登録されている
			tst.w	＿GRAM_MEMORY_MODE(a5)
		}

		@ifeq	{			*Ｇ－ＲＡＭを使っていない場合
			cmpi.w	#16,d1
			bcs	CONTROL_MAIN_ERR7
			cmp.w	max_capacity(pc),d1
			bhi	CONTROL_MAIN_ERR9
		}else
		{				*Ｇ－ＲＡＭを使っている場合
			cmpi.w	#1,d1
			bcs	CONTROL_MAIN_ERR8
			add.w	#512,d1
			cmp.w	max_capacity(pc),d1
			bhi	CONTROL_MAIN_ERR9
			sub.w	#512,d1
		}
		move.w	d1,2(a6)		*容量
			
		tst.w	＿DPB_TABLE(a5)
		@ifeq	{			*新規登録
			move.w	22(a6),＿SYS_MODE(a5)	*CONFIG.SYSからの起動スイッチ
			moveq.l	#0,d1
			move.w	10(a6),d1		*ドライブ名
			bsr	DEVICE_INSERT
			tst.l	d0
			bmi	CONTROL_MAIN_ERR2
			bsr	CONTROL_MAIN_sub1
			tst.l	d0
			bmi	CONTROL_MAIN_ERR3	*DEVICE_DELETEを行う
		}else
		{				*容量変更
			bsr	CONTROL_MAIN_sub1
			tst.l	d0
			bmi	CONTROL_MAIN_ERR2
		}

		move.l	d0,-(sp)
		bsr	RAMDISK_MEMORY_SET

		moveq.l	#-1,d1			* フォーマットしない
		move.w	8(a6),d0
		subq.w	#1,d0			*cmpi.w	#1,d0
		@ifeq	{
			moveq.l	#0,d1			*強制フォーマット
		}else
		{
			subq.w	#1,d0			*cmpi.w	#2,d0
			@ifne	{
				moveq.l	#1,d1			*破壊時のみフォーマット
			}
		}
		tst.w	d1
		@ifpl	{				* 正ならフォーマットしに行く
			bsr	RAMDISK_FORMAT
		}

		tst.w	14(a6)			*強制フォーマット・解除フラグ
		@ifeq	{			*強制常駐しない
			bsr	USED_FAT_CHECK
			cmp.w	max_sector_no(pc),d0
			bgt	CONTROL_MAIN_ERR4	*最大セクタ番号を超えるＦＡＴができる2

			movea.l	FAT_ADDRESS(pc),a0
			move.w	GRAM_MEMORY_MODE(pc),d0	*tstの代わり
			@ifne	{			*Ｇ－ＲＡＭ使用スイッチが入っている
				move.w	$0a+DPB_TABLE(pc),d0
				mulu	$18+DPB_TABLE(pc),d0
				move.w	-2(a0,d0.l),d0		*ＦＡＴ空き部分　RAM_MEMORY_MODE
				cmp.w	RAM_MEMORY_MODE(pc),d0
				bne	CONTROL_MAIN_ERR6	*メモリの管理方法が異なる	

				move.w	$0a+DPB_TABLE(pc),d0
				mulu	$18+DPB_TABLE(pc),d0
				move.l	-6(a0,d0.l),d0		*ＦＡＴ空き部分　RAM_ACCESS_START
				cmp.l	RAM_ACCESS_START(pc),d0
				@ifne	{			*前回取った時と状況が異なる
					tst.w	＿RAM_SIZE(a5)		*G-RAMのみの場合だけ許してあげる
					bne	CONTROL_MAIN_ERR5	*メモリの管理方法が異なる
				}
			}
		}
		tst.w	d1
		@ifpl	{			*強制ノンフォーマットでないとき
			bsr	RAMDISK_FORMAT		*強制の場合は２度行ってしまうが目をつぶる
		}

		bsr	USED_FAT_CHECK_
		move.l	d0,d2

		move.l	(sp)+,d0
CONTROL_MAIN_ERR2::
		rts

CONTROL_MAIN_ERR3::
		movem.l	d0/d7,-(sp)
		bsr	DEVICE_DELETE
		movem.l	(sp)+,d0/d7
		rts
CONTROL_MAIN_ERR1::	*コマンドコードが異常です。
		moveq.l	#9,d7
		moveq.l	#-1,d0
		rts
CONTROL_MAIN_ERR4::	*最大セクタ番号を超えるＦＡＴができる2
		bsr	CONTROL_MAIN_ERR_sub1
		moveq.l	#19,d7
CONTROL_MAIN_ERR_::
		addq.w	#4,sp	*kill stack
		moveq.l	#-1,d0
		rts
CONTROL_MAIN_ERR5::	*メモリの管理方法が異なる(開始位置）
		bsr	CONTROL_MAIN_ERR_sub1
		moveq.l	#20,d7
		bra	CONTROL_MAIN_ERR_
CONTROL_MAIN_ERR6::	*メモリの管理方法が異なる(-B)
		bsr	CONTROL_MAIN_ERR_sub1
		moveq.l	#21,d7
		bra	CONTROL_MAIN_ERR_
CONTROL_MAIN_ERR7::	*容量が小さすぎます1
		moveq.l	#14,d7
		bra	CONTROL_MAIN_ERR_
CONTROL_MAIN_ERR8::	*容量が小さすぎます2
		moveq.l	#23,d7
		bra	CONTROL_MAIN_ERR_
CONTROL_MAIN_ERR9::	*容量が大きすぎます
		moveq.l	#15,d7
		bra	CONTROL_MAIN_ERR_


CONTROL_MAIN_ERR_sub1::
		bsr	MEMORY_REMOVE
		bsr	DEVICE_DELETE
		rts





CONTROL_MAIN_sub1::
		move.w	2(a6),d1		*容量
		move.w	4(a6),d2		*メモリモード
		move.w	6(a6),d3		*Ｇ－ＲＡＭ使用フラグ
		move.w	12(a6),d4		*ベリファイスイッチ
		move.w	18(a6),d5		*容量指定形スイッチ
		move.w	24(a6),d6		*書き込み禁止スイッチ
		movem.l	d1-d6,-(sp)
		bsr	RAMDISK_MANAGE
		movem.l	(sp)+,d1-d6
		rts

CONTROL_MAIN_sub2::
		move.w	12(a6),d0		*ベリファイスイッチ
		subq.b	#1,d0
		@ifpl	{
			move.w	d0,＿VERIFY_MODE(a5)
		}
		move.w	24(a6),d0		*書き込み禁止スイッチ
		subq.b	#1,d0
		@ifpl	{
			move.w	d0,＿WriteEnableSw(a5)
		}
		move.w	26(a6),d0		*アクセスランプスイッチ
		subq.b	#1,d0
		@ifpl	{
			move.w	d0,＿AccessLampSw(a5)
		}
		rts

*	*	*	*

CONTROL_MAIN_1::	*ステータスを返す
		moveq.l	#1,d1
		bsr	CONTROL_MAIN_sub2
		bsr	USED_FAT_CHECK_
		move.l	d0,d2
		bsr	RAMDISK_FORMAT_work_write	*ＦＡＴ＆ディレクトリの情報を残しておく
		moveq.l	#4,d0
		rts

*	*	*	*

CONTROL_MAIN_2::	*フォーマットを行う
		bsr	CONTROL_MAIN_sub2
		moveq.l	#5,d0
		moveq.l	#1,d1
		cmpi.w	#2,8(a6)		*フォーマットフラグ
		@ifne	{
			bsr	yn_check
			tst.l	d0
			@ifne	{
				moveq.l	#99,d0
				rts
			}
			moveq.l	#0,d1		*強制フォーマット
			bsr	RAMDISK_FORMAT
		}
		move.l	d0,-(sp)
		bsr	USED_FAT_CHECK_
		move.l	d0,d2
		move.l	(sp)+,d0
		rts


*	*	*	*
CONTROL_MAIN_ff::	*常駐解除を行う
		tst.w	＿SYS_MODE(a5)
		@ifne	{				*CONFIG.SYSで登録したものは外せません。
			moveq.l	#28,d7
			moveq.l	#-1,d0
			rts
		}
		bsr	yn_check
		tst.l	d0
		@ifne	{
			moveq.l	#99,d0
			rts
		}
		moveq.l	#-1,d1
		bsr	RAMDISK_MANAGE
		tst.l	d0
		bmi	ret
		bsr	DEVICE_DELETE
		tst.l	d0
		bmi	ret
		bsr	RAMDISK_FORMAT_work_write	*ＦＡＴ＆ディレクトリの情報を残しておく
		moveq.l	#3,d0
		rts


yn_check::	*ファイルが残っている場合、本当にいいかどうか聞いてくる
		*out d0=フラグ　Ｙ＝０

		tst.w	16(a6)			*強制フォーマット・常駐解除実行フラグ
		bne	yn_check_y
		bsr	USED_FAT_CHECK_
		cmp.w	$14+DPB_TABLE(pc),d0
		bcs	yn_check_y

		pea	後悔しないな？_mes(pc)
		DOS	_PRINT
		move.w	#1,-(sp)		*キー入力を待ち、エコーバックする
		dc.w	_KFLUSH
		addq.w	#6,sp
		cmpi.b	#'Y',d0
		beq	yn_check_y
		cmpi.b	#'y',d0
		beq	yn_check_y
yn_check_n::
		moveq.l	#1,d0
		rts
yn_check_y::
		moveq.l	#0,d0
		rts


USED_FAT_CHECK::	*何番までのＦＡＴが使われているかを調べる。ただしＧ－ＲＡＭの分は引かれる。
		bsr	USED_FAT_CHECK_
		tst.w	＿GRAM_MEMORY_MODE(a5)
		@ifne	{
			subi.w	#512,d0
		}
		rts

USED_FAT_CHECK_::	*何番までのＦＡＴが使われているかを調べる
*		out	d0=使われているＦＡＴエリアで一番大きい番号(<$14+DPB_TABLE(pc)でエラー)

		movem.l	d1-d6/a0,-(sp)
		moveq.l	#0,d1
		movea.l	FAT_ADDRESS(pc),a0
		move.l	(a0),d0
		rol.l	#8,d0
		andi.w	#$ff,d0
		move.l	d0,-(sp)
		move.b	$1a+DPB_TABLE(pc),d0
		cmp.b	#$f9,d0
		movem.l	(sp)+,d0
		@ifne	{
			move.b	#$F9,d0
		}
		ror.l	#8,d0
		cmpi.l	#$F9FFFF00,d0
		@ifne	{			*ヘッダが存在しない
			move.w	$14+DPB_TABLE(pc),d0
			subq.w	#2,d0			*ＦＡＴ破壊
			bra	USED_FAT_CHECK_EXIT
		}
		tst.w	＿GRAM_MEMORY_MODE(a5)
		@ifeq	{
			tst.b	＿RAM_MEMORY_MODE(a5)
			beq	>
			move.w	$0a+DPB_TABLE(pc),d1
			add.w	d1,d1		*-b登録した時
		}

 .if 0
		move.w	#(4093+1)-(9-2),d6	*9-2は非データ領域-"F9FFFF"の分
 .endif
 .if 0
		moveq.l	#0,d6
		move.b	$11+DPB_TABLE(pc),d6
		mulu	$0a+DPB_TABLE(pc),d6
		add.l	d6,d6
		divu	#3,d6
		sub.w	$14+DPB_TABLE(pc),d6
 .endif

		move.w	max_capacity(pc),d6
		addq.w	#1,d6
		sub.w	$14+DPB_TABLE(pc),d6
		addq.w	#2,d6

		move.w	d6,d0
		subq.w	#1,d0
		addq.w	#3,a0
		move.w	#1024-3,d2
		moveq.l	#0,d4
		{
			moveq.l	#0,d5
			move.b	(a0)+,-(sp)		*(lm)
			subq.w	#1,d2
			@ifeq	{
				move.w	#1024,d2
				suba.l	d1,a0
			}
			move.b	(a0),-(sp)
			move.w	(sp)+,d3
			move.b	(sp)+,d3
			andi.w	#$fff,d3
			@ifne	{
				move.w	d6,d5
				sub.w	d0,d5			*今調べているFAT番号
				cmpi.w	#$fff,d3
				@ifeq	{
					moveq.l	#0,d3
				}
			}
			cmp.w	d3,d4
			@ifcs	{
				move.w	d3,d4
			}
			cmp.w	d5,d4
			@ifcs	{
				move.w	d5,d4
			}
			subq.w	#1,d0
			bmi	>

			moveq.l	#0,d5
			move.b	(a0)+,-(sp)		*(l-)
			subq.w	#1,d2
			@ifeq	{
				move.w	#1024,d2
				suba.l	d1,a0
			}
			move.b	(a0),-(sp)
			move.w	(sp)+,d3
			move.b	(sp)+,d3
			lsr.w	#4,d3
			andi.w	#$fff,d3
			@ifne	{
				move.w	d6,d5
				sub.w	d0,d5			*今調べているFAT番号
				cmpi.w	#$fff,d3
				@ifeq	{
					moveq.l	#0,d3
				}
			}
			cmp.w	d3,d4
			@ifcs	{
				move.w	d3,d4
			}
			cmp.w	d5,d4
			@ifcs	{
				move.w	d5,d4
			}
			addq.w	#1,a0
			subq.w	#1,d2
			@ifeq	{
				move.w	#1024,d2
				suba.l	d1,a0
			}
			dbra	d0,<
		}
		move.w	$14+DPB_TABLE(pc),d0
		subq.w	#2,d0			*ＦＡＴ破壊
		add.w	$14+DPB_TABLE(pc),d4
		subq.w	#1,d4
		cmp.w	max_capacity(pc),d4		*FAT理論上最大値
		@ifls	{			*以内におさまっている
			move.l	d4,d0
		}
USED_FAT_CHECK_EXIT::
		movem.l	(sp)+,d1-d6/a0
		rts


		.even
malloc_back::
		ds.b	16
DPB_buffer::
		ds.b	94

後悔しないな？_mes::
	dc.b	'  ',ESC,'[1;7mファイル・ディレクトリが残っていますがよろしいですか',ESC,'[0m(Y/else)？',0

		.even

KEEPEND::
*	*	*	*	*	*	*	*

COMMAND_DATA::		*常駐部に渡されるデータ：デフォルト
		dc.w	0	*+00	*コマンド：容量設定
		dc.w	-1	*+02	*容量：ドライブタイプ依存
		dc.w	$0100	*+04	*メモリモード：大方向から、DPB=type0
		dc.w	0	*+06	*Ｇ－ＲＡＭ使用フラグ：使わない
		dc.w	0	*+08	*フォーマットフラグ：消去時のみ
		dc.w	0	*+10	*ドライブ名：カレントドライブ
		dc.w	0	*+12	*ベリファイスイッチ：無視
		dc.w	0	*+14	*強制常駐スイッチ：判定する
		dc.w	0	*+16	*強制フォーマット・解放スイッチ：判定する
		dc.w	0	*+18	*容量指定形スイッチ：絶対
		dc.w	0	*+20	*再登録時メモリサイズ自動設定スイッチ：無視
		dc.w	0	*+22	*GRADLOADER.SYSからの起動スイッチ：コマンドから
		dc.w	0	*+24	*書き込み禁止スイッチ：無視
		dc.w	0	*+26	*TIMERランプスイッチ：無視

EXEC_START::		*ここから実行される

		bsr	MoveHumanVector

		lea	COMMAND_DATA(pc),a6

		cmpa.l	#0,a0			*GRADLOADER.sysから起動する時には０にしておく。
						*コマンドからでは絶対に０にならない。
		@ifeq	{
			st.b	22(a6)			*GRADLOADERからの起動スイッチ
		}

		tst.w	22(a6)			*GRADLOADERからの起動スイッチ
		@ifeq	{
			lea	16(a0),a0
			lea	PEND(pc),a1
			suba.l	a0,a1
			move.l	a1,-(sp)
			move.l	a0,-(sp)
			moveq.l	#0,d7			*Human68k V2.01 BUG.
			dc.w	_SETBLOCK
			addq.w	#8,sp
			tst.l	d0
			bmi	cmdline_analyze_ERR6
		}


		lea	BSS_START(PC),a0
BSS_SIZE	equ	BSS_END-BSS_START
		move.w	#BSS_SIZE,d1
		moveq.l	#0,d0
		{
			move.b	d0,(a0)+
			dbra	d1,<
		}

		clr.l	a1
		moveq.l	#_B_SUPER,d0
		trap	#15
		lea	keep_ssp(pc),a0
		move.l	d0,(a0)

		dc.w	_CURDRV
		move.w	d0,10(a6)		*ドライブ名
		lea	current_drive(pc),a0
		move.w	d0,(a0)

		addq.w	#1,a2

cmdline_analyze::
		{
			moveq.l	#0,d0
			move.b	(a2)+,d0
			beq	cmdline_end
			cmpi.b	#'-',d0
			beq	option_check
			cmpi.b	#'/',d0
			beq	option_check
			cmpi.b	#'+',d0
			beq	mem_use_set_
			cmpi.b	#' ',d0
			beq	<
			cmpi.b	#9,d0
			beq	<

			andi.b	#$df,d0
			subi.b	#'@',d0
			bcs	help_print
			cmpi.b	#26+1,d0
			bcc	help_print
			move.b	(a2)+,d1
			cmpi.b	#':',d1
			bne	help_print
			lea	drive_seted(pc),a0
			tst.w	(a0)
			bne	cmdline_analyze_ERR1	*ドライブ名を二重指定しています。
			st.b	(a0)
			subq.w	#1,d0
			@ifmi	{			*'@:'の場合
				move.w	#0,d1
				{
					bsr	drive_assign_get
					addq.w	#1,d1
					tst.l	d0
					bmi	cmdline_analyze_ERR9	*ドライブの空きがありません。
					bne	<			*ドライブが使われている
			}
				subq.w	#1,d1
				move.w	d1,d0
			}
				
			move.w	d0,10(a6)		*ドライブ名
			bra	<
		}

option_check::
		moveq.l	#0,d0
		move.b	(a2)+,d0
		beq	cmdline_end
		cmpi.b	#9,d0
		beq	cmdline_analyze
		cmpi.b	#' ',d0
		beq	cmdline_analyze
		cmpi.b	#'0',d0
		@ifcc	{
			cmpi.b	#'9'+1,d0
			bcs	mem_use_set__
		}
		andi.b	#$df,d0
		cmpi.b	#'G',d0
		beq	gram_use_set
		cmpi.b	#'M',d0
		beq	mem_use_set
		cmpi.b	#'F',d0
		beq	format_set
		cmpi.b	#'P',d0
		beq	print_status_set
		cmpi.b	#'R',d0
		beq	release_set
		cmpi.b	#'V',d0
		beq	verify_set
		cmpi.b	#'W',d0
		beq	write_set
		cmpi.b	#'B',d0
		beq	mem_bottom_mode_set
		cmpi.b	#'T',d0
		beq	mem_top_mode_set
		cmpi.b	#'N',d0
		beq	force_install_set
		cmpi.b	#'H',d0
		beq	not_vercheck_set
		cmpi.b	#'Y',d0
		beq	force_clear_set
		cmpi.b	#'L',d0
		beq	last_memory_mode_set
		cmpi.b	#'A',d0
		beq	AccessLamp_set
		cmpi.b	#'D',d0
		beq	DriveType_set
		bra	help_print


AccessLamp_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		bsr	switch_check		*"Y1"で１、その他で２を返す。
		move.w	d0,26(a6)		*０で設定なし　１でする　２でしない
		lea	AccessLamp_seted(pc),a0
		st.b	(a0)
		bra	option_check

last_memory_mode_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		move.w	#1,20(a6)		*再登録時にメモリサイズの自動設定をする
		bra	option_check

force_clear_set::
		move.w	#1,16(a6)		*ファイルが残っているかどうかのチェックを行わない
		lea	force_clear_seted(pc),a0
		st.b	(a0)
		bra	option_check

force_install_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		move.w	#1,14(a6)		*メモリーのチェックを行わずに常駐する
		lea	force_install_seted(pc),a0
		st.b	(a0)
		bra	option_check

not_vercheck_set::
		lea	notver_seted(pc),a0
		st.b	(a0)
		bra	option_check

mem_bottom_mode_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		move.b	#1,4(a6)		*後ろからセットする
		lea	mem_mode_seted(pc),a0
		st.b	(a0)
		bra	option_check

mem_top_mode_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		clr.b	4(a6)			*前からセットする
		lea	mem_mode_seted(pc),a0
		st.b	(a0)
		bra	option_check

DriveType_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		bsr	get_number
		cmpi.b	#3,d0
		bcc	cmdline_analyze_ERR12
		move.b	d0,1+4(a6)		*ドライブタイプを設定する
		lea	mem_mode_seted(pc),a0
		st.b	(a0)
		bra	option_check

verify_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		bsr	switch_check		*"Y1"で１、その他で２を返す。
		move.w	d0,12(a6)		*０で設定なし　１でする　２でしない
		lea	verify_seted(pc),a0
		st.b	(a0)
		bra	option_check

write_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		bsr	switch_check		*"Y1"で１、その他で２を返す。
		move.w	d0,24(a6)		*０で設定なし　１でする　２でしない
		lea	write_seted(pc),a0
		st.b	(a0)
		bra	option_check

gram_use_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		move.w	#1,6(a6)		*Ｇ－ＲＡＭ使用フラグ
		lea	gram_used(pc),a0
		st.b	(a0)
		bra	option_check

mem_use_set__::
		subq.w	#1,a2
mem_use_set_::
		subq.w	#1,a2
mem_use_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		lea	mem_seted(pc),a0
		tst.w	(a0)
		bne	cmdline_analyze_ERR3	*容量を二重指定しています。

		move.l	a2,-(sp)
		move.b	(a2),d0
		cmpi.b	#'+',d0
		@ifeq	{
			addq.w	#1,a2
			bsr	get_number
			move.w	#1,18(a6)		*容量指定形スイッチ
		}else
			{
			cmpi.b	#'-',d0
			@ifeq	{
				addq.w	#1,a2
				bsr	get_number
				move.w	#-1,18(a6)		*容量指定形スイッチ
			}else
			{
				bsr	get_number
			}
		}
		cmpa.l	(sp)+,a2
		beq	cmdline_analyze_ERR5	*容量値が存在しません。
		move.w	d1,2(a6)		*容量
		lea	mem_seted(pc),a0
		st.b	(a0)
		bra	option_check

format_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		tst.w	8(a6)			*フォーマットフラグ
		bne	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		lea	status_seted(pc),a0
		tst.w	(a0)
		bne	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		move.b	(a2),d0
		andi.w	#$df,d0
		cmpi.b	#'S',d0
		@ifeq	{
			addq.w	#1,a2
			btst.b	#0,($80e)		*SHIFTキーを読む。
			beq	option_check
			moveq.l	#1,d0
		}else
		{
			bsr	switch_check		"N0"で２、その他で１を返す
		}
		move.w	d0,8(a6)		*フォーマットフラグ
		lea	format_seted(pc),a0
		st.b	(a0)
		bra	option_check

print_status_set::
		tst.w	(a6)			*コマンドコード
		bmi	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		tst.w	8(a6)			*フォーマットフラグ
		bne	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		move.w	#1,(a6)			*コマンドコード
		lea	status_seted(pc),a0
		st.b	(a0)
		bra	option_check

release_set::
		tst.w	8(a6)			*フォーマットフラグ
		bne	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		move.w	#2,8(a6)		*フォーマットフラグ
		lea	gram_used(pc),a0
		tst.w	(a0)+			*gram_used
		bne	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		tst.w	(a0)+			*mem_seted
		bne	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		tst.w	(a0)+			*format_seted
		bne	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		tst.w	(a0)+			*status_seted
		bne	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		tst.w	20(a6)			*last_memory_mode_seted
		bne	cmdline_analyze_ERR2	*組み合わせられないオプションです。
		st.b	(a0)			*release_seted
		move.w	#-1,(a6)		*コマンドコード
		bra	option_check

*	*	*	*

switch_check::	*"1","0"をチェック。該当文字ならポインタを進める。"0"ならd0=2、else d0=1
		move.b	(a2),d0
		{
			{
				cmpi.b	#'0',d0
				beq	>>
				cmpi.b	#'1',d0
				beq	>
				moveq.l	#1,d0
				rts
			}
			addq.w	#1,a2
			moveq.l	#1,d0
			rts
		}
		moveq.l	#2,d0
		addq.w	#1,a2
		rts

			

*	*	*	*

get_number::
		moveq.l	#0,d0
		move.w	#0,d1
		{
			move.b	(a2)+,d0
			subi.b	#'0',d0
			bcs	>
			cmpi.b	#9+1,d0
			bcc	>
			add.w	d1,d1	*２倍
			add.w	d1,d0	
			lsl.w	#2,d1	*８倍
			add.w	d0,d1	*１０倍＋Ｄ０
			bra	<
		}
		subq.w	#1,a2
		move.w	d1,d0
		rts

*	*	*	*

cmdline_end::
						*ドライブタイプ設定
		moveq.l	#0,d1
		move.b	1+4(a6),d1		*ドライブタイプ
		lsl.w	#1,d1
		lea	DPB_TYPE(pc),a0
		add.w	(a0,d1.w),a0
		tst.w	2(a6)			*容量
		@ifmi	{
			move.w	(a0),2(a6)
		}
		addq.w	#2,a0
		lea	max_capacity(pc),a1
		move.w	(a0)+,(a1)
		lea	DPB_TABLE(pc),a1
		moveq.l	#$1e-1,d0
		{
			move.b	(a0)+,(a1)+
			dbra	d0,<
		}

		tst.w	4(a6)			*後ろからセットする
		@ifst	{
			pea	1024*64				* 64KB空きメモリを残しておく
			move.w	#1,-(sp)
			dc.w	_MALLOC2
			addq.w	#6,sp
			tst.l	d0
			@ifmi	{
				andi.l	#$ffffff,d0
				move.l	d0,-(sp)
				move.w	#1,-(sp)
				dc.w	_MALLOC2
				addq.w	#6,sp
				bmi	cmdline_analyze_ERR6
			}
			lea	MemSafeBufPtr(pc),a0
			move.l	d0,(a0)
		}

		tst.w	22(a6)			*CONFIG.SYSからの起動スイッチ
		@ifne	{
			tst.w	4(a6)			*後ろからセットする
			beq	cmdline_analyze_ERR10	*CONFIG.SYS 内では -B がないと起動できません。
		}

		cmpi.w	#1,8(a6)		*フォーマットスイッチ
		@ifeq	{			*する
			clr.w	20(a6)			*再登録時にメモリの自動設定をする・・・のをやめる
		}

		lea	notver_seted(pc),a0
		tst.w	(a0)			*notver_seted
		@ifeq	{			*Humanのバージョンチェックを行う。とりあえず2.01～3.99まで。
			dc.w	_VERNUM
			cmpi.w	#$201,d0
			bcs	cmdline_analyze_ERR8	*Humanのバージョンが合っていない
			cmpi.w	#$400,d0
			bcc	cmdline_analyze_ERR8	*Humanのバージョンが合っていない
		}

		bsr	CutSubst

		pea	DPB_buffer(pc)
		move.w	10(a6),-(sp)
		addq.w	#1,(sp)			*ドライブ名は1から・・・
		dc.w	_GETDPB
		addq.w	#6,sp
		move.l	d0,d7

		lea	gram_used(pc),a0
		tst.w	6(a0)			*status_seted
		@ifeq	{			*ステータス表示オプションがない
			tst.w	8(a0)			*release_seted
			@ifeq	{			*解除オプションがない
				tst.w	2(a0)			*mem_seted
				@ifeq	{			*メモリ設定オプションがない
					tst.w	(a0)			*gram_used
					@ifeq	{			*Ｇ－ＲＡＭオプションがない
						tst.w	4(a0)			*format_seted
						@ifeq	{			*フォーマットオプションがない
							tst.l	d7
							@ifpl	{			*ドライブが存在する
								move.w	#1,(a6)			*コマンドコード
							}
						}else
						{				*フォーマットオプションがある
							tst.l	d7
							@ifpl	{			*ドライブが存在する
								move.w	#2,(a6)			*コマンドコード
							}else
							{				*ドライブが存在しない
								clr.w	(a6)			*コマンドコード
							}
						}
					}else
					{			*Ｇ－ＲＡＭオプションがある
						move.w	#1,2(a6)			*-mの容量
					}
				}
			}
		}
		tst.l	d7
		@ifmi	{			*ドライブが存在しない
			tst.w	8(a0)			*release_seted
			bne	cmdline_analyze_ERR4	*そのドライブはGRAD登録されていません。
			tst.w	(a6)			*コマンドコード
			bne	cmdline_analyze_ERR4	*そのドライブはGRAD登録されていません。
			bsr	CONTROL_MAIN
			lea	PSTART(pc),a0
		}else
		{				*ドライブが存在する
			movea.l	DPB_buffer+18(pc),a0	*装置ドライバへのポインタ
			cmpi.l	#'GRAD',14+2(a0)	*デバイスヘッダ中「デバイス名＋２」
			bne	cmdline_analyze_ERR4	*そのドライブはGRAD登録されていません。
			move.l	VERSION(pc),d0
			cmp.l	22(a0),d0		*バージョン
			bne	cmdline_analyze_ERR11	*GRADのバージョンが合いません。

			tst.w	(a6)			*コマンドコード
			@ifmi	{			*解除オプションがある
				move.w	current_drive(pc),d0
				cmp.w	10(a6),d0		*ドライブ名
				beq	cmdline_analyze_ERR7	*カレントドライブは解除できません。
			}
			lea	PSTART-DEVICE_HEADER(a0),a0	*PSTARTに合わせる
			move.l	a0,-(sp)
			jsr	＿CONTROL_MAIN_HOOK(a0)	*デバイスドライバ存在アドレス
			movea.l	(sp)+,a0
		}

		lea	PSTART(pc),a5
		tst.l	d0
		bmi	error
result_print::
		cmpi.l	#99,d0
		@ifeq	{
			pea	アボート_mes(pc)
			DOS	_PRINT
			addq.w	#4,sp
			bra	EXIT_end
		}
		subq.l	#1,d0
		@ifeq	{			*新規登録
			move.l	d1,-(sp)		*フォーマットフラグ
			move.w	10(a6),d0		*ドライブ名
			addi.b	#'A',d0
			lea	drive_no_1(pc),a1
			move.b	d0,(a1)
			pea	title_mes(pc)
			DOS	_PRINT
			pea	新規登録_mes1(pc)
			DOS	_PRINT
			bsr	fb_print
			move.l	RAM_START(pc),d1
			bsr	hex_print_
			move.l	RAM_SIZE(pc),d1
			bsr	dec_print_
			pea	新規登録_mes2(pc)
			DOS	_PRINT
			lea	12(sp),sp

			move.l	(sp)+,d0		*フォーマットフラグ
			bsr	other_print

			bsr	GRADenv_set

			clr.w	-(sp)
KEEPSIZE	equ	KEEPEND-PSTART
			pea	KEEPSIZE
			bra	KEEPPR_end
		}

		subq.l	#1,d0
		@ifeq	{			*容量変更
			move.l	d1,-(sp)		*フォーマットフラグ
			move.w	10(a6),d0		*ドライブ名
			addi.b	#'A',d0
			lea	drive_no_2(pc),a1
			move.b	d0,(a1)
			pea	title_mes(pc)
			DOS	_PRINT
			pea	容量変更_mes1(pc)
			DOS	_PRINT
			bsr	fb_print
			move.l	＿RAM_START(a0),d1
			bsr	hex_print_
			move.l	＿RAM_SIZE(a0),d1
			bsr	dec_print_
			pea	容量変更_mes2(pc)
			DOS	_PRINT
			lea	12(sp),sp

			move.l	(sp)+,d0		*フォーマットフラグ
			bsr	other_print

			bsr	GRADenv_set

			bra	EXIT_end
		}

		subq.l	#1,d0
		@ifeq	{			*常駐解除
			pea	-$f0(a0)		*常駐していたプロセス

			move.w	10(a6),d0		*ドライブ名
			addi.b	#'A',d0
			lea	drive_no_3(pc),a1
			move.b	d0,(a1)
			pea	title_mes(pc)
			DOS	_PRINT
			pea	常駐解除_mes1(pc)
			DOS	_PRINT
			bsr	fb_print
			move.l	＿RAM_START(a0),d1
			bsr	hex_print_
			move.l	＿RAM_SIZE(a0),d1
			bsr	dec_print_
			pea	常駐解除_mes2(pc)
			DOS	_PRINT

			bsr	GRADenv_set

			lea	12(sp),sp
			dc.w	_MFREE
			addq.w	#4,sp
			bra	EXIT_end
		}

		subq.l	#2,d0
		@ifle	{			*ステータス取り込み
			move.l	d1,-(sp)
			move.w	10(a6),d0		*ドライブ名
			addi.b	#'a'-1,d0
			lea	drive_no_4(pc),a1
			move.b	d0,(a1)
			pea	title_mes(pc)
			DOS	_PRINT
			pea	ステータス_mes1(pc)
			DOS	_PRINT
			bsr	fb_print
			move.l	＿RAM_START(a0),d1
			bsr	hex_print_
			move.l	＿RAM_SIZE(a0),d1
			bsr	dec_print_
			pea	ステータス_mes2(pc)
			DOS	_PRINT
			lea	12(sp),sp
			move.l	(sp)+,d0		*フォーマットフラグ
			bsr	other_print

			bsr	GRADenv_set

			bra	EXIT_end
		}


		pea	なんか変ぢゃ_mes(pc)
		DOS	_PRINT
		addq.w	#4,sp
		move.w	#-1,-(sp)
		bra	EXIT2_end

GRADenv_set::
		move.l	a0,-(sp)
		move.w	10(a6),d0		*ドライブ名
		addi.b	#'A',d0
		lea	GRADDRV_env(pc),a0
		move.b	d0,(a0)
		move.l	a0,-(sp)
		clr.l	-(sp)
		pea	GRADDRV_envname(pc)
		dc.w	_SETENV
		lea	12(sp),sp
		tst.l	d0
		bmi	warning_GRADenv_set

		movea.l	(sp),a0
		move.l	＿RAM_START(a0),d1
		moveq.l	#6-1,d2
		lea	GRADMEM_env(pc),a0
		bsr	hex_string_make
		move.l	a0,-(sp)
		clr.l	-(sp)
		pea	GRADMEM_envname(pc)
		dc.w	_SETENV
		lea	12(sp),sp
		tst.l	d0
		bmi	warning_GRADenv_set

		movea.l	(sp),a0
		move.w	＿max_sector_no(a0),d1
		moveq.l	#4-1,d2
		lea	GRADSIZE_env(pc),a0
		bsr	dec_string_make
		move.l	a0,-(sp)
		clr.l	-(sp)
		pea	GRADSIZE_envname(pc)
		dc.w	_SETENV
		lea	12(sp),sp
		tst.l	d0
		bmi	warning_GRADenv_set

		movea.l	(sp)+,a0
		rts
warning_GRADenv_set::
		tst.w	22(a6)			*CONFIG.SYSからの起動スイッチ
		@ifeq	{
			pea	warning_GRADenv_set_mes(pc)
			DOS	_PRINT
			addq.w	#4,sp
		}
		movea.l	(sp)+,a0
		rts


KEEPPR_end::
		bsr	RemainSubst

		move.l	(sp)+,d1
		move.w	(sp)+,d2
		move.l	keep_ssp(pc),d0
		@ifpl	{
			movea.l	d0,a1
			moveq.l	#_B_SUPER,d0
			trap	#15
		}

		move.l	d0,-(sp)		* 空きメモリに確保しておいた分を開放する。
		move.l	MemSafeBufPtr(pc),-(sp)
		tst.l	(sp)
		@ifne	{
			DOS	_MFREE
		}
		addq.w	#4,sp
		move.l	(sp)+,d0

		tst.w	22(a6)			*GRADLOADER.SYSからの起動スイッチ
		@ifeq	{
			move.w	d2,-(sp)
			move.l	d1,-(sp)
			dc.w	_KEEPPR
		}
		lea	DEVICE_HEADER(pc),a0
		rts				*GRADLOADER.SYSへ帰る:D1=常駐する長さ:A0=デバイスヘッダのアドレス

EXIT_end::
		bsr	RemainSubst

		move.l	keep_ssp(pc),d0
		@ifpl	{
			movea.l	d0,a1
			moveq.l	#_B_SUPER,d0
			trap	#15
		}

		move.l	d0,-(sp)		* 空きメモリに確保しておいた分を開放する。
		move.l	MemSafeBufPtr(pc),-(sp)
		tst.l	(sp)
		@ifne	{
			DOS	_MFREE
		}
		addq.w	#4,sp
		move.l	(sp)+,d0

		tst.w	22(a6)			*GRADLOADER.SYSからの起動スイッチ
		@ifeq	{
			dc.w	_EXIT
		}
		moveq.l	#0,d1
		rts				*こーなるはずはないんだけど・・・。

EXIT2_end::
		bsr	RemainSubst

		moveq.l	#0,d1
		move.w	(sp)+,d1
		move.l	keep_ssp(pc),d0
		@ifpl	{
			movea.l	d0,a1
			moveq.l	#_B_SUPER,d0
			trap	#15
		}

		move.l	d0,-(sp)		* 空きメモリに確保しておいた分を開放する。
		move.l	MemSafeBufPtr(pc),-(sp)
		tst.l	(sp)
		@ifne	{
			DOS	_MFREE
		}
		addq.w	#4,sp
		move.l	(sp)+,d0

		tst.w	22(a6)			*GRADLOADER.SYSからの起動スイッチ
		@ifeq	{
			move.w	d1,-(sp)
			dc.w	_EXIT2
		}
		neg.l	d1			*マイナスにしておく
		rts


fb_print::
		tst.b	＿RAM_MEMORY_MODE(a0)
		@ifeq	{
			pea	前から_mes(pc)
		}else
		{
			pea	後ろから_mes(pc)
		}
		DOS	_PRINT
		addq.w	#4,sp
		rts


other_print::
		tst.w	d0
		@ifeq	{
			pea	フォーマット_mes3(pc)
			DOS	_PRINT
			addq.w	#4,sp
		}

		tst.w	＿VERIFY_MODE(a0)
		@ifeq	{
			pea	ベリファイ_mes1(pc)
		}else
		{
			pea	ベリファイ_mes2(pc)
		}
		DOS	_PRINT
		addq.w	#4,sp

		tst.w	＿WriteEnableSw(a0)
		@ifeq	{
			pea	書き込み禁止_mes1(pc)
		}else
		{
			pea	書き込み禁止_mes2(pc)
		}
		DOS	_PRINT
		addq.w	#4,sp


		pea	ＦＡＴ表示_mes1(pc)
		DOS	_PRINT
		move.l	d2,d1
		move.w	$14+＿DPB_TABLE(a0),d3
		subq.w	#2,d3
		cmp.w	d3,d1
		@ifne	{
			addq.w	#1,d3
			cmp.w	d3,d1
			@ifeq	{			*FATが使用されていない
				pea	ＦＡＴ表示_mes4(pc)
				DOS	_PRINT
			}else
			{				*FATが使用されている
				bsr	dec_print
				pea	ＦＡＴ表示_mes2(pc)
				DOS	_PRINT
			}
		}else
		{				*FATが破壊されている
			pea	ＦＡＴ表示_mes3(pc)
			DOS	_PRINT
		}
		addq.w	#8,sp


		tst.w	＿AccessLampSw(a0)
		@ifeq	{
			pea	アクセスランプ_mes1(pc)
		}else
		{
			pea	アクセスランプ_mes2(pc)
		}
		DOS	_PRINT
		addq.w	#4,sp


		rts


cmdline_analyze_ERR1::	*ドライブ名を二重指定しています。
		moveq.l	#10,d7
		bra	error_
cmdline_analyze_ERR2::	*組み合わせられないオプションです。
		moveq.l	#11,d7
		bra	error_
cmdline_analyze_ERR3::	*容量を二重指定しています。
		moveq.l	#12,d7
		bra	error_
cmdline_analyze_ERR4::	*そのドライブはGRAD登録されていません。
		moveq.l	#13,d7
		bra	error_
cmdline_analyze_ERR5::	*-Mオプションのパラメータが存在しません。
		moveq.l	#24,d7
		bra	error_
cmdline_analyze_ERR6::	*メモリが足りないので起動できません。
		moveq.l	#25,d7
		bra	error_
cmdline_analyze_ERR7::	*カレントドライブは解除できません。
		moveq.l	#18,d7
		bra	error_
cmdline_analyze_ERR8::	*Ｈｕｍａｎのバージョンが合わないため起動できません。
		moveq.l	#22,d7
		bra	error_
cmdline_analyze_ERR9::	*ドライブの空きがありません。
		moveq.l	#26,d7
		bra	error_
cmdline_analyze_ERR10::	*CONFIG.SYS 内では -B がないと起動できません。
		moveq.l	#27,d7
		bra	error_
cmdline_analyze_ERR11::	*GRADのバージョンが合いません。
		moveq.l	#29,d7
		bra	error_
cmdline_analyze_ERR12::	*ドライブタイプが異常です。
		moveq.l	#31,d7
		bra	error_



*	*	*	*	*	*	*	*

RAMDISK_MANAGE_NEW::
		mulu	#1024,d1

		tst.w	d3
		@ifne	{
			bsr	GRAM_USED_CHECK
			tst.l	d0
			bne	RAMDISK_MANAGE_ERR5

			movem.l	d1-d2,-(sp)
			moveq.l	#0,d1
			moveq.l	#1,d2
			moveq.l	#_TGUSEMD,d0
			trap	#15			*システムで使用中にする
			movem.l	(sp)+,d1-d2
		}

		move.w	d2,8(a0)		*RAM_MEMORY_MODE
		move.w	d3,18(a0)		*GRAM_MEMORY_MODE

		ror.w	#8,d2
		tst.b	d2
		@ifeq	{			*-Bオプションなし
			move.l	d1,-(sp)
			move.w	#0,-(sp)
			dc.w	_MALLOC2
			addq.w	#6,sp
			tst.l	d0
			bmi	RAMDISK_MANAGE_ERR3	*メモリが足りない
			move.l	d0,(a0)			*RAM_START
			move.l	d0,14(a0)		*RAM_ACCESS_START
			tst.w	d3
			@ifeq	{
				move.l	d1,-(sp)
				move.w	$0e+DPB_TABLE(pc),d1
				mulu	$0a+DPB_TABLE(pc),d1
				add.l	d0,d1
				move.l	d1,10(a0)		*FAT_ADDRESS
				move.l	(sp)+,d1
			}else
			{
				move.l	d1,-(sp)
				move.w	$0e+DPB_TABLE(pc),d1
				mulu	$0a+DPB_TABLE(pc),d1
				add.l	#$c00000,d1
				move.l	d1,10(a0)		*FAT_ADDRESS
				move.l	(sp)+,d1
			}
			tst.w	20(a6)			*再登録時メモリサイズ自動設定スイッチ
			@ifne	{			*が設定されている
				move.l	a1,-(sp)
				movea.l	FAT_ADDRESS(pc),a1
				move.l	(a1),d0
				rol.l	#8,d0
				andi.w	#$ff,d0
				move.l	d0,-(sp)
				move.b	$1a+DPB_TABLE(pc),d0
				cmp.b	#$f9,d0
				movem.l	(sp)+,d0
				@ifne	{
					move.b	#$F9,d0
				}
				ror.l	#8,d0
				cmpi.l	#$F9FFFF00,d0
				@ifeq	{			*ヘッダがちゃんとある
					moveq.l	#0,d0
					move.w	$18+DPB_TABLE(pc),d0		* ルートディレクトリセクタ番号
					sub.w	$0e+DPB_TABLE(pc),d0		* FATセクタ番号
					mulu	$0a+DPB_TABLE(pc),d0		* sector_len
					move.w	-8(a1,d0.l),d0	*ＦＡＴ空き部分　RAM_SIZE
					mulu	#1024,d0
					cmp.l	d1,d0
					@ifcc	{			*前回はメモリサイズがもっと大きかった
						move.l	d0,-(sp)
						move.l	RAM_START(pc),-(sp)
						moveq.l	#0,d7			*Human68k V2.01 BUG.
						dc.w	_SETBLOCK
						addq.w	#4,sp
						tst.l	d0
						@ifmi	{			*メモリが足りなかった
							addq.w	#4,sp
						}else
						{				*足りた
							move.l	(sp)+,d1	*新しい方のサイズにする
						}
					}
				}
				move.l	(sp)+,a1
			}

			pea	1024*64				* 64KB空きメモリを残しておく
			move.w	#1,-(sp)
			dc.w	_MALLOC2
			addq.w	#6,sp
			tst.l	d0
			bmi	RAMDISK_MANAGE_ERR3		* 残らない
			move.l	a0,-(sp)
			lea	MemSafeBufPtr(pc),a0
			move.l	d0,(a0)
			move.l	(sp)+,a0

			moveq.l	#1,d0			*領域確保

		}else
		{	*-Bオプションあり
			move.l	(Ｈmemory_end),a1
			bsr	RAMDISK_MANAGE_NEW_sub1
			tst.l	d0
			bne	RAMDISK_MANAGE_ERR3_

			tst.w	20(a6)			*再登録時メモリサイズ自動設定スイッチ
			@ifne	{			*が設定されている
				move.w	$0e+DPB_TABLE(pc),d0		* FATセクタ番号
				addq.w	#1,d0
				mulu	$0a+DPB_TABLE(pc),d0		* sector_len
				neg.l	d0
				move.l	(a1,d0.l),d0
				rol.l	#8,d0
				andi.w	#$ff,d0
				move.l	d0,-(sp)
				move.b	$1a+DPB_TABLE(pc),d0
				cmp.b	#$f9,d0
				movem.l	(sp)+,d0
				@ifne	{
					move.b	#$F9,d0
				}
				ror.l	#8,d0
				cmpi.l	#$F9FFFF00,d0
				@ifeq	{			*ヘッダ発見
					move.w	$18+DPB_TABLE(pc),d0		* ルートディレクトリセクタ番号
					subq.w	#1,d0
					mulu	$0a+DPB_TABLE(pc),d0		* sector_len
					neg.l	d0
					move.w	-8(a1,d0.l),d0	*ＦＡＴ空き部分　RAM_SIZE
					cmpi.w	#16,d0
					bcs	>			*一応、規定値に
					cmp.w	max_capacity(pc),d0
					bhi	>			*入っているかどうかチェック
					mulu	#1024,d0
					cmp.l	d1,d0
					@ifcc	{			*前回はメモリサイズがもっと大きかった
						move.l	d0,-(sp)
						bsr	RAMDISK_MANAGE_NEW_sub1
						tst.l	d0
						@ifmi	{			*メモリが足りなかった
							addq.w	#4,sp
						}else
						{				*足りた
							move.l	(sp)+,d1		*新しい方のサイズにする
						}
					}
				}
			}

			move.l	a1,d0
			move.l	d0,14(a0)		*RAM_ACCESS_START
			sub.l	d1,d0
			move.l	d0,(Ｈmemory_end)

			move.l	14(a0),d2		*RAM_ACCESS_START
			sub.l	d1,d2
			move.l	d2,(a0)			*RAM_START
			move.b	#1,8(a0)		*RAM_MEMORY_MODE
			tst.w	d3
			@ifeq	{
				move.l	d1,-(sp)
				move.w	$0e+DPB_TABLE(pc),d1
				addq.w	#1,d1
				mulu	$0a+DPB_TABLE(pc),d1
				sub.l	d1,a1
				move.l	a1,10(a0)		*FAT_ADDRESS
				move.l	(sp)+,d1
			}else
			{
				move.l	d1,-(sp)
				move.w	$0e+DPB_TABLE(pc),d1
				mulu	$0a+DPB_TABLE(pc),d1
				add.l	#$c00000,d1
				move.l	d1,10(a0)		*FAT_ADDRESS
				move.l	(sp)+,d1
			}

			moveq.l	#1,d0			*領域確保
		}

		tst.l	d0
		@ifpl	{
			move.l	d1,4(a0)			*RAM_SIZE
			moveq.l	#1,d0			*領域確保
		}			
		rts




GRAM_USED_CHECK::	*Ｇ－ＲＡＭが既に使用されているかどうかチェック
		*out	d0=0	使われていない
		*	   1	他のＧＲＡＤ．Ｘで使用中
		*	   2	システム／他のアプリケーションで使用中

		movem.l	d1-d3/a0,-(sp)
		moveq.l	#0,d2			*使用中フラグ
		moveq.l	#26,d3
		{
			pea	DPB_buffer(pc)
			move.w	d3,-(sp)
			dc.w	_GETDPB
			addq.w	#6,sp
			tst.l	d0
			@ifpl	{
				movea.l	DPB_buffer+18(pc),a0	*装置ドライバへのポインタ
				cmpi.l	#'GRAD',14+2(a0)	*デバイス名＋２
				@ifeq	{
					tst.w	＿GRAM_MEMORY_MODE-8(a0)	*PSTARTのjmpの分だけ引いておく
					bne	GRAM_USED_CHECK_end1
				}
			}
			subq.w	#1,d3
			bne	<
		}
		moveq.l	#0,d1
		moveq.l	#-1,d2
		moveq.l	#_TGUSEMD,d0
		trap	#15			*Ｇ－ＲＡＭの使用状況をチェック
		tst.l	d0			*使用されていない
		beq	GRAM_USED_CHECK_end0
		cmpi.b	#3,d0			*使用後で破壊されている
		bne	GRAM_USED_CHECK_end2
GRAM_USED_CHECK_end0::
		moveq.l	#0,d0
		movem.l	(sp)+,d1-d3/a0
		rts

GRAM_USED_CHECK_end1::
		moveq.l	#1,d0
		movem.l	(sp)+,d1-d3/a0
		rts

GRAM_USED_CHECK_end2::
		moveq.l	#2,d0
		movem.l	(sp)+,d1-d3/a0
		rts

DEVICE_INSERT::
*		in	d1.l	ドライブ名（0=A: 1=b:･･･）
*		out	d0.l	エラーフラグ（マイナスでエラー）


		lea	DEVICE_HEADER(pc),a0
		lea	strategy(pc),a1
		move.l	a1,6(a0)
		lea	interrupt(pc),a1
		move.l	a1,10(a0)
		lea	DPB_TABLE(pc),a1
		move.l	a0,2(a1)		*一見間違っているようだがこれでよろしい。
		lea	DRIVE_INFORMATION_TABLE(pc),a0
		move.l	a1,70(a0)		*なんかすごーく悪いことをして
						*いるような気がする・・・。

		lea	Ｈdrive_assign_table,a0
		move.b	0(a0,d1.w),＿DPB_TABLE(a5)

		bsr	drive_assign_get

		tst.l	d0
		bmi	DEVICE_INSERT_ERR1	*ドライブ名が異常です
		tst.b	d0
		bne	DEVICE_INSERT_ERR2	*ドライブはすでに使用されています

		bsr	first_dpb_get

		{
			tst.l	6(a0)			*Human2.01 次のＤＰＢへのリンクポインタ
			bmi	>
			movea.l	6(a0),a0		*Human2.01 次のＤＰＢへのリンクポインタ
			bra	<
		}

		move.l	a0,-(sp)

		lea	Ｈdrive_assign_table,a0
		move.b	0(a0,d1.w),d0
		addq.w	#1,d0			*ドライブ名は１から・・・
		pea	DPB_buffer(pc)
		move.w	d0,-(sp)
		dc.w	_GETDPB
		addq.w	#6,sp
		move.l	DPB_buffer+18(pc),a0
		{
			tst.l	(a0)			*次のデバイスドライバへのリンクポインタ
			bmi	>
			movea.l	a0,a1
			movea.l	(a0),a0			*次のデバイスドライバへのリンクポインタ
			bra	<
		}
		tst.w	22(a6)			*CONFIG.SYSからの起動スイッチ
						*a0=Cの、a1=Bのポインタ
		@ifne	{			*A-B-C から A-B-D-Cとリンク
			movea.l	a1,a0
			lea	DEVICE_HEADER(pc),a1
			move.l	(a0),(a1)
		}else
		{				*A-B-C から A-B-C-Dとリンク
			lea	DEVICE_HEADER(pc),a1
		}
		move.l	a1,(a0)			*次のデバイスドライバへのリンクポインタ
		move.l	(sp)+,a0

		lea	DPB_TABLE(pc),a1
		move.l	a1,6(a0)		*Human2.01 次のＤＰＢへのリンクポインタ

		move.w	10(a6),d0		*ドライブ名
		bsr	drive_information_table_exchange
		addq.b	#1,(Ｈnum_of_drive)

		moveq.l	#0,d0
		rts

drive_assign_get::	*ドライブの割り当て状況を調べる
			*in	d1=drive number(a:=0,b:=1,)
		move.l	d1,-(sp)
		lea	DPB_buffer(pc),a0

		addi.b	#'A',d1
		rol.w	#8,d1
		move.b	#':',d1
		swap	d1

		move.l	d1,-(sp)
		move.l	a0,-(sp)
		pea	4(sp)
		clr.w	-(sp)
		dc.w	_ASSIGN
		lea	14(sp),sp
		move.l	(sp)+,d1
		rts



DEVICE_INSERT_ERR1::		*ドライブ名が異常です
		moveq.l	#5,d7
		moveq.l	#-1,d0
		rts
DEVICE_INSERT_ERR2::		*ドライブはすでに使用されています
		moveq.l	#6,d7
		moveq.l	#-1,d0
		rts


*	*	*	*	*	*	*	*	*


CutSubst::
						* Subst情報を保存
		lea	AssignInfoBuf(pc),a0
		clr.w	(a0)
		clr.b	2(a0)
		clr.w	-(sp)
		move.w	#'A:',-(sp)
		move.w	10(a6),d0
		add.b	d0,(sp)
		pea	2(a0)
		pea	4(sp)
		clr.w	-(sp)
		dc.w	_ASSIGN
		lea	10+4(sp),sp
		move.w	d0,(a0)
						* Subst情報を切る
		cmpi.w	#$60,d0
		@ifeq	{
			clr.w	-(sp)
			move.w	#'A:',-(sp)
			move.w	10(a6),d0
			add.b	d0,(sp)
			pea	(sp)
			move.w	#4,-(sp)
			dc.w	_ASSIGN
			lea	6+4(sp),sp
		}

		rts


*	*	*	*	*	*	*	*	*


RemainSubst::
						* Subst情報を復活
		lea	AssignInfoBuf(pc),a0
		tst.w	(a0)
		@ifne	{
			clr.w	-(sp)
			move.w	#'A:',-(sp)
			move.w	10(a6),d0
			add.b	d0,(sp)
			move.w	(a0),-(sp)
			pea	2(a0)
			pea	6(sp)
			move.w	#1,-(sp)
			dc.w	_ASSIGN
			lea	12+4(sp),sp
		}

		rts


*	*	*	*	*	*	*	*	*


MoveHumanVector::
						* DOSコールの移動処理
		movem.l	a1/a2,-(sp)
		dc.w	_VERNUM
		cmp.w	#$020f,d0
		@ifcs	{
			clr.l	-(sp)
			dc.w	_SUPER
			move.l	d0,(sp)
			lea.l	$1940.w,a1
			lea.l	$1a00.w,a2
			move.l	(a1),d0
			cmp.l	(a2),d0
			@ifne	{
				moveq.l	#$30-1,d0
				{
					move.l	(a1)+,(a2)+
					dbra	d0,<
				}
			}
			tst.l	(sp)
			@ifpl	{
				dc.w	_SUPER
			}
			addq.w	#4,sp
		}
		movem.l	(sp)+,a1/a2
		rts


*	*	*	*	*	*	*	*	*


hex_print_::
		movem.l	d1-d2,-(sp)
		bsr	hex_print
		movem.l	(sp)+,d1-d2
		move.w	#' -',-(sp)
		dc.w	_PUTCHAR
		addq.w	#2,sp
		rts
hex_print::
		move.l	a0,-(sp)
		lea	print_buffer(pc),a0
		move.l	a0,-(sp)
		moveq.l	#6-1,d2
		bsr	hex_string_make
		DOS	_PRINT
		addq.w	#4,sp
		movea.l	(sp)+,a0
		rts

hex_string_make::	*１６進文字列を作成する
		*in	d1=number,d2=桁数-1,a0=文字列バッファのポインタ
		movem.l	d1-d2/a0,-(sp)
		moveq.l	#7,d0
		sub.w	d2,d0
		lsl.w	#2,d0			*あらかじめ左詰めする
		rol.l	d0,d1
		{
			rol.l	#4,d1
			move.b	d1,d0
			andi.w	#$0f,d0
			move.b	HEXWORD(pc,d0.w),(a0)+
			dbra	d2,<
		}
		clr.b	(a0)
		movem.l	(sp)+,d1-d2/a0
		rts

HEXWORD::	dc.b	'0123456789ABCDEF'

*	*	*	*

dec_print_::
		movem.l	d1-d2/a0-a1,-(sp)
		divu	$0a+＿DPB_TABLE(a0),d1
		bsr	dec_print
		movem.l	(sp)+,d1-d2/a0-a1
		tst.w	＿GRAM_MEMORY_MODE(a0)
		@ifne	{
			pea	gram_use_mes(pc)
			DOS	_PRINT
			addq.w	#4,sp
		}
		rts

dec_print::
		move.l	a0,-(sp)
		moveq.l	#4-1,d2
		lea	print_buffer(pc),a0
		move.l	a0,-(sp)
		bsr	dec_string_make
		DOS	_PRINT
		addq.w	#4,sp
		movea.l	(sp)+,a0
		rts

dec_string_make::	*	１０進文字列を作成する
		*in	d1=number,d2=桁数-1,a0=１０進文字列バッファのポインタ

		movem.l	d1-d2/a0,-(sp)
		lea	div_number(pc),a1
		subq.w	#1,d2
		{				*ゼロサプレス
			ext.l	d1
			divu	(a1)+,d1
			bne	dec_string_make_1
			swap	d1
			dbra	d2,<
		}
		bra	dec_string_make_2
		{
			ext.l	d1
			divu	(a1)+,d1
dec_string_make_1::
			addi.b	#'0',d1
			move.b	d1,(a0)+
			swap	d1
			dbra	d2,<
		}
dec_string_make_2::
		addi.b	#'0',d1
		move.b	d1,(a0)+
		clr.b	(a0)
		movem.l	(sp)+,d1-d2/a0
		rts

div_number::	dc.w	1000,100,10,1

*	*	*	*	*	*	*	*	*

help_print::
		pea	title_mes(pc)
		DOS	_PRINT
		pea	help_mes(pc)
		DOS	_PRINT
		addq.w	#8,sp
		move.w	#-1,-(sp)
		bra	EXIT2_end


error_::
		moveq.l	#-1,d0
error::
		move.w	d7,-(sp)
		pea	GRAD_mes(pc)
		DOS	_PRINT
		subq.w	#1,d7
		add.w	d7,d7
		move.w	error_mes_table(pc,d7.w),d0
		lea	error_mes_table(pc,d0.w),a1
		move.l	a1,-(sp)
		DOS	_PRINT
		cmpi.w	#15,8(sp)
		@ifeq	{
			move.w	max_capacity(pc),d1
			tst.w	＿GRAM_MEMORY_MODE(a0)
			@ifne	{
				sub.w	#512,d1
			}
			bsr	dec_print
			pea	ermes15_(pc)
			DOS	_PRINT
			addq.w	#4,sp
		}
		pea	CR(pc)
		DOS	_PRINT
		lea	12(sp),sp
		bra	EXIT2_end

error_mes_table::
	dc.w	ermes1-error_mes_table
	dc.w	ermes2-error_mes_table
	dc.w	ermes3-error_mes_table
	dc.w	ermes4-error_mes_table
	dc.w	ermes5-error_mes_table
	dc.w	ermes6-error_mes_table
	dc.w	ermes7-error_mes_table
	dc.w	ermes8-error_mes_table
	dc.w	ermes9-error_mes_table
	dc.w	ermes10-error_mes_table
	dc.w	ermes11-error_mes_table
	dc.w	ermes12-error_mes_table
	dc.w	ermes13-error_mes_table
	dc.w	ermes14-error_mes_table
	dc.w	ermes15-error_mes_table
	dc.w	ermes16-error_mes_table
	dc.w	ermes17-error_mes_table
	dc.w	ermes18-error_mes_table
	dc.w	ermes19-error_mes_table
	dc.w	ermes20-error_mes_table
	dc.w	ermes21-error_mes_table
	dc.w	ermes22-error_mes_table
	dc.w	ermes23-error_mes_table
	dc.w	ermes24-error_mes_table
	dc.w	ermes25-error_mes_table
	dc.w	ermes26-error_mes_table
	dc.w	ermes27-error_mes_table
	dc.w	ermes28-error_mes_table
	dc.w	ermes29-error_mes_table
	dc.w	ermes30-error_mes_table
	dc.w	ermes31-error_mes_table

ermes1	dc.b	'登録時と -G オプションのモードが異なるので容量変更できません。',0
ermes2	dc.b	'RAM ディスクのメモリ領域がメモリの中間位置にあるので容量変更・解除できません。',0
ermes3	dc.b	'メモリが足りないので登録・容量変更できません。',0
ermes4	dc.b	' GRAD.r は常駐していません。',0
ermes5	dc.b	'ドライブ名が異常です。',0
ermes6	dc.b	'指定のドライブはすでに使用されています。',0
ermes7	dc.b	'システムエラー：DPB が存在しません。',0
ermes8	dc.b	'システムエラー：デバイスドライバが存在しません。',0
ermes9	dc.b	'システムエラー：コマンドコードが異常です。',0
ermes10	dc.b	'ドライブ名を二重指定しています。',0
ermes11	dc.b	'組み合わせられないオプションです。',0
ermes12	dc.b	'容量を二重指定しています。',0
ermes13	dc.b	'指定のドライブは GRAD.r の管理ではありません。',0
ermes14	dc.b	'指定容量が小さすぎます(min=16)。',0
ermes15	dc.b	'指定容量が大きすぎます(max=',0
ermes16	dc.b	'他のドライブに登録されている GRAD.r が G-RAM を使用しています。',0
ermes17	dc.b	'システム／アプリケーションで G-RAM が使用されています。',0
ermes18	dc.b	'カレントドライブは解除できません。',0
ermes19	dc.b	'ディスク領域外を指す FAT ができるため登録・容量変更できません。',0
ermes20	dc.b	'前回登録時と RAM ディスクに割り当てられるメモリが一部異なるので登録できません。',0
ermes21	dc.b	'前回登録時と -B オプションのモードが異なるので登録できません。',0
ermes22	dc.b	'Human のバージョンが合わないため起動できません。',0
ermes23	dc.b	'指定容量が小さすぎます(min=1)。',0
ermes24	dc.b	'容量値(-Mn)がありません。',0
ermes25	dc.b	'メモリが足りないため起動できません。',0
ermes26	dc.b	'ドライブの空きがありません。',0
ermes27	dc.b	'CONFIG.SYS 内では -B がないと起動できません。',0
ermes28	dc.b	'CONFIG.SYS 内で登録した GRAD.r は解除できません。',0
ermes29	dc.b	'GRAD のバージョンが合いません。',0
ermes30	dc.b	'MALLOC2 でメモリを確保しているプロセスがあるため登録・容量変更できません。',0
ermes31	dc.b	'ドライブタイプが異常です。',0

ermes15_	dc.b	')。',0

help_mes::
	dc.b   ' 指定ドライブに RAM ディスクを登録します。',13,10
	dc.b	13,10
	dc.b   ' 使いかた：GRAD.r [ドライブ名:] [-オプション]',13,10
	dc.b   '  ドライブ名：省略するとカレントドライブです。',13,10
	dc.b   '  オプション：省略すると -B -M または -P になります。',13,10
	dc.b   '    -M[n] メインメモリから n KB 確保します。省略時 256KB。',13,10
	dc.b   '　　　　　+n,-nと指定すると現在からの相対量になります。',13,10
	dc.b   '　  -G    G-RAMから 512KB 確保します。登録時のみ設定可能。',13,10
	dc.b   '　  -L    登録時に前回登録時のサイズを参照して容量を確保します。',13,10
	dc.b   '　  -T    メインメモリの前部から指定容量を確保するモードにします。登録時のみ設定可能。',13,10
	dc.b   '　  -B    メインメモリの後部から指定容量を確保するモードにします。登録時のみ設定可能。',13,10
	dc.b   '          登録時に -B を付けた場合のみ容量増加ができます。',13,10
	dc.b   '　  -F    フォーマットを行います。',13,10
	dc.b   '　  -F0   FATが破壊されていてもフォーマットを行ないません。',13,10
	dc.b   '　  -FS   シフトキーが押されている場合のみフォーマットを行います。',13,10
	dc.b   '　  -V[n] ベリファイを行います。n=1で行います。省略時 1。',13,10
	dc.b   '　  -W[n] 書き込みを禁止します。n=1で禁止。省略時 1。',13,10
	dc.b   '　  -P    指定ドライブの状況を表示します。',13,10
	dc.b   '　  -R    登録を解除します。',13,10
	dc.b   '　  -N    登録時に FAT・-B,-T,-Gオプションの不都合による登録中止を無視します。',13,10
	dc.b   '　  -Y    Y/N チェックを常に Y にします。',13,10
	dc.b   '　  -H    登録時に Human のバージョンチェックを行いません。',13,10
	dc.b   '　  -A[n] TIMERランプをアクセスランプにします。n=1で行ないます。省略時 1。',13,10
	dc.b   '　  -D[n] 登録時にドライブタイプを指定します(0=GRAD,1=2HD,2=2HDE)。',13,10
	dc.b	0

title_mes::
	dc.b	13,10
	dc.b	'RAM DISK DRIVER 「ＧＲＡＤ．ｒ」 Copyright (C) 1990-94 GORRY.',13,10
	dc.b	' Version 1.30 : 94/11/15  Programmed by GORRY.'
CR::
	dc.b	13,10
	dc.b	0
GRAD_mes::
	dc.b	'GRAD:'
	dc.b	0

gram_use_mes::
	dc.b	'KBytes,G-RAM 512',0

新規登録_mes1::
常駐解除_mes1::
	dc.b	'　RAMDISK ('
drive_no_1::
drive_no_3::
	dc.b	'C:',0
新規登録_mes2::
	dc.b	'KBytes) を新規確保しました。',13,10,0

容量変更_mes1::
	dc.b	'　RAMDISK ('
drive_no_2::
	dc.b	'C:) の容量を ',0
容量変更_mes2::
	dc.b	'KBytes に変更しました。',13,10,0

常駐解除_mes2::
	dc.b	'KBytes)を解除しました。',13,10,0

ステータス_mes1::
	dc.b	' 【ドライブ ',$82
drive_no_4::
	dc.b	'a：】',0
ステータス_mes2::
	dc.b	'KBytes 使用しています。',13,10,0

フォーマット_mes1::
	dc.b	'　RAMDISK ('
drive_no_5::
	dc.b	'C:',0
フォーマット_mes2::
	dc.b	'KBytes) をフォーマットしました。',13,10,0
フォーマット_mes3::
	dc.b	'  ・フォーマットを行いました。',13,10,0
ベリファイ_mes1::
	dc.b	'  ・ベリファイを行います。',13,10,0
ベリファイ_mes2::
	dc.b	'  ・ベリファイを行いません。',13,10,0
書き込み禁止_mes1::
	dc.b	'  ・書き込み禁止です。',13,10,0
書き込み禁止_mes2::
	dc.b	'  ・書き込み可能です。',13,10,0
アクセスランプ_mes1::
	dc.b	'  ・TIMERランプをアクセスランプに使用します。',13,10,0
アクセスランプ_mes2::
	dc.b	'  ・TIMERランプをアクセスランプに使用しません。',13,10,0
前から_mes::
	dc.b	'《前から》$',0
後ろから_mes::
	dc.b	'《後ろから》$',0
ＦＡＴ表示_mes1::
	dc.b	'　・FAT は ',0
ＦＡＴ表示_mes2::
	dc.b	' セクターの分まで使用しています。',13,10,0
ＦＡＴ表示_mes3::
	dc.b	' 破壊されています。',13,10,0
ＦＡＴ表示_mes4::
	dc.b	' 使用されていません。',13,10,0
アボート_mes::
	dc.b	13,10,'  中止しました。',13,10,0
なんか変ぢゃ_mes::
	dc.b	'　内部で異常動作が発生しました。',13,10,0
warning_GRADenv_set_mes
	dc.b	ESC,'[47m環境変数領域が不足しています。一部環境を設定できませんでした。'
	dc.b	ESC,'[0m',7,13,10,0
GRADDRV_envname::
	dc.b	'GRADDRV',0
GRADDRV_env::
	dc.b	'A:',0
GRADSIZE_envname::
	dc.b	'GRADSIZE',0
GRADSIZE_env::
	dc.b	'4093',0
GRADMEM_envname::
	dc.b	'GRADMEM',0
GRADMEM_env::
	dc.b	'ffffff',0


	.even

DPB_TYPE::
		dc.w	DPB_TYPE0-DPB_TYPE
		dc.w	DPB_TYPE1-DPB_TYPE
		dc.w	DPB_TYPE2-DPB_TYPE

DPB_TYPE0::
		* GRAD
		dc.w	256		* 初期容量
		dc.w	4093		* 最大容量

		dc.b	0		*00.b	登録時のドライブ番号
		dc.b	0		*01.b	ユニット番号
		dc.l	0		*DEVICE_HEADER	*02.l	デバイスドライバのエントリアドレス
		dc.l	-1		*06.l	次のＤＰＢへのリンクポインタ（－１で終了）
		dc.w	＃sector_len	*0a.w	１セクタ当たりのバイト数（１０２４で固定）
		dc.b	1-1		*0c.b	１クラスタ当たりのセクタ数－１（０で固定）
		dc.b	0		*0d.b	先頭クラスタのセクタ番号
		dc.w	0		*0e.w	ＦＡＴ領域のセクタ番号
		dc.b	1		*10.b	ＦＡＴ領域の個数
		dc.b	6		*11.b	ＦＡＴに使用するセクタ数
		dc.w	96		*12.w	ルートディレクトリに作成できるファイル数
		dc.w	9		*14.w	データ領域の先頭セクタ番号
		dc.w	256-9+3		*16.w	全ディスク容量＋３
		dc.w	6		*18.w	ルートディレクトリ領域の先頭セクタ番号
		dc.b	$f9		*1a.b	メディアバイト
		dc.b	$0a		*1b.b	不明（$0aで固定）
		dc.w	$0002		*1c.w	不明（$0002で固定）

DPB_TYPE1::
		* 2HD
		dc.w	1232		* 初期容量
		dc.w	1369		* 最大容量

		dc.b	0		*00.b	登録時のドライブ番号
		dc.b	0		*01.b	ユニット番号
		dc.l	0		*DEVICE_HEADER	*02.l	デバイスドライバのエントリアドレス
		dc.l	-1		*06.l	次のＤＰＢへのリンクポインタ（－１で終了）
		dc.w	＃sector_len	*0a.w	１セクタ当たりのバイト数（１０２４で固定）
		dc.b	1-1		*0c.b	１クラスタ当たりのセクタ数－１（０で固定）
		dc.b	0		*0d.b	先頭クラスタのセクタ番号
		dc.w	1		*0e.w	ＦＡＴ領域のセクタ番号
		dc.b	2		*10.b	ＦＡＴ領域の個数
		dc.b	2		*11.b	ＦＡＴに使用するセクタ数
		dc.w	192		*12.w	ルートディレクトリに作成できるファイル数
		dc.w	11		*14.w	データ領域の先頭セクタ番号
		dc.w	1232-11+3	*16.w	全ディスク容量＋３
		dc.w	5		*18.w	ルートディレクトリ領域の先頭セクタ番号
		dc.b	$fe		*1a.b	メディアバイト
		dc.b	$0a		*1b.b	不明（$0aで固定）
		dc.w	$0002		*1c.w	不明（$0002で固定）

DPB_TYPE2::
		* 2HDE
		dc.w	1440		* 初期容量
		dc.w	2053		* 最大容量

		dc.b	0		*00.b	登録時のドライブ番号
		dc.b	0		*01.b	ユニット番号
		dc.l	0		*DEVICE_HEADER	*02.l	デバイスドライバのエントリアドレス
		dc.l	-1		*06.l	次のＤＰＢへのリンクポインタ（－１で終了）
		dc.w	＃sector_len	*0a.w	１セクタ当たりのバイト数（１０２４で固定）
		dc.b	1-1		*0c.b	１クラスタ当たりのセクタ数－１（０で固定）
		dc.b	0		*0d.b	先頭クラスタのセクタ番号
		dc.w	1		*0e.w	ＦＡＴ領域のセクタ番号
		dc.b	2		*10.b	ＦＡＴ領域の個数
		dc.b	3		*11.b	ＦＡＴに使用するセクタ数
		dc.w	192		*12.w	ルートディレクトリに作成できるファイル数
		dc.w	13		*14.w	データ領域の先頭セクタ番号
		dc.w	1440-13+3	*16.w	全ディスク容量＋３
		dc.w	7		*18.w	ルートディレクトリ領域の先頭セクタ番号
		dc.b	$f8		*1a.b	メディアバイト
		dc.b	$0a		*1b.b	不明（$0aで固定）
		dc.w	$0002		*1c.w	不明（$0002で固定）

*	最大容量計算方法
*	(($0a.w*$11.b-3-8)*2/3)+$14.w
*	ただし4093以上にはならない。


	.even

	.bss

BSS_START
	.offset	0
gram_used::	equ	BSS_START+$
		dc.w	0
mem_seted::	equ	BSS_START+$
		dc.w	0
format_seted::	equ	BSS_START+$
		dc.w	0
status_seted::	equ	BSS_START+$
		dc.w	0
release_seted::	equ	BSS_START+$
		dc.w	0
drive_seted::	equ	BSS_START+$
		dc.w	0
verify_seted::	equ	BSS_START+$
		dc.w	0
write_seted::	equ	BSS_START+$
		dc.w	0
mem_mode_seted::equ	BSS_START+$
		dc.w	0
force_install_seted::	equ	BSS_START+$
		dc.w	0
notver_seted::	equ	BSS_START+$
		dc.w	0
force_clear_seted::equ	BSS_START+$
		dc.w	0
AccessLamp_seted::equ	BSS_START+$
		dc.w	0

current_drive::	equ	BSS_START+$
		dc.w	0

keep_ssp::	equ	BSS_START+$
		dc.l	0

print_buffer::	equ	BSS_START+$
		ds.b	10

sysboot_switch::equ	BSS_START+$
		dc.w	0
MemSafeBufPtr::	equ	BSS_START+$
		ds.l	1
AssignInfoBuf::	equ	BSS_START+$
		ds.b	SizeOfAssignInfo

BSS_END::	equ	BSS_START+$
PEND::		equ	BSS_START+$

*/*/*/*/*/*/*/*/
	.end		PSTART


