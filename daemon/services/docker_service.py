import json
import docker
import asyncio


class DockerService:
    def __init__(self):
        pass
    # ==========================================
    # 1. STREAMING & LOGS
    # ==========================================

    async def get_stats_process(self, container_id):
        proc = await asyncio.create_subprocess_exec(
            "docker", "stats", "--format", "{{json .}}", container_id,
            stdout=asyncio.subprocess.PIPE,
        )
        return proc

    async def get_logs_process(self, container_id):
        proc = await asyncio.create_subprocess_exec(
            "docker", "logs", "-f", "--tail", "50", container_id,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )
        return proc

    # ==========================================
    # 2. DATA FETCHERS
    # ==========================================

    def _fetch_containers(self, client):
        containers = client.containers.list(all=True)
        compose_projects = {}
        standalone_containers = []
        running_count = 0

        for c in containers:
            if c.status == "running":
                running_count += 1
            labels = c.labels
            project_name = labels.get("com.docker.compose.project")

            container_info = {
                "id": c.short_id,
                "name": c.name,
                "status": c.status,
                "service": labels.get("com.docker.compose.service", "N/A"),
            }

            if project_name:
                working_dir = labels.get("com.docker.compose.project.working_dir", "")
                config_files_str = labels.get(
                    "com.docker.compose.project.config_files", ""
                )

                if project_name not in compose_projects:
                    compose_projects[project_name] = {
                        "working_dir": working_dir,
                        "config_files_set": set(),
                        "containers": [],
                    }
                if config_files_str:
                    for f in config_files_str.split(","):
                        if f.strip():
                            compose_projects[project_name]["config_files_set"].add(
                                f.strip()
                            )

                compose_projects[project_name]["containers"].append(container_info)
            else:
                standalone_containers.append(container_info)

        for proj_name, proj_data in compose_projects.items():
            proj_data["config_files"] = ",".join(proj_data.pop("config_files_set"))

        return compose_projects, standalone_containers, running_count, len(containers)

    def _fetch_images(self, client):
        images_list = []
        for img in client.images.list():
            tags = img.tags if img.tags else ["<none>:<none>"]
            size_mb = round(img.attrs.get("VirtualSize", 0) / (1024 * 1024), 1)
            for tag in tags:
                name, t = tag.split(":", 1) if ":" in tag else (tag, "latest")
                images_list.append(
                    {
                        "id": img.short_id.replace("sha256:", ""),
                        "name": name,
                        "tag": t,
                        "size": f"{size_mb} MB",
                    }
                )
        return images_list

    def _fetch_volumes(self, client):
        volumes_list = []
        for vol in client.volumes.list():
            volumes_list.append(
                {
                    "name": vol.name,
                    "driver": vol.attrs.get("Driver", "local"),
                    "mountpoint": vol.attrs.get("Mountpoint", ""),
                }
            )
        return volumes_list

    def get_docker_status(self):
        try:
            client = docker.from_env()
            compose_projects, standalone_containers, running_count, total_count = (
                self._fetch_containers(client)
            )
            images_list = self._fetch_images(client)
            volumes_list = self._fetch_volumes(client)

            return {
                "type": "docker_stats",
                "payload": {
                    "runningCount": running_count,
                    "totalCount": total_count,
                    "composeProjects": compose_projects,
                    "standaloneContainers": standalone_containers,
                    "images": images_list,
                    "volumes": volumes_list,
                    "error": "",
                },
            }
        except Exception as e:
            return {
                "type": "docker_stats",
                "payload": {"runningCount": -1, "error": str(e)},
            }

    def get_container_details(self, container_id):
        try:
            client = docker.from_env()
            c = client.containers.get(container_id)
            attrs = c.attrs
            recent_logs = c.logs(tail=50, stdout=True, stderr=True).decode(
                "utf-8", errors="ignore"
            )

            details = {
                "id": c.short_id,
                "name": c.name,
                "status": c.status,
                "image": attrs["Config"]["Image"],
                "created": attrs["Created"],
                "env": attrs["Config"].get("Env", []),
                "ports": attrs["NetworkSettings"]["Ports"],
                "logs": recent_logs,
            }
            return {"type": "container_details", "payload": details}
        except Exception as e:
            return {"type": "error", "payload": f"Could not fetch details: {e}"}

    # ==========================================
    # 3. ACTIONS
    # ==========================================

    def docker_action(self, action, target, action_type):
        try:
            client = docker.from_env()
            if action_type == "container":
                container = client.containers.get(target)
                if action == "start":
                    container.start()
                elif action == "stop":
                    container.stop()
                elif action == "restart":
                    container.restart()
                elif action == "delete":
                    if container.status == "running":
                        container.stop()
                    container.remove(v=True, force=True)
            elif action_type == "image":
                if action == "delete":
                    client.images.remove(target, force=True)
            elif action_type == "volume":
                if action == "delete":
                    volume = client.volumes.get(target)
                    volume.remove(force=True)
            return True
        except Exception as e:
            print(f"Error occured during docker {action_type} action: {e}")
            return False

    async def docker_action_async(self, action, target_obj, action_type):
        try:
            working_dir = target_obj.get("working_dir")
            config_files_str = target_obj.get("config_files", "")
            cmd = ["docker", "compose"]

            if config_files_str:
                for f in config_files_str.split(","):
                    cmd.extend(["-f", f.strip()])

            cmd.append(action)
            if action == "up":
                cmd.append("-d")

            proc = await asyncio.create_subprocess_exec(
                *cmd,
                cwd=working_dir,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await proc.communicate()

            if proc.returncode != 0:
                print(f"Error running compose: {stderr.decode()}")
                return False
            return True
        except Exception as e:
            print(f"Error occured during compose action: {e}")
            return False
