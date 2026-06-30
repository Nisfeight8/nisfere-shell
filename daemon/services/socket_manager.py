import asyncio
import json
import os


class DevShellSocket:
    def __init__(self, path="/tmp/nisfere-shell.sock"):
        self.path = path
        self.active_connections = set()
        self.message_handler = None

    async def start_server(self, message_handler):
        self.message_handler = message_handler

        if os.path.exists(self.path):
            try:
                os.unlink(self.path)
            except OSError:
                pass

        server = await asyncio.start_unix_server(self.handle_client, self.path)
        return server

    async def handle_client(self, reader, writer):
        print("Quickshell connected!")
        self.active_connections.add(writer)

        try:
            while True:
                data = await reader.readline()
                if not data:
                    break
                message = data.decode("utf-8").strip()
                if message and self.message_handler:
                    await self.message_handler(message)
        except (asyncio.CancelledError, ConnectionResetError):
            pass
        finally:
            print("Quickshell disconnected (Reloading or closed).")
            self.active_connections.discard(writer)
            writer.close()
            try:
                await writer.wait_closed()
            except Exception:
                pass

    def has_active_connections(self):
        return len(self.active_connections) > 0

    async def send(self, data_dict: dict):
        if not self.active_connections:
            return

        msg = json.dumps(data_dict) + "\n"
        payload = msg.encode("utf-8")

        for writer in list(self.active_connections):
            try:
                writer.write(payload)
                await writer.drain()
            except Exception:
                self.active_connections.discard(writer)
