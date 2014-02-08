module Docker
	using Requests
	using JSON

	immutable DockerError
		status::Int
		msg::ByteString
	end

	const headers = {"Content-Type"=>"application/json"}

	docker_uri(host) = URI("http://$host/v1.8")
	docker_uri(host,endpoint) = URI("http://$host/v1.8/$endpoint")

	function create_container(host, image, cmd::Cmd; 
				tty = true, 
				attachStdin  = false,
				openStdin    = false,
     			attachStdout = true,
     			attachStderr = true,
     			volumes = String[],
     			ports = [],
     			pwd = "")

		url = docker_uri(host)

		params =   ["Image" => image, 
					"Cmd" => [cmd.exec], 
				 	"Tty" => tty,
				 	"AttachStdin" 	=> attachStdin,
				 	"OpenStdin" 	=> openStdin,
				 	"AttachStdout" 	=> attachStdout,
				 	"AttachStderr" 	=> attachStderr,
				 	"Entrypoint" 	=> [],
				 	"Volumes"  		=> (String=>Dict{String,String})[v => (String=>String)[] for v in volumes],
				 	"VolumesFrom"   => "",
					"ExposedPorts" 	=> [string(dec(p),"/tcp")=>Dict{Any,Any}() for p in ports]]
		if !isempty(pwd)
			params["WorkingDir"] = pwd
		end
		resp = post(URI("$url/containers/create"),data = params, headers=headers)
		if resp.status != 201
			throw(DockerError(resp.status,resp.data))
		end
		JSON.parse(resp.data)
	end

	function inspect_container(host,id)
		resp = get(docker_uri(host,"containers/$id/json"))
		if resp.status != 200
			throw(DockerError(resp.status,resp.data))
		end
		JSON.parse(resp.data)
	end

	getNattedPort(host,id,port) = parseint(inspect_container(host,id)["NetworkSettings"]["Ports"][string(dec(port),"/tcp")][1]["HostPort"])

	function start_container(host, id; binds = Dict{String,String}(), ports=[])
		params = ["Binds" => ["$k:$v" for (k,v) in binds], "ContainerIDFile" => "", "PortBindings" => [string(dec(p),"/tcp") => [Dict{Any,Any}()] for p in ports]]
		resp = post(docker_uri(host,"containers/$id/start"), data = params, headers=headers)	
		if resp.status != 204
			throw(DockerError(resp.status,resp.data))
		end
		id
	end

	function kill_container(host, id)
		resp = post(docker_uri(host,"containers/$id/start"),"")	
		if resp.status != 204
			throw(DockerError(resp.status,resp.data))
		end
		resp
	end

	function remove_container(host, id)
		resp = delete(docker_uri(host,"containers/$id"))	
		if resp.status != 204
			throw(DockerError(resp.status,resp.data))
		end
		resp
	end

	function list_containers(host)
		resp = get(docker_uri(host,"containers/json"))
		if resp.status != 200
			throw(DockerError(resp.status,resp.data))
		end
		JSON.parse(resp.data)
	end

	function open_logs_stream(host, id; history=false)
		path = "containers/$id/attach?stderr=1&stdin=1&stdout=1&stream=1"
		if history
			path *=  "&logs=1"
		end
		url = docker_uri(host,path)
		Requests.open_stream(url,["Content-Type"=>"plain/text"],"","POST")
	end

	function cleanse!(host)
		resp = get(docker_uri(host,"containers/json?all=true"))
		if resp.status != 200
			throw(DockerError(resp.status,resp.data))
		end
		data = JSON.parse(resp.data)
		for c in data
			kill_container(host,c["Id"])
			remove_container(host,c["Id"])
		end
		nothing
	end
end
