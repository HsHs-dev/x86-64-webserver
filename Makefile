AS := as
LD := ld
ASFLAGS := --64
LDFLAGS :=

TARGET := server
SRCS := main.s network.s io.s req_handler.s
OBJS := $(SRCS:.s=.o)

# Define your server's port here so it's easy to change later
PORT := 80

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

run: $(TARGET)
	@echo "🚀 Server running on http://127.0.0.1:$(PORT)"
	@# Waits 0.5 seconds in the background for the server to spin up, then opens the browser
	@(sleep 0.5 && xdg-open http://localhost:$(PORT)) &
	./$(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)
