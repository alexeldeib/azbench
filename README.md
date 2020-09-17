# azbench

This repo provides a basic benchmarking setup using pgbench on Kubernetes clusters.

## Standard_D64s_v3, 1.5TB ephemeral OS disk workload.

### noop scheduler

#### bench2

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

### mq-deadline scheduler

#### bench1
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

#### bench2
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