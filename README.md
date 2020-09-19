# azbench

This repo provides a basic benchmarking setup using pgbench on Kubernetes clusters.

## What it does

### variables
- OS disk type: managed vs ephemeral
- VM size: D4s_v3, D16s_v3, and D64s_v3
- Workload disk type: OS disk, data disk, or local (nvme/temp).
- io scheduler: none, mq-deadline.
- (can't be tested in AKS) host disk caching
- scale factor

### outputs
- pgbench synthetic tps
- latency average per transation
- flamegraph of postgresql during test run (TODO)
- pgio output tar (iostat/vmstat/mpstat?)

### mechanics

Each test run provisions an AKS cluster with a small system pool and
adds a user pool to run workloads. If we need to perform any node tuning
for a given run, we perform it when the cluster and nodepool are ready.
If we applied any tests we need to wait for each pod in the nsenter
daemonset to have 1 restart and be running.  After that, the pipeline
applies postgresql and waits for it to be ready. Next we apply the
workload (pgio or pgbench currently).

We tail the logs of the workload pod every few seconds, waiting to find
log lines indicating the results are ready. If we expect to exfiltrate
result artifacts from this run we can exec them now using magic wormhole
(using the code in the logs).

After exfiltrating any required metrics, we can process them client side
in AzDevOps (either bash or go/rust). When there we should start a
docker container with metrics extension, and send the results to the
backend data store using statsd format. We should download any
credentials to do this at the beginning of the run to fail fast if
appropriate.

## Test runs

### Standard_D4s_v3, 2TB (P40) managed data disk.
### Standard_D4s_v3, 2TB (P40) managed OS disk workload.

This VM SKU and disk SKU are fairly even in terms of IOPS (6400 vs 7500,
respectively), but the disk has much higher throughput (96 vs 250 MBps).
When we enable ephemeral OS, disk locality might improve performance but
we should not see improvements due to IOPS/throughput. Not sure how much
improvment we might get from scheduler changes.

#### noop scheduler

bench 1
```
scaling factor: 120
query mode: prepared
number of clients: 4
number of threads: 2
duration: 120 s
number of transactions actually processed: 67083
latency average = 7.210 ms
tps = 554.763001 (including connections establishing)
tps = 554.827463 (excluding connections establishing)
```

bench 2
```
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1080
query mode: prepared
number of clients: 4
number of threads: 2
duration: 120 s
number of transactions actually processed: 64832
latency average = 7.404 ms
tps = 540.247231 (including connections establishing)
tps = 546.052536 (excluding connections establishing)
```

bench 3
```
scaling factor: 4800
query mode: prepared
number of clients: 4
number of threads: 2
duration: 120 s
number of transactions actually processed: 64256
latency average = 7.473 ms
tps = 535.267102 (including connections establishing)
tps = 535.346898 (excluding connections establishing)
```

#### mq-deadline

bench 1
```
scaling factor: 120
query mode: prepared
number of clients: 4
number of threads: 2
duration: 120 s
number of transactions actually processed: 74963
latency average = 6.403 ms
tps = 624.668903 (including connections establishing)
tps = 624.838723 (excluding connections establishing)
```

bench 2
```
scaling factor: 1080
query mode: prepared
number of clients: 4
number of threads: 2
duration: 120 s
number of transactions actually processed: 71002
latency average = 6.761 ms
tps = 591.640199 (including connections establishing)
tps = 591.760748 (excluding connections establishing)
```

bench 3
```
scaling factor: 4800
query mode: prepared
number of clients: 4
number of threads: 2
duration: 120 s
number of transactions actually processed: 64276
latency average = 7.469 ms
tps = 535.575853 (including connections establishing)
tps = 535.650729 (excluding connections establishing)
```

### Standard_D4s_v3, 100 GB ephemeral OS disk workload.

#### noop scheduler

bench 1
```
scaling factor: 120
query mode: prepared
number of clients: 4
number of threads: 2
duration: 120 s
number of transactions actually processed: 116653
latency average = 4.115 ms
tps = 972.084629 (including connections establishing)
tps = 982.457925 (excluding connections establishing)
```

bench 2
```
scaling factor: 1080
scaling factor: 1080
query mode: prepared
number of clients: 4
number of threads: 2
duration: 120 s
number of transactions actually processed: 110176
latency average = 4.357 ms
tps = 918.105121 (including connections establishing)
tps = 918.240023 (excluding connections establishing)
```

bench 3
```
scaling factor: 4800
query mode: prepared
number of clients: 4
number of threads: 2
duration: 120 s
number of transactions actually processed: 96088
latency average = 4.996 ms
tps = 800.702109 (including connections establishing)
tps = 800.826102 (excluding connections establishing)
```

### Standard_D64s_v3, 2TB managed OS disk workload.

### Standard_D64s_v3, 1.5TB ephemeral OS disk workload.

This is a very large VM size, with ephemeral OS we should expect to have
all VM IOPS available. We may not see much difference here since there
is no resource pressure.

#### noop scheduler

bench2
```
scaling factor: 1920
query mode: prepared
number of clients: 32
number of threads: 16
duration: 120 s
number of transactions actually processed: 734770
latency average = 5.227 ms
tps = 6122.303554 (including connections establishing)
tps = 6123.461290 (excluding connections establishing)


scaling factor: 17280
query mode: prepared
number of clients: 32
number of threads: 16
duration: 600 s
number of transactions actually processed: 3758465
latency average = 5.109 ms
tps = 6264.065334 (including connections establishing)
tps = 6264.333491 (excluding connections establishing)
```

#### mq-deadline scheduler

bench1
```
scaling factor: 1920
query mode: prepared
number of clients: 32
number of threads: 16
duration: 120 s
number of transactions actually processed: 740760
latency average = 5.184 ms
tps = 6172.844743 (including connections establishing)
tps = 6173.959172 (excluding connections establishing)
```

bench2
```
scaling factor: 17280
query mode: prepared
number of clients: 32
number of threads: 16
duration: 120 s
number of transactions actually processed: 754765
latency average = 5.088 ms
tps = 6289.496557 (including connections establishing)
tps = 6290.728039 (excluding connections establishing)
```
