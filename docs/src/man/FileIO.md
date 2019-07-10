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
cp("examples/Amp.s2p","docs/build/man/Amp.s2p", force = true) # hide
cp("examples/Short.s1p","docs/build/man/Short.s1p", force = true) # hide
nothing
```

```@example
using Marconi # hide
readTouchstone("BPF.s2p")
```

## Writing Touchstone Files
To save your work from Marconi, one can either work directly with the `frequency` and `s_params` from
a `DataNetwork` or save directly to a Touchstone file with `writeTouchstone`

```@example
using Marconi # hide
amp = readTouchstone("Amp.s2p")
bpf = readTouchstone("BPF.s2p")
system = cascade(bpf,amp)
writeTouchstone(system,"Cascade.s2p")
rm("Cascade.s2p") # hide
```

As of this version, Marconi will write the touchstone file in Hz with S-Parameters in Real/Imaginary
format as every software should in theory support all versions of the format. Format specifiers could
come in a future release.
