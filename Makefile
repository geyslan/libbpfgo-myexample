CLANG  = clang

OUTPUTDIR = ./output

.PHONY: all
all: libbpf vmlinuxh


# libbpf

CC     = gcc
CFLAGS = -g -O2 -Werror -Wall -fpie

LIBBPFDIR      = $(abspath ./libbpf)
LIBBPFOBJ      = $(abspath $(OUTPUTDIR)/libbpf.a)
LIBBPFSRCDIR   = $(LIBBPFDIR)/src
LIBBPFSRCFILES = $(wildcard $(LIBBPFSRCDIR)/*.[ch])
LIBBPFDESTDIR  = $(abspath $(OUTPUTDIR))
LIBBPFOBJDIR   = $(LIBBPFDESTDIR)/libbpf

.PHONY: libbpf
libbpf: $(LIBBPFOBJ)

$(LIBBPFOBJ): $(LIBBPFSRCFILES) | $(OUTPUTDIR)
	CC="$(CC)" CFLAGS="$(CFLAGS)" \
	$(MAKE) -C $(LIBBPFSRCDIR) \
		BUILD_STATIC_ONLY=1 \
		OBJDIR=$(LIBBPFOBJDIR) \
		DESTDIR=$(LIBBPFDESTDIR) \
		INCLUDEDIR= LIBDIR= UAPIDIR= \
		install


# vmlinux header file

BPFTOOL  = $(shell which bpftool)
BTFFILE  = /sys/kernel/btf/vmlinux
VMLINUXH = $(OUTPUTDIR)/vmlinux.h

.PHONY: vmlinuxh
vmlinuxh: $(VMLINUXH)

$(VMLINUXH): $(BTFFILE) | $(OUTPUTDIR)
	@echo "INFO: generating $@ from $<";
	$(BPFTOOL) btf dump file $< format c > $@;

$(BTFFILE):
	@if [ ! -f $(BTFFILE) ]; then \
		echo "ERROR: kernel does not seem to support BTF"; \
		exit 1; \
	fi


# output

$(OUTPUTDIR):
	mkdir -p $(OUTPUTDIR)


# cleanup

clean:
	rm -rf $(OUTPUTDIR)