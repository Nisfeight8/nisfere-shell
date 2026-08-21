import asyncio
import json
import logging
import os
import socket
from typing import Awaitable, Callable

logger = logging.getLogger(__name__)

MessageHandler = Callable[[str], Awaitable[None]]

# Per the systemd socket activation protocol, the first fd systemd
# passes to an activated process is always fd 3 (stdin/stdout/stderr
# occupy 0/1/2). LISTEN_FDS tells you how many were passed; we only
# ever expect one here.
_SYSTEMD_LISTEN_FDS_START = 3


class DevShellSocket:
    def __init__(self, path: str = "/tmp/nisfere-shell.sock"):
        self.path = path
        self.active_connections: set[asyncio.StreamWriter] = set()
        self._message_handler: MessageHandler | None = None

    # ── Server lifecycle ────────────────────────────────────────────────────

    def _get_systemd_socket(self) -> socket.socket | None:
        """Return the socket systemd handed us via socket activation, or
        None if we weren't started that way — in which case start_server
        falls back to creating (and owning) the socket file itself, same
        as before. This makes `python3 main.py` still work unchanged for
        local/manual runs with no systemd involved at all."""
        listen_pid = os.environ.get("LISTEN_PID")
        listen_fds = os.environ.get("LISTEN_FDS")

        if not listen_pid or not listen_fds:
            return None

        try:
            if int(listen_pid) != os.getpid():
                # These env vars can be inherited by child processes that
                # aren't actually the intended socket-activation target —
                # only trust them if they were meant for THIS process.
                return None
            if int(listen_fds) < 1:
                return None
        except ValueError:
            logger.warning("Malformed LISTEN_PID/LISTEN_FDS, ignoring")
            return None

        sock = socket.socket(fileno=_SYSTEMD_LISTEN_FDS_START)
        sock.setblocking(False)
        logger.info("Using systemd-provided socket (socket activation)")
        return sock

    async def start_server(self, message_handler: MessageHandler) -> asyncio.Server:
        self._message_handler = message_handler

        systemd_sock = self._get_systemd_socket()
        if systemd_sock is not None:
            server = await asyncio.start_unix_server(
                self._handle_client, sock=systemd_sock
            )
            logger.info("Socket listening via systemd activation on %s", self.path)
        else:
            self._remove_stale_socket()
            server = await asyncio.start_unix_server(
                self._handle_client, path=self.path
            )
            os.chmod(self.path, 0o600)  # owner-only access
            logger.info(
                "Socket listening on %s (self-managed, no systemd activation)",
                self.path,
            )

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
