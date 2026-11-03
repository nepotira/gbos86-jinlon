#!/system/bin/sh
# GBOS System, Gaming and RAM Optimization Service for HP Elite c1030 (jinlon)
# Automatically executed as root on property:sys.boot_completed=1

LOG="/postinstall/gbos/logs/optimize.log"
exec >> "$LOG" 2>&1
echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Starting GBOS Hardware Optimization ==="

# 1. CPU Intel Speed Shift (HWP) & EPP Tuning
echo "[CPU] Configuring Intel P-State and Energy Performance Preference..."
if [ -d /sys/devices/system/cpu/intel_pstate ]; then
  echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
fi

for cpu in /sys/devices/system/cpu/cpu[0-7]; do
  # Set Energy Performance Preference to balance_performance
  if [ -f "$cpu/cpufreq/energy_performance_preference" ]; then
    echo "balance_performance" > "$cpu/cpufreq/energy_performance_preference" 2>/dev/null || true
  fi
  # Ensure governor is schedutil with aggressive responsiveness
  if [ -f "$cpu/cpufreq/scaling_governor" ]; then
    echo "schedutil" > "$cpu/cpufreq/scaling_governor" 2>/dev/null || true
  fi
done
echo "[CPU] P-State status: EPP=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)"

# 2. Intel RAPL Power Limits (prevent thermal clamp down to 800 MHz)
echo "[RAPL] Configuring Intel RAPL Power Limits..."
RAPL="/sys/class/powercap/intel-rapl/intel-rapl:0"
if [ -d "$RAPL" ]; then
  # PL1: 22W (22,000,000 uW)
  echo 22000000 > "$RAPL/constraint_0_power_limit_uw" 2>/dev/null || true
  # PL2: 35W (35,000,000 uW)
  echo 35000000 > "$RAPL/constraint_1_power_limit_uw" 2>/dev/null || true
  echo "[RAPL] Applied: PL1=$(cat $RAPL/constraint_0_power_limit_uw 2>/dev/null) uW, PL2=$(cat $RAPL/constraint_1_power_limit_uw 2>/dev/null) uW"
else
  echo "[RAPL] Intel RAPL sysfs path not found (will bind on module load)"
fi

# 3. Intel UHD 620 GPU Frequency Scaling (eliminate UI stutter)
echo "[GPU] Tuning Intel UHD Graphics frequencies..."
for drm_card in /sys/class/drm/card[0-9]; do
  if [ -f "$drm_card/gt_min_freq_mhz" ]; then
    # Raise minimum GPU clock to 500 MHz (prevents frame drops during window gestures)
    echo 500 > "$drm_card/gt_min_freq_mhz" 2>/dev/null || true
    echo 1150 > "$drm_card/gt_max_freq_mhz" 2>/dev/null || true
    echo 1150 > "$drm_card/gt_boost_freq_mhz" 2>/dev/null || true
    echo "[GPU] $drm_card min=$(cat $drm_card/gt_min_freq_mhz 2>/dev/null) MHz, max=$(cat $drm_card/gt_max_freq_mhz 2>/dev/null) MHz"
  fi
done

# 4. RAM & Virtual Memory Tuning for 16 GB LPDDR4x
echo "[RAM] Tuning VM subsystem for 16 GB physical RAM..."
sysctl -w vm.swappiness=10 2>/dev/null || echo 10 > /proc/sys/vm/swappiness 2>/dev/null || true
sysctl -w vm.vfs_cache_pressure=50 2>/dev/null || echo 50 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null || true
sysctl -w vm.dirty_ratio=20 2>/dev/null || echo 20 > /proc/sys/vm/dirty_ratio 2>/dev/null || true
sysctl -w vm.dirty_background_ratio=5 2>/dev/null || echo 5 > /proc/sys/vm/dirty_background_ratio 2>/dev/null || true

# 5. NVMe SSD I/O Queue Scheduler
echo "[I/O] Tuning NVMe storage queue..."
if [ -d /sys/block/nvme0n1 ]; then
  echo "none" > /sys/block/nvme0n1/queue/scheduler 2>/dev/null || true
  echo 512 > /sys/block/nvme0n1/queue/read_ahead_kb 2>/dev/null || true
  echo "[I/O] nvme0n1 scheduler: $(cat /sys/block/nvme0n1/queue/scheduler 2>/dev/null), read_ahead_kb: $(cat /sys/block/nvme0n1/queue/read_ahead_kb 2>/dev/null)"
fi

# 6. Silence Console Printk Flood
echo "[PRINTK] Silencing console printk spam..."
echo "3 4 1 3" > /proc/sys/kernel/printk 2>/dev/null || true

# 7. Stop Parasitic Background Debian VM
echo "[VM] Stopping background Debian Terminal VM if running..."
am force-stop com.android.virtualization.terminal 2>/dev/null || true

# 8. SurfaceFlinger & Touch Latency Tuning
echo "[SF] Tuning SurfaceFlinger properties..."
setprop debug.sf.latch_unsignaled 1
setprop debug.sf.enable_gl_backpressure 0
setprop debug.sf.early_phase_offset_ns 500000
setprop debug.sf.early_app_phase_offset_ns 500000

# 9. ART / Dex2Oat Compiler Threading for 8-thread CPU
echo "[ART] Setting dex2oat affinity to 8 threads..."
setprop dalvik.vm.dex2oat-cpu-set 0,1,2,3,4,5,6,7
setprop dalvik.vm.boot-dex2oat-cpu-set 0,1,2,3,4,5,6,7
setprop dalvik.vm.dex2oat-threads 8
setprop dalvik.vm.image-dex2oat-threads 8

echo "=== Optimization Completed Successfully at $(date '+%Y-%m-%d %H:%M:%S') ==="
