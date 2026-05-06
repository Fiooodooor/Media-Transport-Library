/* SPDX-License-Identifier: BSD-3-Clause
 * Copyright(c) 2022 Intel Corporation
 */

#if defined(__FreeBSD__) && !defined(MTL_HAS_NUMA)

#include <stdlib.h>

#include "mt_log.h"

/* NUMA stub implementation for FreeBSD when libnuma is not available */

int numa_available(void) {
  /* Pretend NUMA is available but return single socket */
  return 0;
}

int numa_max_node(void) {
  /* Single socket system */
  return 0;
}

int numa_node_of_cpu(int cpu) {
  /* All CPUs on node 0 */
  (void)cpu;
  return 0;
}

void* numa_alloc_onnode(size_t size, int node) {
  /* Fallback to regular malloc, ignore node */
  (void)node;
  return malloc(size);
}

void numa_free(void* mem, size_t size) {
  /* Use regular free */
  (void)size;
  free(mem);
}

#endif /* __FreeBSD__ && !MTL_HAS_NUMA */
