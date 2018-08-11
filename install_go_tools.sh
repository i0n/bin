#!/bin/sh

set -e

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
