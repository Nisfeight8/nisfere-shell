pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ==========================================
    // SIGNALS
    // ==========================================
    signal dataRefreshed
    signal navigateToDetails

    // ==========================================
    // GLOBAL STATE PROPERTIES
    // ==========================================
    property var composeProjects: ({})
    property var standaloneContainers: []
    property int runningContainers: 0
    property int totalContainers: 0

    property var dockerImages: []
    property var dockerVolumes: []

    // Structural/connection-level issue reported ALONGSIDE a
    // docker_stats payload (e.g. "Docker is not installed") — separate
    // from lastActionError below, which is about one specific action
    // failing, not the whole stats fetch.
    property string errorMessage: ""

    // True from requestDockerStats() until the next docker_stats
    // message arrives (or the timeout below gives up waiting). Lets
    // any UI reading this (e.g. the @containers search provider) show
    // a real loading state on first fetch instead of a misleading
    // "nothing found" — see chat.
    property bool loading: false

    // A specific action (start/stop/restart/delete/...) failed — the
    // daemon's generic {"type": "error", "payload": {"action", "error"}}
    // message was previously never even listened for here, so failures
    // were silently dropped with no way for any UI to know. Cleared
    // automatically the next time a docker_stats arrives (a fresh
    // successful stats fetch means whatever failed is now stale news).
    property string lastActionError: ""
    property string lastActionErrorAction: ""

    // Client-side safety net — mirrors GitService's own timeout. The
    // daemon already always responds to get_stats (even the failure
    // path returns a docker_stats payload with its own error field —
    // see docker_service.py's get_docker_status), so this only
    // matters if the socket itself drops mid-request; without it,
    // `loading` would stay true forever with nothing telling you
    // anything went wrong.
    readonly property int _requestTimeoutMs: 10000
    property Timer _requestTimeoutTimer: Timer {
        interval: root._requestTimeoutMs
        onTriggered: {
            root.loading = false;
            root.errorMessage = "No response from daemon (timed out) — check the daemon is running.";
        }
    }

    // ==========================================
    // CONTAINER DETAILS STATE
    // ==========================================
    property var activeContainerDetails: null
    property bool isViewingDetails: false

    // Which container's details we're actually waiting on right now —
    // guards against a slow/delayed response for a PREVIOUS
    // inspectContainer() call landing after you've already navigated
    // to a different container, which would otherwise silently
    // overwrite activeContainerDetails with stale data for the wrong
    // container.
    property string _expectedDetailsContainerId: ""

    // ==========================================
    // LIVE STREAMING STATE
    // ==========================================
    property string streamingContainerId: ""
    property string liveCpu: "0%"
    property string liveRam: "0B"
    property string liveLogs: ""

    // ==========================================
    // SOCKET MESSAGE ROUTER
    // ==========================================
    property Connections _conn: Connections {
        target: SocketService

        function onMessageReceived(type, payload) {
            if (type === "docker_stats") {
                root._requestTimeoutTimer.stop();
                root.loading = false;
                root.lastActionError = "";
                root.lastActionErrorAction = "";

                // 1. Update general container data
                root.runningContainers = payload.runningCount ?? 0;
                root.totalContainers = payload.totalCount ?? 0;
                root.composeProjects = payload.composeProjects ?? {};
                root.standaloneContainers = payload.standaloneContainers ?? [];

                // 2. Update new tabs data (Images & Volumes)
                root.dockerImages = payload.images ?? [];
                root.dockerVolumes = payload.volumes ?? [];

                root.errorMessage = payload.error ?? "";

                // 3. Auto-refresh details if the user is actively viewing a container
                if (root.activeContainerDetails && root.isViewingDetails) {
                    root.inspectContainer(root.activeContainerDetails.id);
                }

                root.dataRefreshed();
            } else if (type === "container_details") {
                if (payload.id !== root._expectedDetailsContainerId)
                    return; // stale — superseded by a newer inspectContainer() call
                root.activeContainerDetails = payload;
                root.dataRefreshed();
            } else if (type === "stream_log") {
                root.liveLogs += payload;
            } else if (type === "stream_stat") {
                root.liveCpu = payload.CPUPerc;
                root.liveRam = payload.MemUsage;
            } else if (type === "error") {
                // Previously not handled at all here — a failed
                // action (stop an already-stopped container, docker
                // daemon unreachable, ...) was silently dropped with
                // no way for any UI to surface it.
                root.lastActionError = payload.error ?? "Docker action failed";
                root.lastActionErrorAction = payload.action ?? "";
            }
        }
    }

    // ==========================================
    // DOCKER ACTIONS
    // ==========================================
    // Was 4 near-duplicate functions each hand-building the same
    // {action_type, target} payload shape — consolidated into one
    // private helper, same "_openFlag"-style DRY pattern already used
    // in ShellState for its own near-identical open/close/toggle
    // functions.
    function _dockerAction(actionType, action, target) {
        SocketService.sendCommand("docker", action, {
            "action_type": actionType,
            "target": target
        });
    }

    function composeAction(action, workingDir) {
        root._dockerAction("compose", action, workingDir);
    }

    function containerAction(action, containerId) {
        // Drop the "streaming shield" visually if we restart or stop
        if (action === "restart" || action === "stop") {
            root.streamingContainerId = "";
            root.liveLogs = "Waiting for container...\n";
            root.liveCpu = "0%";
            root.liveRam = "0B";
        }
        root._dockerAction("container", action, containerId);
    }

    function imageAction(action, imageId) {
        root._dockerAction("image", action, imageId);
    }

    // Removes dangling (<none>:<none>) images — daemon-side scope
    // matches plain `docker image prune`, not the more aggressive
    // `-a` variant. See docker_service.py's docker_action for the
    // reasoning.
    function pruneImages() {
        root._dockerAction("image", "prune", "");
    }

    function volumeAction(action, volumeName) {
        root._dockerAction("volume", action, volumeName);
    }

    // Same reasoning as pruneImages() — removes unused volumes,
    // matches plain `docker volume prune` scope.
    function pruneVolumes() {
        root._dockerAction("volume", "prune", "");
    }

    // ==========================================
    // NAVIGATION & DETAILS
    // ==========================================

    function inspectContainer(containerId) {
        root._expectedDetailsContainerId = containerId;
        const payload = {
            "action_type": "container",
            "target": containerId
        };
        SocketService.sendCommand("docker", "inspect_container", payload);
    }

    function requestAndNavigate(containerId) {
        root.isViewingDetails = true;
        root.inspectContainer(containerId);
        root.navigateToDetails();
    }

    // ==========================================
    // STREAM MANAGEMENT
    // ==========================================

    function startStream(containerId, initialLogs) {
        // Shield: Do nothing if the stream is already running for this ID
        if (root.streamingContainerId === containerId)
            return;

        root.streamingContainerId = containerId;
        root.liveLogs = initialLogs || "";
        root.liveCpu = "0%";
        root.liveRam = "0B";
        const payload = {
            "action_type": "container",
            "target": containerId
        };
        SocketService.sendCommand("docker", "start_stream", payload);
    }

    function stopStream() {
        // Shield: Do nothing if there's no stream running
        if (root.streamingContainerId === "")
            return;

        root.streamingContainerId = "";
        // No "target" here deliberately — the daemon's stop_stream
        // handler (_streams.stop_all()) stops every active stream
        // unconditionally, it doesn't look at target at all. Kept
        // action_type for consistency with every other payload shape
        // even though this specific action doesn't use it.
        const payload = {
            "action_type": "container"
        };
        SocketService.sendCommand("docker", "stop_stream", payload);
    }

    function requestDockerStats() {
        root.loading = true;
        root._requestTimeoutTimer.restart();
        SocketService.sendCommand("docker", "get_stats", {});
    }
}
