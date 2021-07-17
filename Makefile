CLANG  = clang

OUTPUTDIR = $(abspath ./output)

.PHONY: all
all: libbpf vmlinuxh


# libbpf

CC     = gcc
CFLAGS = -g -O2 -Werror -Wall -fpie

LIBBPFDIR      = $(abspath ./libbpf)
LIBBPFOBJ      = $(OUTPUTDIR)/libbpf.a
LIBBPFSRCDIR   = $(LIBBPFDIR)/src
LIBBPFSRCFILES = $(wildcard $(LIBBPFSRCDIR)/*.[ch])
LIBBPFDESTDIR  = $(OUTPUTDIR)
LIBBPFOBJDIR   = $(LIBBPFDESTDIR)/libbpf

.PHONY: libbpf
libbpf: $(LIBBPFOBJ)

$(LIBBPFOBJ): $(LIBBPFSRCFILES) # | $(OUTPUTDIR)
	CC="$(CC)" CFLAGS="$(CFLAGS)" \
	$(MAKE) -C $(LIBBPFSRCDIR) \
		BUILD_STATIC_ONLY=1 \
		OBJDIR=$(LIBBPFOBJDIR) \
		DESTDIR=$(LIBBPFDESTDIR) \
		INCLUDEDIR= LIBDIR= UAPIDIR= \
		install


# vmlinux header file

BTFFILE  = /sys/kernel/btf/vmlinux
BPFTOOL  = $(shell which bpftool)
VMLINUXH = $(OUTPUTDIR)/vmlinux.h

.PHONY: vmlinuxh
vmlinuxh: $(VMLINUXH)

$(VMLINUXH): $(OUTPUTDIR)
	@if [ ! -f $(BTFFILE) ]; then \
		echo "ERROR: kernel does not seem to support BTF"; \
		exit 1; \
	fi
	@if [ ! -f $(VMLINUXH) ]; then \
		echo "INFO: generating $(VMLINUXH) from $(BTFFILE)"; \
		$(BPFTOOL) btf dump file $(BTFFILE) format c > $(VMLINUXH); \
	fi

# output

$(OUTPUTDIR):
	mkdir -p $(OUTPUTDIR)


# cleanup

clean:
	rm -rf $(OUTPUTDIR)