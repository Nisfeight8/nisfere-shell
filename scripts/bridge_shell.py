import os, pty, subprocess, sys, re, termios, fcntl

master, slave = pty.openpty()

flags = fcntl.fcntl(master, fcntl.F_GETFL)
fcntl.fcntl(master, fcntl.F_SETFL, flags | os.O_NONBLOCK)

flags = fcntl.fcntl(sys.stdin, fcntl.F_GETFL)
fcntl.fcntl(sys.stdin, fcntl.F_SETFL, flags | os.O_NONBLOCK)

attrs = termios.tcgetattr(slave)
attrs[3] = attrs[3] & ~termios.ECHO
termios.tcsetattr(slave, termios.TCSANOW, attrs)

proc = subprocess.Popen(
    ["sh"],
    stdin=slave,
    stdout=slave,
    stderr=slave,
    start_new_session=True,
    env={**os.environ, "TERM": "xterm", "NO_COLOR": "1", "PS1": ""}
)

os.close(slave)

ansi_escape = re.compile(
    r"\x1b("
    r"\[[0-9;?]*[a-zA-Z]"
    r"|\][^\x07\x1b]*[\x07]"
    r"|\][^\x07\x1b]*\x1b\\"
    r"|\([AB012]"
    r"|[=>]"
    r"|[MDE]"
    r")"
)

while True:
    try:
        data = os.read(master, 4096).decode(errors="ignore")
        if data:
            clean = ansi_escape.sub("", data)
            clean = clean.replace("\r\n", "\n").replace("\r", "\n")
            clean = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", "", clean)
            if clean:
                if not clean.endswith("\n"):
                    clean += "\n"

                sys.stdout.write(clean)
                sys.stdout.flush()
    except BlockingIOError:
        pass
    except OSError:
        break

    try:
        cmd = os.read(sys.stdin.fileno(), 4096)
        if cmd:
            os.write(master, cmd)
    except BlockingIOError:
        pass
