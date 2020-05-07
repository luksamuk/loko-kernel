LOKO        := /usr/local/bin/loko
LOKO_SOURCE := /usr/local/lib/loko

PROGRAM     := bin/kernel.bin

.PHONY: run clean dirs

all: dirs $(PROGRAM)

dirs:
	mkdir -p bin/

$(PROGRAM): kmain.sps
	LOKO_SOURCE=$(LOKO_SOURCE) \
	$(LOKO) -ftarget=pc -feval --compile $< --output $@

run: $(PROGRAM)
	qemu-system-x86_64 -enable-kvm \
	-kernel $(PROGRAM) \
	-m 1024 \
	-serial stdio \
	-debugcon vc

clean:
	rm $(PROGRAM)
