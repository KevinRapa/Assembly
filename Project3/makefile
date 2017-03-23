# Leave the following lines alone!!!

LDFLAGS=-melf_i386
%.o: %.asm
        nasm -f elf -l $*.lst $< -o $@

#
# End of provided rules
#

# Modify following to the name of your linked program
TARGET=main3.out

# Modify following to the list of component object files
OBJS=main3.o prt_dec.o

#
# Do not modify remainder of this Makefile
#
${TARGET}: ${OBJS}
        ${LD} ${LDFLAGS} ${OBJS} -o ${TARGET}
