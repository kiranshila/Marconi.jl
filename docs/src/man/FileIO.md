# File IO

```@contents
Pages = ["FileIO.md"]
Depth = 3
```

## Reading Touchstone Files

One of the easiest ways to get measured data into `Marconi` is with Touchstone files.

These files follow the standard enumerated [here](http://na.support.keysight.com/plts/help/WebHelp/FilePrint/SnP_File_Format.htm) - a typical output format from simulation
software and network analyzers.

!!! note

    `Marconi` currently doesn't support port impedance mapping (different port impedances) or noise parameters.

Reading these files into a `Network` object is straightforward

```@eval
cd("../../..")
cp("examples/BPF.s2p","docs/build/man/BPF.s2p",force = true)
nothing
```

```@example
using Marconi # hide
readTouchstone("BPF.s2p")
```
