#	makefile for GRAD,GRADLOADER
#	by GORRY.
#

.SUFFIXES:

AS		=	has
LD		=	hlk

ASFLAGS		=	-w -z /a 
LDFLAGS		=	


CV		=	cv
ASP		=	asp
AR		=	lha
FIN		=	ntf

CVFLAGS		=	
ASPFLAGS	=	
ARFLAGS		=	a
FINFLAGS	=	-t -kl 2


program1	=	GRAD
program2	=	GRADLOADER
program3	=	GSTOP

target1		=	$(addsuffix .r,$(program1))
target2		=	$(addsuffix .x,$(program2))
target3		=	$(addsuffix .r,$(program3))

source1		=	$(addsuffix .asp,$(program1))
source2		=	$(addsuffix .asp,$(program2))
source3		=	$(addsuffix .asp,$(program3))




.default:x


.phony:x

x	:	$(target1) $(target2) $(target3)

$(target1)	:	$(source1)
	$(ASP) $(source1) $(program1)
	$(AS) $(ASFLAGS) $(program1) > err.err
	$(LD) $(program1)
	$(CV) $(program1)
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




all		:	x arc doc


