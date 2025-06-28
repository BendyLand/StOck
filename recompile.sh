#!/bin/bash

cd odin-vm
odin build . &
ODIN_PS=$!
cd ..

cd go-parser
go build . &
GO_PS=$!
cd ..

wait $ODIN_PS $GO_PS
echo "VM and Parser recompiled successfully!"

