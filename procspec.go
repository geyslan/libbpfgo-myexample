package main

import (
	"C"
	"fmt"
	"os"

	bpf "github.com/aquasecurity/tracee/libbpfgo"
)

func main() {

	bpfModule, err := bpf.NewModuleFromFile("procspec.bpf.o")
	if err != nil {
		os.Exit(-1)
	}
	defer bpfModule.Close()

	bpfModule.BPFLoadObject()
	bpfMap, err := bpfModule.GetMap("proc_spec")
	if err != nil {
		os.Exit(-1)
	}
	fmt.Println(bpfMap.GetMaxEntries())

	bpfMap.Unpin("/sys/fs/bpf/proc_spec")
}
