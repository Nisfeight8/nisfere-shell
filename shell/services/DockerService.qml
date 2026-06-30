pragma Singleton
import QtQuick

QtObject {
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

    property string errorMessage: ""

    // ==========================================
    // CONTAINER DETAILS STATE
    // ==========================================
    property var activeContainerDetails: null
    property bool isViewingDetails: false

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
                root.activeContainerDetails = payload;
                root.dataRefreshed();
            } else if (type === "stream_log") {
                root.liveLogs += payload;
            } else if (type === "stream_stat") {
                root.liveCpu = payload.CPUPerc;
                root.liveRam = payload.MemUsage;
            }
        }
    }

    // ==========================================
    // DOCKER ACTIONS
    // ==========================================

    function composeAction(action, workingDir) {
        const payload = {
            "action_type": "compose",
            "target": workingDir
        };
        SocketService.sendCommand("docker", action, payload);
    }

    function containerAction(action, containerId) {
        // Drop the "streaming shield" visually if we restart or stop
        if (action === "restart" || action === "stop") {
            root.streamingContainerId = "";
            root.liveLogs = "Waiting for container...\n";
            root.liveCpu = "0%";
            root.liveRam = "0B";
        }
        const payload = {
            "action_type": "container",
            "target": containerId
        };
        SocketService.sendCommand("docker", action, payload);
    }

    // NEW: Handle actions for Images
    function imageAction(action, imageId) {
        const payload = {
            "action_type": "image",
            "target": imageId
        };
        SocketService.sendCommand("docker", action, payload);
    }

    // NEW: Handle actions for Volumes
    function volumeAction(action, volumeName) {
        const payload = {
            "action_type": "volume",
            "target": volumeName
        };
        SocketService.sendCommand("docker", action, payload);
    }

    // ==========================================
    // NAVIGATION & DETAILS
    // ==========================================

    function inspectContainer(containerId) {
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
        const payload = {
            "action_type": "container"
        };
        SocketService.sendCommand("docker", "stop_stream", payload);
    }

    function requestDockerStats() {
        SocketService.sendCommand("docker", "get_stats", {});
    }
}
