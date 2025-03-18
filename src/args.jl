using StyledStrings

const help = styled"""
{bold,success,region:# optional switches:}

{tip:* -h}            Show help message and exit
{tip:* -u}            Specify a single URL to process.
{tip:* -ul}           Provide a file containing multiple URLs to process
{tip:* -s}            Read URL(s) from standard input (stdin)
{tip:* -p}            Specify a file containing patterns to use in JSON format
{tip:* -w}            Provide a wordlist file for processing
{tip:* -e}            Specify a file containing extensions to use
{tip:* -n}            Define a number range (e.g., 1-100)
{tip:* -y}            Define a year range (e.g., 2022-2023)
{tip:* -m}            Define a month range (e.g., 1-12)
{tip:* -d}            Define a day range (e.g., 1-30)
{tip:* -o}            Save the output to a file (default: empty)


{bold,info,region:# optional variables:}

{info:* scheme}       
{info:* username}
{info:* password}
{info:* host}
{info:* subdomain}
{info:* domain}
{info:* tld}
{info:* port}
{info:* path}
{info:* directory}
{info:* file}
{info:* fileN}          file name
{info:* fileE}          file extension
{info:* query}
{info:* fragment}
{info:* word}           wordlist
{info:* ext}            extensions
{info:* num}            number range
{info:* y}              year range
{info:* m}              month range
{info:* d}              day range
"""


function single_pass(param::String)
	idx = findfirst(==(param), ARGS) + 1
	if isassigned(ARGS, idx) && !startswith(ARGS[idx], "-")
		return ARGS[idx]
	else
		return ""
	end
end

function multi_pass(param::String)
	res = String[]
	idx1 = findfirst(==(param), ARGS)
	for i in ARGS[idx1+1:end]
		startswith(i, "-") && break
		push!(res, i)
	end
	return res
end

function number_sequence(range::String, padding::Int = 2)
	try
		range = replace(range, "-" => ":")
		seq = eval(Meta.parse(range))
		string.(seq, pad = padding)
	catch e
		if isa(e, ArgumentError)
			@error "Range Should be Numbers: $range"
			exit(0)
		end
	end
end

function ARGUMENTS()
	args = Dict{String, Any}(
		"source" => String[],
		"u" => "",
		"ul" => "",
		"p" => "",
		"w" => "",
		"e" => "",
		"n" => "",
		"y" => "",
		"m" => "",
		"d" => "",
		"o" => "",
		"s" => false,
	)

	("-h" ∈ ARGS) && (print(help), exit(0))
	("-s" ∈ ARGS) && (args["s"] = true)

	for itm in ("-u", "-ul", "-p", "-w", "-e", "-n", "-y", "-m", "-d", "-o")
		if itm ∈ ARGS
			res = single_pass(itm)
			!isempty(res) && (args[chopprefix(itm, "-")] = res)
		end
	end

	if args["s"]
		lines = filter(!isempty, readlines(stdin))
		append!(args["source"], lines)
	end

	if !isempty(args["u"])
		push!(args["source"], args["u"])
	end

	if !isempty(args["ul"])
		file = args["ul"]
		if isfile(file)
			lines = filter(!isempty, readlines(file))
			append!(args["source"], lines)
		end
	end

	if !isempty(args["w"])
		file = args["w"]
		if isfile(file)
			args["w"] = filter(!isempty, readlines(file))
		end
	end

	if !isempty(args["e"])
		file = args["e"]
		if isfile(file)
			args["e"] = filter(!isempty, readlines(file))
		end
	end

	for item in ("n", "y", "m", "d")
		if !isempty(args[item])
			args[item] = number_sequence(args[item])
		end
	end

	return args
end
