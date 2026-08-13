pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Wraps SocketService's generic module/action/payload protocol for the
// daemon's "git" module. Keyed by repo path (statusByRepo/errorByRepo)
// rather than a single flat "current status" — a response arriving for
// a DIFFERENT repo than the one you're currently looking at (e.g. you
// switched away and the daemon's answer was already in flight) should
// never overwrite what you're actually viewing.
Singleton {
    id: root

    property var statusByRepo: ({})   // repoPath -> {branch, ahead, behind, staged, unstaged, untracked}
    property var errorByRepo: ({})    // repoPath -> {action, message}
    property bool loading: false

    signal statusUpdated(string repo)
    signal errorOccurred(string repo, string action, string message)

    Connections {
        target: SocketService
        function onMessageReceived(type, payload) {
            if (type === "git_status") {
                console.log(JSON.stringify(payload));

                root._requestTimeoutTimer.stop();
                const repo = payload.repo;
                const copy = Object.assign({}, root.statusByRepo);
                copy[repo] = payload;
                root.statusByRepo = copy;
                // A fresh, successful status supersedes any earlier
                // error shown for this same repo.
                if (root.errorByRepo[repo]) {
                    const errCopy = Object.assign({}, root.errorByRepo);
                    delete errCopy[repo];
                    root.errorByRepo = errCopy;
                }
                root.loading = false;
                root.statusUpdated(repo);
            } else if (type === "git_error") {
                root._requestTimeoutTimer.stop();
                const repo = payload.repo;
                const errCopy = Object.assign({}, root.errorByRepo);
                errCopy[repo] = {
                    action: payload.action,
                    message: payload.message
                };
                root.errorByRepo = errCopy;
                root.loading = false;
                root.errorOccurred(repo, payload.action, payload.message);
            }
        }
    }

    // Client-side safety net — the daemon already bounds push/pull to
    // 15s and everything else to 10s (see git_manager.py), guaranteeing
    // SOME response eventually IF the request actually reaches it and
    // the daemon is alive. This covers the remaining gap: the socket
    // disconnecting mid-request, or the request never making it there
    // at all — without this, `loading` would just stay true forever
    // with nothing telling you anything went wrong.
    property string _pendingRepo: ""
    property string _pendingAction: ""
    property Timer _requestTimeoutTimer: Timer {
        interval: 20000
        onTriggered: {
            root.loading = false;
            if (root._pendingRepo !== "")
                root.errorOccurred(root._pendingRepo, root._pendingAction, "No response from daemon (timed out) — check the daemon is running.");
        }
    }

    function _send(action, repo, extraPayload) {
        root.loading = true;
        root._pendingRepo = repo;
        root._pendingAction = action;
        root._requestTimeoutTimer.restart();
        const payload = Object.assign({
            repo: repo
        }, extraPayload ?? {});
        console.log("INSIDE");
        SocketService.sendCommand("git", action, payload);
    }

    function requestStatus(repo) {
        console.log(repo);
        root._send("status", repo);
    }
    function stage(repo, files) {
        root._send("stage", repo, {
            files: files ?? []
        });
    }
    function unstage(repo, files) {
        root._send("unstage", repo, {
            files: files ?? []
        });
    }
    function commit(repo, message) {
        root._send("commit", repo, {
            message: message
        });
    }
    function push(repo) {
        root._send("push", repo);
    }
    function pull(repo) {
        root._send("pull", repo);
    }

    function statusFor(repo) {
        return root.statusByRepo[repo] ?? null;
    }
    function errorFor(repo) {
        return root.errorByRepo[repo] ?? null;
    }
}
