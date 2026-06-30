import json
import asyncio
from services.socket_manager import DevShellSocket
from modules import docker_manager, theme_controller, sys_monitor

COMMAND_ROUTER = {
    "docker": docker_manager.handle_command,
    "theme": theme_controller.handle_command,
    # "git": git_manager.handle_command
}


async def stats_loop(sock):
    while True:
        if sock.has_active_connections():
            stats = await sys_monitor.get_system_stats()
            await sock.send(stats)
        await asyncio.sleep(2)


async def main():
    sock = DevShellSocket()

    async def handle_incoming_commands(msg):
        try:
            data = json.loads(msg)
            module_name = data.get("module")
            action = data.get("action")
            payload = data.get("payload", {})

            if not module_name:
                print(f"Warning: Command received without 'module': {data}")
                return

            if module_name in COMMAND_ROUTER:
                handler = COMMAND_ROUTER[module_name]
                await handler(action, payload, sock)
            else:
                print(f"Unknown module target: '{module_name}'")

        except json.JSONDecodeError as e:
            print(f"JSON parse error: {e}")

    server = await sock.start_server(handle_incoming_commands)

    print("🚀 Nisfere Daemon started as Server!")

    async with server:
        await asyncio.gather(stats_loop(sock), server.serve_forever())


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n Exit.")
