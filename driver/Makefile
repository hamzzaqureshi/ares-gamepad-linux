obj-m := xpad.o

KVERSION ?= $(shell uname -r)
KDIR     ?= /lib/modules/$(KVERSION)/build
PWD      := $(CURDIR)

# Auto-detect Clang/LLVM kernels (e.g. CachyOS) vs GCC
ifeq ($(shell grep -qi "clang" /proc/version 2>/dev/null && echo 1),1)
LLVM ?= 1
export LLVM
endif

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	-$(MAKE) -C $(KDIR) M=$(PWD) clean 2>/dev/null || true
	rm -f *.o *.ko *.mod *.mod.c .*.cmd *.zst modules.order Module.symvers

install: all
	install -d /lib/modules/$(KVERSION)/updates
	install -m 644 xpad.ko /lib/modules/$(KVERSION)/updates/
	depmod -a $(KVERSION)

.PHONY: all clean install
