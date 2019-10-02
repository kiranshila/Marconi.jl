#!/bin/bash

# Julia version
JULIAVER=$1
JULIABIN=/test/julia-$JULIAVER/bin/julia
TESTCMD=xvfb-run $JULIABIN

## install the image (when necessary)
/test/install-julia.sh $JULIAVER

cd /mnt && if [[ -a .git/shallow ]]; then git fetch --unshallow; fi

# run tests
$TESTCMD --color=yes -e "import Pkg; Pkg.build(); Pkg.test(; coverage=true)"
chmod 777 Manifest.toml
