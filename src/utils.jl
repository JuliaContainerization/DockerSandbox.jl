"""
    apply_chmod_recursively(root_dir::String; dir_mode::Integer, file_mode::Integer)
"""
function apply_chmod_recursively(root_dir::String;
                                 dir_mode::Integer,
                                 file_mode::Integer)
    chmod(root_dir, dir_mode)
    for (root, dirs, files) in walkdir(root_dir)
        for dir in dirs
            full_dir_path = joinpath(root, dir)
            isdir(full_dir_path) || throw(ArgumentError("unexpected error"))
            chmod(full_dir_path, dir_mode)
        end
        for file in files
            full_file_path = joinpath(root, file)
            isfile(full_file_path) || throw(ArgumentError("unexpected error"))
            chmod(full_file_path, file_mode)
        end
    end
    return nothing
end

"""
    make_world_readable_recursively(root_dir::String)
"""
function make_world_readable_recursively(root_dir::String)
    return apply_chmod_recursively(root_dir; dir_mode=0o555, file_mode=0o444)
end

"""
    make_world_writeable_recursively(root_dir::String)
"""
function make_world_writeable_recursively(root_dir::String)
    return apply_chmod_recursively(root_dir; dir_mode=0o777, file_mode=0o666)
end
