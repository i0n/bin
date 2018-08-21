#!/bin/sh

set -e

# Required for deoplete-go
go get -u github.com/nsf/gocode

go get -u github.com/alecthomas/gometalinter

go get -u honnef.co/go/tools/...
# gosimple
# keyify
# rdeps
# staticcheck
# structlayout
# structlayout-optimize
# structlayout-pretty
# unused
# megacheck

go get -u golang.org/x/tools/cmd/gotype

go get -u github.com/cweill/gotests/...
