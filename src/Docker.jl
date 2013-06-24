module Docker
	using HTTPClient
	using JSON

	immutable DockerError
		status::Int
		msg::ByteString
	end

	const headers = {"Content-Type"=>"application/json"}

	function create_container(host, image, cmd::Cmd; 
				tty = true, 
				attachStdin  = false,
				openStdin    = false,
     			attachStdout = true,
     			attachStderr = true,
     			ports = [])

		url = "http://$host:4243/v1.3"

		params =   ["Image" => image, 
					"Cmd" => [cmd.exec], 
				 	"Tty" => tty,
				 	"AttachStdin" 	=> attachStdin,
				 	"OpenStdin" 	=> openStdin,
				 	"AttachStdout" 	=> attachStdout,
				 	"AttachStderr" 	=> attachStderr,
				 	"PortSpecs"		=> [dec(p) for p in ports], 
				 	"Entrypoint" 	=> [],
				 	"Volumes"  		=> ["/.julia" => Dict{String,String}()],
				 	"VolumesFrom"   => ""]
		println(JSON.to_json(params))
		resp = HTTPClient.post(URI("$url/containers/create"),JSON.to_json(params);headers=headers)
		if resp.status != 201
			throw(DockerError(resp.status,resp.data))
		end
		JSON.parse(resp.data)
	end

	function inspect_container(host,id)
		url = URI("http://$host:4243/v1.3/containers/$id/json")
		resp = HTTPClient.get(url)
		if resp.status != 200
			throw(DockerError(resp.status,resp.data))
		end
		JSON.parse(resp.data)
	end

	getNattedPort(id,port) = parseint(inspect_container(id)["NetworkSettings"]["PortMapping"]["Tcp"][dec(port)])

	function start_container(host, id; binds = Dict{String,String}())
		url = URI("http://$host:4243/v1.3//containers/$id/start")
		params = ["Binds" => ["$k:$v" for (k,v) in binds], "ContainerIDFile" => ""]
		println(JSON.to_json(params))
		resp = HTTPClient.post(url,JSON.to_json(params);headers=headers)	
		if resp.status != 204
			throw(DockerError(resp.status,resp.data))
		end
		id
	end

	function kill_container(host, id)
		url = URI("http://$host:4243/v1.3/containers/$id/start")
		resp = HTTPClient.post(url,"")	
		if resp.status != 204
			throw(DockerError(resp.status,resp.data))
		end
		resp
	end

	function remove_container(host, id)
		url = URI("http://$host:4243/v1.3/containers/$id")
		resp = HTTPClient.delete(url)	
		if resp.status != 204
			throw(DockerError(resp.status,resp.data))
		end
		resp
	end

	function open_logs_stream(host, id)
		url = URI("http://$host:4243/v1.3/containers/$id/attach?stderr=1&stdin=1&stdout=1&stream=1")
		HTTPClient.open_stream(,["Content-Type"=>"plain/text"],"","POST")
	end

	function cleanse!(host)
		resp = HTTPClient.get(URI("http://$host:4243/v1.3/containers/json?all=true"))
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