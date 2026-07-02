import asyncio
import json
import logging
import os
from typing import Awaitable, Callable

logger = logging.getLogger(__name__)

MessageHandler = Callable[[str], Awaitable[None]]


class DevShellSocket:
    def __init__(self, path: str = "/tmp/nisfere-shell.sock"):
        self.path = path
        self.active_connections: set[asyncio.StreamWriter] = set()
        self._message_handler: MessageHandler | None = None

    # ── Server lifecycle ────────────────────────────────────────────────────

    async def start_server(self, message_handler: MessageHandler) -> asyncio.Server:
        self._message_handler = message_handler
        self._remove_stale_socket()
        server = await asyncio.start_unix_server(self._handle_client, self.path)
        os.chmod(self.path, 0o600)  # owner-only access
        logger.info("Socket listening on %s", self.path)
        return server

    def _remove_stale_socket(self) -> None:
        try:
            os.unlink(self.path)
            logger.debug("Removed stale socket at %s", self.path)
        except FileNotFoundError:
            pass
        except OSError as e:
            logger.warning("Could not remove stale socket: %s", e)

    # ── Client handler ──────────────────────────────────────────────────────

    async def _handle_client(
        self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter
    ) -> None:
        addr = writer.get_extra_info("peername", "unknown")
        logger.info("Client connected: %s", addr)
        self.active_connections.add(writer)
        try:
            while True:
                data = await reader.readline()
                if not data:
                    break
                message = data.decode("utf-8").strip()
                if message and self._message_handler:
                    await self._message_handler(message)
        except (asyncio.CancelledError, ConnectionResetError):
            pass
        except Exception as e:
            logger.error("Unexpected error for client %s: %s", addr, e)
        finally:
            logger.info("Client disconnected: %s", addr)
            self.active_connections.discard(writer)
            await self._close_writer(writer)

    @staticmethod
    async def _close_writer(writer: asyncio.StreamWriter) -> None:
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass

    # ── Outgoing broadcast ──────────────────────────────────────────────────

    def has_active_connections(self) -> bool:
        return bool(self.active_connections)

    async def send(self, data: dict) -> None:
        """Broadcast a JSON message to all connected clients."""
        if not self.active_connections:
            return

        payload = (json.dumps(data) + "\n").encode("utf-8")
        dead: set[asyncio.StreamWriter] = set()

        for writer in list(self.active_connections):
            try:
                writer.write(payload)
                await writer.drain()
            except Exception as e:
                logger.warning("Send failed, dropping connection: %s", e)
                dead.add(writer)

        for writer in dead:
            self.active_connections.discard(writer)
            await self._close_writer(writer)
