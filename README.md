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

pgbench on Azure Standard_D8s_v3 with P30 SSD (5k IOPS), no IO scheduler, OS Disk workload, bench3 job
```
scaling factor: 1000
query mode: simple
number of clients: 8
number of threads: 4
duration: 120 s
number of transactions actually processed: 100779
latency average = 9.526 ms
tps = 839.795426 (including connections establishing)
tps = 839.892167 (excluding connections establishing)

scaling factor: 2160
query mode: prepared
number of clients: 8
number of threads: 4
duration: 120 s
number of transactions actually processed: 100303
latency average = 9.572 ms
tps = 835.812172 (including connections establishing)
tps = 835.969773 (excluding connections establishing)
```

pgbench on Azure Standard_D8s_v3 with P30 SSD (5k IOPS), mq-deadline, OS Disk workload, bench2 job
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

pgbench on Azure Standard_D8s_v3 with P30 SSD (5k IOPS), mq-deadline, OS Disk workload, bench3 job
```
scaling factor: 1000
query mode: simple
number of clients: 8
number of threads: 4
duration: 120 s
number of transactions actually processed: 103507
latency average = 9.275 ms
tps = 862.525737 (including connections establishing)
tps = 862.713411 (excluding connections establishing)

scaling factor: 2160
query mode: prepared
number of clients: 8
number of threads: 4
duration: 120 s
number of transactions actually processed: 103223
latency average = 9.301 ms
tps = 860.153806 (including connections establishing)
tps = 860.315906 (excluding connections establishing)
```