#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.svdcutoff = '0.1,0.01,0.001,0.0001,0.00001'

process sweepSvdCutoff {
    debug false
    input:
        val svdcutoff

    output:
        stdout

    """
    #!/usr/bin/env python3

    import qb.core
    import numpy as np

    tqb = qb.core.session()
    tqb.qb12()
    tqb.qn = 2     # Number of qubits
    tqb.sn = 1024  # Number of shots
    tqb.acc = "tnqvm"
    tqb.noplacement = True
    tqb.nooptimise = True
    tqb.notiming = True
    tqb.output_oqm_enabled = False
    tqb.svd_cutoff[0][0][0] = ${svdcutoff}
    tqb.instring = '''

    __qpu__ void QBCIRCUIT(qreg q) {
    OPENQASM 2.0;
    include "qelib1.inc";
    creg c[2];
    h q[0];
    cx q[0],q[1];
    measure q[1] -> c[1];
    measure q[0] -> c[0];
    }

    '''

    tqb.run()
    print("SVD cutoff: ", tqb.svd_cutoff[0][0][0])
    print(tqb.out_raw[0][0])
    """
}

workflow {
    input = Channel.fromList( params.svdcutoff.tokenize(',') )

    input | sweepSvdCutoff | view
}
