AS := as
LD := ld
ASFLAGS := --64
LDFLAGS :=

TARGET := server
SRCS := main.s network.s io.s req_handler.s
OBJS := $(SRCS:.s=.o)

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)
