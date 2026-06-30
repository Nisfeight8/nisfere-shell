import asyncio
import json
from services.docker_service import DockerService

docker_svc = DockerService()

ACTIVE_STREAMS = []

# ==========================================
# EXPOSED ASYNC WRAPPERS
# ==========================================


def stop_all_streams():
    global ACTIVE_STREAMS
    for proc in ACTIVE_STREAMS:
        try:
            proc.terminate()
        except:
            pass
    ACTIVE_STREAMS.clear()


async def stream_container_stats(container_id, sock):
    proc = await docker_svc.get_stats_process(container_id)
    ACTIVE_STREAMS.append(proc)

    try:
        while True:
            line = await proc.stdout.readline()
            if not line:
                break

            stats_str = line.decode("utf-8").strip()
            if not stats_str:
                continue

            start_idx = stats_str.find("{")
            end_idx = stats_str.rfind("}") + 1

            if start_idx != -1 and end_idx != -1:
                clean_json_str = stats_str[start_idx:end_idx]
                try:
                    stats_data = json.loads(clean_json_str)
                    if sock:
                        await sock.send({"type": "stream_stat", "payload": stats_data})
                except json.JSONDecodeError:
                    pass
    except asyncio.CancelledError:
        proc.terminate()


async def stream_container_logs(container_id, sock):
    proc = await docker_svc.get_logs_process(container_id)
    ACTIVE_STREAMS.append(proc)

    try:
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
            if sock:
                await sock.send({"type": "stream_log", "payload": line.decode("utf-8")})
    except asyncio.CancelledError:
        proc.terminate()


async def fetch_container_details(container_id):
    return await asyncio.to_thread(docker_svc.get_container_details, container_id)


async def get_docker_stats():
    return await asyncio.to_thread(docker_svc.get_docker_status)


async def perform_docker_action(action, target, action_type):
    if action_type == "compose":
        return await docker_svc.docker_action_async(action, target, action_type)
    else:
        return await asyncio.to_thread(
            docker_svc.docker_action, action, target, action_type
        )


async def handle_command(action, payload, sock):
    target = payload.get("target", None)
    action_type = payload.get("action_type", "container")

    print(f"Docker Module · {action_type} · {action} → {target}")

    try:
        if action == "inspect_container":
            details = await fetch_container_details(target)
            if sock:
                await sock.send(details)
            return

        if action == "start_stream":
            stop_all_streams()
            asyncio.create_task(stream_container_stats(target, sock))
            asyncio.create_task(stream_container_logs(target, sock))
            return

        if action == "stop_stream":
            stop_all_streams()
            return

        if action == "get_stats":
            docker_stats = await get_docker_stats()
            await sock.send(docker_stats)
            return

        success = await perform_docker_action(action, target, action_type)
        if success and sock:
            await sock.send(await get_docker_stats())

    except Exception as e:
        print(f"Docker Command Error: {e}")
