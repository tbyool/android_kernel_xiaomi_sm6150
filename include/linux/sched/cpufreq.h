/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _LINUX_SCHED_CPUFREQ_H
#define _LINUX_SCHED_CPUFREQ_H

#include <linux/types.h>

/*
 * Interface between cpufreq drivers and the scheduler:
 */

#define SCHED_CPUFREQ_RT	(1U << 0)
#define SCHED_CPUFREQ_DL	(1U << 1)
#define SCHED_CPUFREQ_IOWAIT	(1U << 2)
#define SCHED_CPUFREQ_INTERCLUSTER_MIG (1U << 3)
#define SCHED_CPUFREQ_RESERVED	(1U << 4)
#define SCHED_CPUFREQ_PL	(1U << 5)
#define SCHED_CPUFREQ_EARLY_DET (1U << 6)
#define SCHED_CPUFREQ_FORCE_UPDATE (1U << 7)
#define SCHED_CPUFREQ_CONTINUE (1U << 8)

#ifdef CONFIG_CPU_FREQ
struct update_util_data {
       void (*func)(struct update_util_data *data, u64 time, unsigned int flags);
};

void cpufreq_add_update_util_hook(int cpu, struct update_util_data *data,
                       void (*func)(struct update_util_data *data, u64 time,
				    unsigned int flags));
void cpufreq_remove_update_util_hook(int cpu);

static inline unsigned long map_util_freq(unsigned long util,
					unsigned long freq, unsigned long cap)
{
	return (freq + (freq >> 2)) * util / cap;
}

static inline __maybe_unused unsigned long map_util_perf(unsigned long util)
{
	return util + (util >> 2);
}

/* Exported helpers for external cpufreq governors (e.g. loadable modules) */
unsigned long cpufreq_get_capacity_ref_freq(struct cpufreq_policy *policy);
unsigned long sugov_effective_cpu_perf(int cpu, unsigned long actual,
				       unsigned long min, unsigned long max);
void cpufreq_get_effective_util(int cpu, unsigned long boost,
				unsigned long *out_util,
				unsigned long *out_bw_min);
bool cpufreq_cpu_dl_bw_exceeded(int cpu, unsigned long bw_min);
bool cpufreq_cpu_uclamp_capped(int cpu);
// cpufreq_scx_switched_all(void) removed for 4.19!!

#endif /* CONFIG_CPU_FREQ */

#endif /* _LINUX_SCHED_CPUFREQ_H */
