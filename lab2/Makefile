TARGET = matrix

all: $(TARGET)

$(TARGET): $(TARGET).o
	ld $(TARGET).o -o prog

$(TARGET).o: $(TARGET).asm
	nasm -f elf64 -g -F dwarf $(TARGET).asm -o $(TARGET).o

clean:
	rm -f $(TARGET).o $(TARGET) prog