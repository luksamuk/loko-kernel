LOKO        := /usr/local/bin/loko
LOKO_SOURCE := /usr/local/lib/loko

PROGRAM     := bin/kernel.bin
LIBS        := lib/kmem.sls lib/stdlib.sls lib/vga.sls lib/keyboard.sls

.PHONY: run clean dirs

all: dirs $(PROGRAM)

dirs:
	mkdir -p bin/

$(PROGRAM): kmain.sps $(LIBS)
	LOKO_SOURCE=$(LOKO_SOURCE) \
	$(LOKO) -ftarget=pc -feval --compile kmain.sps --output $@

run: $(PROGRAM)
	qemu-system-x86_64 -enable-kvm \
	-kernel $(PROGRAM) \
	-m 1024 \
	-serial stdio \
	-debugcon vc

clean:
	rm $(PROGRAM)
