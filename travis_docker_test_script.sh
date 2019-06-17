#!/bin/bash

# Julia version
JULIAVER=$1
JULIABIN=/test/julia-$JULIAVER/bin/julia

## install the image (when necessary)
/test/install-julia.sh $JULIAVER

cd /mnt && if [[ -a .git/shallow ]]; then git fetch --unshallow; fi

# run tests
sudo chmod 777 Manifest.toml
ls -las
$JULIABIN -e "import Pkg; Pkg.build(); Pkg.test(; coverage=true)"
