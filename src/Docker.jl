module Docker

using HTTP
using JSON
using Compat

struct DockerError
    status::Int
    msg::Compat.String
end

const headers = Dict("Content-Type" => "application/json")

docker_uri(host) = HTTP.URI("http://$host/v1.21")
docker_uri(host,endpoint) = HTTP.URI("http://$host/v1.21/$endpoint")
parse_body(data) = JSON.parse(join(map(Char,data)))

function create_container(
        host, image;
        cmd::Cmd     = ``,
        entryPoint   = "",
        tty_stream   = true,
        attachStdin  = false,
        openStdin    = false,
        attachStdout = true,
        attachStderr = true,
        memory       = 0,
        cpuSets      = "",
        volumeDriver = "",
        portBindings = ["",""], # [ContainerPort,HostPort]
        ports        = [],
        workingDir   = ""
    )

    url = docker_uri(host)

    params = Dict(
        "Image" => image,
        "Tty" => tty_stream,
        "AttachStdin"   => attachStdin,
        "OpenStdin"     => openStdin,
        "AttachStdout"  => attachStdout,
        "AttachStderr"  => attachStderr,
        "ExposedPorts"  => Dict([Pair(string(dec(p),"/tcp"), Dict()) for p in ports]),
        "HostConfig"    => Dict(
            "Memory"       => memory,
            "CpusetCpus"   => cpuSets,
            "VolumeDriver" => volumeDriver,
            "PortBindings" => Dict(
                string(portBindings[1],"/tcp") => [
                    Dict("HostPort" => string(portBindings[2]))
                ]
            )
        )
    )

    if !isempty(entryPoint)
        params["Entrypoint"] = entryPoint
    end

    if !isempty(cmd.exec)
        params["Cmd"] = collect(cmd.exec)
    end

    if !isempty(workingDir)
        params["WorkingDir"] = workingDir
    end

    resp = HTTP.request("POST",HTTP.URI("$url/containers/create"),[],JSON.json(params),headers=headers)
    if resp.status != 201
        throw(DockerError(resp.status,resp.body))
    end
    parse_body(resp.body)
end

function inspect_container(host,id)
    resp = HTTP.request("GET",(docker_uri(host,"containers/$id/json")))
    if resp.status != 200
        throw(DockerError(resp.status,resp.body))
    end
    parse_body(resp.body)
end

function start_container(host, id)
    resp = HTTP.request("POST",(docker_uri(host,"containers/$id/start")))
    print(resp)
    if resp.status != 204
        throw(DockerError(resp.status,resp.body))
    end
    id
end

function restart_container(host, id)
    resp = HTTP.request("POST",(docker_uri(host,"containers/$id/restart")))
    if resp.status != 204
        throw(DockerError(resp.status,resp.body))
    end
    resp
end

function stop_container(host, id)
    resp = HTTP.request("POST",(docker_uri(host,"containers/$id/stop")))
    if resp.status != 204
        throw(DockerError(resp.status,resp.body))
    end
    resp
end

function pause_container(host, id)
    resp = HTTP.request("POST",(docker_uri(host,"containers/$id/pause")))
    if resp.status != 204
        throw(DockerError(resp.status,resp.body))
    end
    resp
end

function unpause_container(host, id)
    resp = HTTP.request("POST",(docker_uri(host,"containers/$id/unpause")))
    if resp.status != 204
        throw(DockerError(resp.status,resp.body))
    end
    id
end

function kill_container(host, id)
    resp = HTTP.request("POST",(docker_uri(host,"containers/$id/kill")))
    if resp.status != 204
        throw(DockerError(resp.status,resp.body))
    end
    resp
end

function remove_container(host, id)
    resp = HTTP.request("DELETE",(docker_uri(host,"containers/$id?force=1")))
    if resp.status != 204
        throw(DockerError(resp.status,resp.body))
    end
    resp
end

function processes_container(host, id)
    resp = HTTP.request("GET",(docker_uri(host,"containers/$id/top")))
    if resp.status != 204
        println(resp.status)
    end
    if resp.status != 200
        throw(DockerError(resp.status,resp.body))
    end
    parse_body(resp.body)
end

function list_containers(host)
    resp = HTTP.request("GET",(docker_uri(host,"containers/json")))
    print(resp)
    if resp.status != 200
        throw(DockerError(resp.status,resp.body))
    end
    parse_body(resp.body)
end

function stats_container(host,id)
    resp = HTTP.request("GET",(docker_uri(host,"containers/$id/stats?stream=0")))
    if resp.status != 200
        throw(DockerError(resp.status,resp.body))
    end
    parse_body(resp.body)
end

function open_logs_stream(host, id; history=false)
    path = "containers/$id/attach?logs&follow=1&stdout=1"
    if history
        path *=  "&logs=1"
    end
    url = docker_uri(host,path)
    HTTP.open(url,"GET",[Dict("Content-Type"=>"plain/text")],"","POST")
end

function cleanse!(host)
    resp = HTTP.request("GET",(docker_uri(host,"containers/json?all=true")))
    if resp.status != 200
        throw(DockerError(resp.status,resp.body))
    end
    data = parse_body(resp.body)
    for c in data
        remove_container(host,c["Id"])
        kill_container(host,c["Id"])
    end
    nothing
end

end # module Docker
