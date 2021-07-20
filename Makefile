OUTPUTDIR = ./output

.PHONY: all
all: libbpf vmlinuxh bpfobj bpfman


# libbpf

CC     = gcc
CFLAGS = -g -O2 -Werror -Wall -fpie

GIT            = $(shell which git)
LIBBPFDIR      = $(abspath ./libbpf)
LIBBPFOBJ      = $(OUTPUTDIR)/libbpf.a
LIBBPFSRCDIR   = $(LIBBPFDIR)/src
LIBBPFSRCFILES = $(wildcard $(LIBBPFSRCDIR)/*.[ch])
LIBBPFDESTDIR  = $(abspath $(OUTPUTDIR))
LIBBPFOBJDIR   = $(LIBBPFDESTDIR)/libbpf

.PHONY: libbpf
libbpf: $(LIBBPFOBJ)

$(LIBBPFOBJ): $(LIBBPFSRCDIR) $(LIBBPFSRCFILES) | $(OUTPUTDIR)
	$(info INFO: compiling $@)
	@CC="$(CC)" CFLAGS="$(CFLAGS)" \
	$(MAKE) -C $(LIBBPFSRCDIR) \
		BUILD_STATIC_ONLY=1 \
		OBJDIR=$(LIBBPFOBJDIR) \
		DESTDIR=$(LIBBPFDESTDIR) \
		INCLUDEDIR= LIBDIR= UAPIDIR= \
		install


$(LIBBPFSRCDIR):
ifeq ($(wildcard $@), )
	$(info INFO: updating submodule 'libbpf')
	@$(GIT) submodule update --init --recursive
endif


# vmlinux header file

BPFTOOL  = $(shell which bpftool)
BTFFILE  = /sys/kernel/btf/vmlinux
VMLINUXH = $(OUTPUTDIR)/vmlinux.h

.PHONY: vmlinuxh
vmlinuxh: $(VMLINUXH)

$(VMLINUXH): $(BTFFILE) | $(OUTPUTDIR)
	$(info INFO: generating $@ from $<)
	@$(BPFTOOL) btf dump file $< format c > $@;

$(BTFFILE):
ifeq ($(wildcard $@), )
	$(error ERROR: kernel does not seem to support BTF)
endif


# bpf objects

CLANG      = clang
CLANGFLAGS = -g -O2 -c -target bpf
CLANGINC   = $(OUTPUTDIR)
BPFOBJDIR  = $(OUTPUTDIR)
BPFS_C     = $(wildcard *.bpf.c)
BPFS_O     = $(addprefix $(BPFOBJDIR)/, $(BPFS_C:.c=.o))

.PHONY: bpfobj
bpfobj: libbpf vmlinuxh $(BPFS_O)

$(BPFOBJDIR)/%.o: %.c | $(BPFOBJDIR)
	$(info INFO: compiling bpf object $@)
	@$(CLANG) $(CLANGFLAGS) -I $(CLANGINC) -o $@ $<


# bpf management

BPFMANSRC   = $(BPFS_C:.bpf.c=.go)
BPFMAN      = $(addprefix $(OUTPUTDIR)/, $(BPFMANSRC:.go=))
CGO_CFLAGS  = -I $(OUTPUTDIR)/bpf
CGO_LDFLAGS = $(OUTPUTDIR)/libbpf.a

.PHONY: bpfman
bpfman: bpfobj $(BPFMAN)

$(BPFMAN): $(BPFMANSRC)
	$(info INFO: compiling bpf management $@)
	@go mod tidy
	@CC=gcc CGO_CFLAGS="$(CGO_CFLAGS)" CGO_LDFLAGS="$(CGO_LDFLAGS)" \
		go build -o $@ $<


# output

$(OUTPUTDIR):
	@mkdir -p $@


# cleanup

clean:
	rm -rf $(OUTPUTDIR)
