#	makefile for GRAD,GRADLOADER
#	by GORRY.
#	modified by TcbnErik
#

.SUFFIXES:

SRCDIR_MK = ../srcdir.mk
SRC_DIR = ../src
-include $(SRCDIR_MK)

AS		=	has060
ifndef LD
LD		=	hlk
endif
ifeq ($(findstring hlkx,$(LD)),hlkx)
USE_HLKX = true
endif

ASFLAGS		=	-w
LDFLAGS		=	


CV		=	cv
ASP		=	asp.r
AR		=	lha
FIN		=	ntf

CVFLAGS		=	
ASPFLAGS	=	
ARFLAGS		=	a
FINFLAGS	=	-t -kl 2

U8TOSJ		=	u8tosj
CP_P		=	cp -p
EXTRACT_LHA	=	lx -i
ZIP		=	zip -9

GRAD130_LZH	=	GRAD130.LZH
SRC_ZIP		=	src.zip
GRADX_ZIP	=	gradx.zip

program1	=	grad
program2	=	GRADLOADER
program3	=	GSTOP

target1		=	$(addsuffix .r,$(program1))
target2		=	$(addsuffix .x,$(program2))
target3		=	$(addsuffix .r,$(program3))

source1		=	$(addsuffix .asp,$(program1))
source2		=	$(addsuffix .asp,$(program2))
source3		=	$(addsuffix .asp,$(program3))







.phony: x archive
all: grad.r

x	:	$(target1) $(target2) $(target3)


$(GRAD130_LZH):
	$(CP_P) $(SRC_DIR)/../archives/$(GRAD130_LZH) $@

$(ASP): $(GRAD130_LZH)
	$(EXTRACT_LHA) $(GRAD130_LZH) source.Lzh
	$(EXTRACT_LHA) source.Lzh $@
	touch $@
	rm source.Lzh


$(target1)	:	$(ASP) $(source1)
	./$(ASP) $(source1) $(program1).s
	$(AS) $(ASFLAGS) -o$(program1).o $(program1).s
ifdef USE_HLKX
	$(LD) $(LDFLAGS) -r -o$@ $(program1).o
else
	$(LD) $(LDFLAGS) -o$(program1).x $(program1).o
	$(CV) $(program1).x
endif

$(target2)	:	$(source2)
	$(ASP) $(source2) $(program2)
	$(AS) $(ASFLAGS) $(program2) > err.err
	$(LD) $(program2)
$(target3)	:	$(source3)
	$(ASP) $(source3) $(program3)
	$(AS) $(ASFLAGS) $(program3) > err.err
	$(LD) $(program3)
	$(CV) $(program3)




.phony:arc
.phony:doc


arcfile		=	GRAD130.Lzh
ASPDIR		=	

fin1		=	$(addsuffix .ntf,$(program1))
fin2		=	$(addsuffix .ntf,$(program2))
fin3		=	$(addsuffix .ntf,$(program3))

doc1		=	$(addsuffix .doc,$(program1))
doc2		=	$(addsuffix .doc,$(program2))
doc3		=	$(addsuffix .doc,$(program3))


arc	:	$(arcfile)

$(arcfile)	:	$(target1) $(doc1)
$(arcfile)	:	$(target2) $(doc2)
$(arcfile)	:	$(target3) $(doc3)
$(arcfile)	:	GRADFIRST.BAT
$(arcfile)	:	使用許諾規定.DOC source.Lzh
	$(AR) $(ARFLAGS) $@ $?


source.Lzh	:	$(source1) $(source2) $(source3) makefile $(addprefix $(ASPDIR),$(ASP)).r
	$(AR) $(ARFLAGS) $@ $?


doc		:	$(doc1) $(doc2) $(doc3)

$(doc1)		:	$(fin1)
	$(FIN) $(FINFLAGS) $^ > $@
$(doc2)		:	$(fin2)
	$(FIN) $(FINFLAGS) $^ > $@
$(doc3)		:	$(fin3)
	$(FIN) $(FINFLAGS) $^ > $@


archive: $(GRADX_ZIP)

$(GRADX_ZIP): $(GRAD130_LZH) $(SRC_ZIP) $(target1) CHANGELOG.txt README.txt
	rm -f $@
	$(ZIP) $@ $^

$(SRC_ZIP): $(source1) Makefile
	rm -f $@
	$(ZIP) $@ $^

CHANGELOG.txt: $(SRC_DIR)/../CHANGELOG.md
	$(U8TOSJ) < $^ >! $@

README.txt: $(SRC_DIR)/../README.md
	$(U8TOSJ) < $^ >! $@


