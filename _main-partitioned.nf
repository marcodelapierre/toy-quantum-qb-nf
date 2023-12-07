#!/usr/bin/env nextflow
nextflow.enable.dsl=2
import groovy.json.JsonSlurper


params.N_PHYSICAL_QUBITS = 2
params.QRISTAL_ACC = "aer"

params.N_ASYNC_THREADS = 2
params.N_SHOTS = 512
params.N_PROCESSES = 4

def jsonSlurper = new JsonSlurper()


process partitionCircuitQubitBackend {
    debug false
    input:
        path circuit
        each shots_N

    output:
       stdout

    """
    #!/usr/bin/env python3

    import ast
    import json
    import numpy as np
    import time
    import qb.core
    tqb = qb.core.session()
    tqb.qb12()

    tqb.qn = ${params.N_PHYSICAL_QUBITS}  # Number of qubits
    tqb.infile = "$circuit"

    tqb.noplacement = True
    tqb.nooptimise = True
    tqb.notiming = True
    tqb.output_oqm_enabled = False

    NW = ${params.N_ASYNC_THREADS}  # number of async workers
    SLEEP_SECONDS = 0.1 # seconds to sleep between progress
    ALG_UNDER_TEST = 0

    # Set up workers
    # Set up the pool of backends for parallel task distribution
    qpu_config = {"accs": NW*[{"acc": "${params.QRISTAL_ACC}"}]}
    tqb.set_parallel_run_config(json.dumps(qpu_config))

    # Set the number of threads to use in the thread pool
    tqb.num_threads = NW

    # Set up jobs that partition the requested number of shots
    tqb.sn[ALG_UNDER_TEST].clear()
    for jj in range(NW):
        tqb.sn[ALG_UNDER_TEST].append($shots_N // NW)

    handles = []
    for i in range(NW):
        handles.append(tqb.run_async(ALG_UNDER_TEST, i))
        time.sleep(0.001)

    # Gather the results
    allres = {}
    componentres = [ast.literal_eval(handles[i].get()) for i in range(NW)]
    for ii in range(NW):
        allres = {k: allres.get(k,0) + componentres[ii].get(k,0) for k in set(allres) | set(componentres[ii])}

    # View the results
    print(json.dumps(allres))

    # Store the settings
    save_js = {}
    save_js['shots'] = $shots_N
    save_js['backend'] = "${params.QRISTAL_ACC}"
    save_js['workers'] = ${params.N_ASYNC_THREADS}
    save_js['circuit'] = "$circuit"
    save_js['qubits'] = ${params.N_PHYSICAL_QUBITS}
    with open('settings.json', 'w') as f:
        json.dump(save_js, f)
    """
}


def gatherall = [:]

workflow {
  circuit_ch = Channel.fromPath("*.oqm")
  shots_N_ch = (0..<params.N_PROCESSES).collect { params.N_SHOTS/params.N_PROCESSES }
  shotoutcomes_ch = partitionCircuitQubitBackend(circuit_ch, shots_N_ch).map { jsonSlurper.parseText( it ) }
  (shotoutcomes_ch.map { gatherall = (gatherall.keySet() + it.keySet()).collectEntries { k -> [k, (gatherall[k] ?: 0) + (it[k] ?: 0)] } }).last().view()
}
