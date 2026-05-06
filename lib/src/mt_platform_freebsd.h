/* SPDX-License-Identifier: BSD-3-Clause
 * Copyright(c) 2022 Intel Corporation
 */

#ifndef _MT_PLATFORM_FREEBSD_H_
#define _MT_PLATFORM_FREEBSD_H_

#ifdef __FreeBSD__

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/shm.h>           /* For shmget/shmat/shmctl/shmdt */
#include <sys/endian.h>        /* FreeBSD's endian.h */
#include <arpa/inet.h>         /* For inet_addr, htonl, etc. */
#include <net/if.h>
#include <net/ethernet.h>      /* struct ether_header, replaces net/if_arp.h */
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <pthread.h>
#include <poll.h>
#include <time.h>

/* FreeBSD uses CLOCK_MONOTONIC_FAST for low-overhead monotonic time */
#ifdef CLOCK_MONOTONIC_FAST
#define MT_CLOCK_MONOTONIC_ID CLOCK_MONOTONIC_FAST
#else
#define MT_CLOCK_MONOTONIC_ID CLOCK_MONOTONIC
#endif

/* FreeBSD's pthread_setaffinity_np uses cpuset_t */
#include <sys/cpuset.h>
#include <sys/param.h>

/* FreeBSD uses pthread_cond_timedwait with CLOCK_REALTIME by default */
#define MT_THREAD_TIMEDWAIT_CLOCK_ID CLOCK_REALTIME

/* Temp file paths */
#define MT_FLOCK_PATH "/tmp/kahawai_lcore.lock"

/* Enable process-shared mutexes/condvars */
#define MT_ENABLE_P_SHARED

/* SIMD support - FreeBSD has same x86 intrinsics as Linux */
#ifdef MTL_HAS_AVX512
#include <immintrin.h>
#endif

/* NUMA support - declare stubs if libnuma not available */
#ifndef MTL_HAS_NUMA
/* NUMA stub declarations for FreeBSD when libnuma is not available */
int numa_available(void);
int numa_max_node(void);
int numa_node_of_cpu(int cpu);
void* numa_alloc_onnode(size_t size, int node);
void numa_free(void* mem, size_t size);
#else
/* Use system libnuma */
#include <numa.h>
#endif

#endif /* __FreeBSD__ */
#endif /* _MT_PLATFORM_FREEBSD_H_ */
