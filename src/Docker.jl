module Docker
	using WWWClient
	using JSON

	immutable DockerError
		status::Int
		msg::ByteString
	end

	const headers = {"Content-Type"=>"application/json"}

	docker_uri(host) = URI("http://$host/v1.3")
	docker_uri(host,endpoint) = URI("http://$host/v1.3/$endpoint")

	function create_container(host, image, cmd::Cmd; 
				tty = true, 
				attachStdin  = false,
				openStdin    = false,
     			attachStdout = true,
     			attachStderr = true,
     			ports = [])

		url = "http://$host/v1.4"

		params =   ["Image" => image, 
					"Cmd" => [cmd.exec], 
				 	"Tty" => tty,
				 	"AttachStdin" 	=> attachStdin,
				 	"OpenStdin" 	=> openStdin,
				 	"AttachStdout" 	=> attachStdout,
				 	"AttachStderr" 	=> attachStderr,
				 	"PortSpecs"		=> [dec(p) for p in ports], 
				 	"Entrypoint" 	=> [],
				 	"Volumes"  		=> Dict{String,String}(),
				 	"VolumesFrom"   => ""]
		println(json(params))
		resp = WWWClient.post(URI("$url/containers/create"),json(params);headers=headers)
		if resp.status != 201
			throw(DockerError(resp.status,resp.data))
		end
		JSON.parse(resp.data)
	end

	function inspect_container(host,id)
		resp = WWWClient.get(docker_uri(host,"containers/$id/json"))
		if resp.status != 200
			throw(DockerError(resp.status,resp.data))
		end
		JSON.parse(resp.data)
	end

	getNattedPort(host,id,port) = parseint(inspect_container(host,id)["NetworkSettings"]["PortMapping"]["Tcp"][dec(port)])

	function start_container(host, id; binds = Dict{String,String}())
		params = ["Binds" => ["$k:$v" for (k,v) in binds], "ContainerIDFile" => ""]
		println(json(params))
		resp = WWWClient.post(docker_uri(host,"containers/$id/start"),json(params);headers=headers)	
		if resp.status != 204
			throw(DockerError(resp.status,resp.data))
		end
		id
	end

	function kill_container(host, id)
		resp = WWWClient.post(docker_uri(host,"containers/$id/start"),"")	
		if resp.status != 204
			throw(DockerError(resp.status,resp.data))
		end
		resp
	end

	function remove_container(host, id)
		resp = WWWClient.delete(docker_uri(host,"containers/$id"))	
		if resp.status != 204
			throw(DockerError(resp.status,resp.data))
		end
		resp
	end

	function open_logs_stream(host, id)
		url = docker_uri(host,"containers/$id/attach?stderr=1&stdin=1&stdout=1&stream=1")
		WWWClient.open_stream(url,["Content-Type"=>"plain/text"],"","POST")
	end

	function cleanse!(host)
		resp = WWWClient.get(docker_uri(host,"containers/json?all=true"))
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