package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
)

func main() {
	parserCmd := exec.Command("./go-parser/parser")
	var buf bytes.Buffer
	parserCmd.Stdout = &buf // capture parser output
	if err := parserCmd.Run(); err != nil {
		log.Fatalf("parser failed: %v\n", err)
	}
	vmCmd := exec.Command("./odin-vm/odin-vm")
	vmIn, err := vmCmd.StdinPipe()
	if err != nil {
		log.Fatalf("Unable to connect Stdin: %v\n", err)
	}
	var vmOut bytes.Buffer
	vmCmd.Stdout = &vmOut
	vmCmd.Stderr = os.Stderr
	if err := vmCmd.Start(); err != nil {
		log.Fatalf("vm start failed: %v\n", err)
	}
	_, err = io.Copy(vmIn, &buf)
	if err != nil {
		log.Fatalf("copy error: %v\n", err)
	}
	vmIn.Close()
	if err := vmCmd.Wait(); err != nil {
		log.Printf("vm exited with error: %v\n", err)
	}
	fmt.Println("VM Output:\n" + vmOut.String())
}

