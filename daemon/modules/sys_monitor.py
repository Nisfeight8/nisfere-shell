import psutil

def get_cpu_temp():
    if not hasattr(psutil, "sensors_temperatures"):
        return "N/A"
        
    temps = psutil.sensors_temperatures()
    for name in ['coretemp', 'k10temp', 'zenpower']:
        if name in temps and len(temps[name]) > 0:
            current_temp = temps[name][0].current
            return f"{int(current_temp)}°C"
            
    return "N/A"

async def get_system_stats():
    # === CPU ===
    cpu_percent = psutil.cpu_percent(interval=None)
    cpu_usage = cpu_percent / 100.0
    
    # === RAM ===
    mem = psutil.virtual_memory()
    ram_usage = mem.percent / 100.0
    # GiB (1024^3)
    ram_used_gib = (mem.total - mem.available) / (1024**3)
    ram_total_gib = mem.total / (1024**3)
    
    # === DISK ===
    disk = psutil.disk_usage('/')
    # bytes to GB
    disk_used_gb = disk.used / (1024**3)
    disk_total_gb = disk.total / (1024**3)

    return {
        "type": "sys_stats",
        "payload": {
            "cpuUsage": cpu_usage,
            "cpuTempText": get_cpu_temp(),
            "ramUsage": ram_usage,
            "ramUsedText": f"{ram_used_gib:.1f}GiB",
            "ramTotalText": f"{ram_total_gib:.1f}GiB",
            "diskUsage": f"{int(disk.percent)}%",
            "diskUsedText": f"{disk_used_gb:.1f}G",
            "diskTotalText": f"{disk_total_gb:.1f}G"
        }
    }