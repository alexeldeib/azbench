# azbench

This repo provides a basic benchmarking setup using pgbench on Kubernetes clusters.

pgbench on Azure Standard_D8s_v3 with P30 SSD (5k IOPS), no IO scheduler, OS Disk workload, bench2 job
```
scaling factor: 2160
query mode: simple
number of clients: 16
number of threads: 8
duration: 120 s
number of transactions actually processed: 20319
latency average = 94.501 ms
tps = 169.310981 (including connections establishing)
tps = 169.369530 (excluding connections establishing)
```

pgbench on Azure Standard_D8s_v3 with P30 SSD (5k IOPS), no IO scheduler, OS Disk workload, bench2 job
```
scaling factor: 2160
query mode: simple
number of clients: 16
number of threads: 8
duration: 120 s
number of transactions actually processed: 123460
latency average = 15.552 ms
tps = 1028.789614 (including connections establishing)
tps = 1028.926825 (excluding connections establishing)
```