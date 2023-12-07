## Toy pipeline to run Quantum Computing simulations using Qristal by Quantum Brilliance

This pipeline reproduces the examples reported in the [Qristal documentation](https://qristal.readthedocs.io/en/latest/rst/nextflow.html).

Qristal is preferably deployed using containers, so by default the Docker container runtime is required to run this pipeline.

Give it a go with the parameter sweep example (SVD cut-off):
```
nextflow run marcodelapierre/toy-quantum-qb-nf
```

Custom SVD cut-off values can be provided, using the `svdcutoff` input parameter and a comma separated list (no spaces):
```
nextflow run marcodelapierre/toy-quantum-qb-nf --svdcutoff=0.01,0.001
```

The second example is still a WORK IN PROGRESS. Hold on :-)
