# Docker.jl

A Julia interface for the Docker Remote API. It provides basic features to run containers and manage them.

The package is tested against Julia 1.0.1 on Linux.

## Installation

```
Pkg.add("Docker")
```

## Getting started

The Docker.jl API resides in the ``Docker`` module.

```
using Docker
```

### create_container

Creates a container that can then be started for ``start_container()``:

```
create_container("127.0.0.1:4243","ubuntu:latest",memory=512*(10^6),portBindings=[22,22])
```

**Parameters:**

* ``host`` (string): url/port to the Docker. Example: 127.0.0.1:4243
* ``entrypoint`` (string): An entrypoint
* ``cmd`` (string): Command to be executed
* ``image`` (string): Image name to get
* ``tty_stream`` (bool): Allocate a pseudo-TTY. Default: True
* ``AttachStdin`` (bool): Attach STDIN. Default: False
* ``openStdin`` (bool): Keep STDIN open even if not attached. Default: False
* ``attachStdout`` (bool): Attach to stdout of the exec command if true. Default: True
* ``attachStderr`` (bool): Get STDERR. Default: True
* ``memory`` (int): set memory limit. It accepts integer values that are bytes as a unit
* ``CpuSets`` (string): CPUs in which to allow execution. Example: "0-2", "0,1"
* ``volumeDriver`` (string): The name of a volume driver/plugin.
* ``portBindings`` (list): Provide a list of ports to open inside the containers in format [ContainerPort,HostPort].
* ``workingDir`` (string): Specifies the working directory for commands to run in.

**Returns**: A dictionary with an image 'Id' key and a 'Warnings' key.

### Other functions

* ``inspect_container(host,id)``
* ``start_container(host,id)``
* ``restart_container(host,id)``
* ``stop_container(host,id)``
* ``pause_container(host,id)``
* ``unpause_container(host,id)``
* ``kill_container(host,id)``
* ``remove_container(host,id)``
* ``processes_container(host,id)``
* ``list_container(host,id)``
* ``stats_container(host,id)``
* ``open_logs_stream(host,id; history=false)``
* ``cleanse!(host)``
