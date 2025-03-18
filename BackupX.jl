using Pkg

function ensure_package()
	dependencies = ("JSON", "OrderedCollections")
	for pkg in dependencies
		isnothing(Base.find_package(pkg)) && Pkg.add(pkg)
	end
end

ensure_package()


include("src/banner.jl")
include("src/args.jl")
include("src/URL.jl")

using JSON
using Printf
using OrderedCollections


function GenerateBackupNames(; urls::Vector{String}, opt::Dict{String, Vector{String}}, patterns::Vector{String})
	result = OrderedSet{String}()
	Threads.@threads for u in urls
		url = URL(u)
		data = merge(url_vars(url), opt)

		Threads.@threads for pattern in patterns
			try
				edit_patt = replace(pattern, "\$" => "%s", "%" => "%s", isletter => "") |> Printf.Format
				vars = split(pattern, !isletter, keepempty = false)
				vals = [data[k] for k in vars]
				for items in Iterators.product(vals...)
					push!(result, Printf.format(edit_patt, items...))
				end
			catch err
				@error sprint(showerror, err)
				exit(0)
			end
		end
	end
	return result
end



function check_pattern_var(patterns::Vector{String})
	pat_vars = (
		"scheme", "username", "password", "host",
		"subdomain", "domain", "tld", "port",
		"path", "directory", "file", "fileN",
		"fileE", "query", "fragment", "word",
		"ext", "num", "y", "m", "d",
	)

	found_vars = Set{String}()

	for pat in patterns
		push!(found_vars, split(pat, !isletter, keepempty = false)...)
	end

	if !issubset(found_vars, pat_vars)
		bad_vars = setdiff(found_vars, pat_vars) |> collect
		@error "$bad_vars variable(s) not supported ❎"
		exit(0)
	end
end

function OpenPatterns(FilePath::String)
	if !isfile(FilePath)
		@error "No Such File or Directory: $FilePath"
		exit(0)
	end

	File = try
		patterns = read(FilePath, String) |> JSON.parse
		sub_patterns = String[]

		for key in keys(patterns)
			append!(sub_patterns, patterns[key])
		end

		check_pattern_var(sub_patterns)

		sub_patterns
	catch e
		@warn sprint(showerror, e) file = FilePath
		exit(0)
	end
end


function main()
	banner()

	args = ARGUMENTS()
	opt = Dict{String, Vector{String}}()
	for k in ("w", "e", "n", "y", "m", "d")
		v = args[k]
		if k == "w"
			k = "word"
		elseif k == "e"
			k = "ext"
		elseif k == "n"
			k = "num"
		end
		opt[k] = isempty(v) ? String[] : v
	end

	patterns = args["p"] |> OpenPatterns

	result = GenerateBackupNames(urls = args["source"], opt = opt, patterns = patterns)

	if !isempty(args["o"])
		open(args["o"], "w+") do file
			write(file, join(result, "\n"))
		end
	else
		print(join(result, "\n"))
	end

end

main()
