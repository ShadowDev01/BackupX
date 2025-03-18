using LibCURL


"""
PARSE URL PARTS
for example:
https://admin:test1234@login.admin-auth.company.co.com:443/admin/desk/master.js?A=line+25&B=#12&C#justfortest

"""
struct URL
	raw_url::String              # raw url without decode
	decoded_url::String          # decoded url
	scheme::String               # https
	username::String             # admin
	password::String             # test1234
	auth::String                 # admin:test1234
	host::String                 # login.admin-auth.company.co.com 
	subdomain::String            # login.admin-auth
	domain::String               # company
	tld::String                  # co.com
	port::String                 # 443
	path::String                 # /admin/desk/master.js
	directory::String            # /admin/desk
	file::String                 # master.js
	file_name::String            # master
	file_ext::String             # js
	query::String                # A=line+25&B=#12&C
	fragment::String             # justfortest

	# extended url parts
	_scheme::String
	_auth::String
	_host::String
	_port::String
	_path::String
	_query::String
	_fragment::String
end

function URL(input_url::String)::URL
	url::String = input_url |> URL_Decode |> HTML_Decode
	url = chopprefix(url, "*.")
	regex::Regex = r"^((?<scheme>([a-zA-Z]+)):\/\/)?((?<username>([\w\-]+))\:?(?<password>(.*?))\@)?(?<host>([\w\-\.]+)):?(?<port>(\d+))?(?<path>([\/\w\-\.\%\,\"\'\<\>\=\(\)]+))?(?<query>\?(.*?))?(?<fragment>(?<!\=)\#([^\#]*?))?$"
	parts = match(regex, url)

	raw_url::String = input_url
	decoded_url::String = url
	scheme::String = parts["scheme"] |> isExist
	username::String = parts["username"] |> isExist
	password::String = parts["password"] |> isExist
	auth::String = chopsuffix(parts[4] |> isExist, "@")
	host::String = chopprefix(parts["host"] |> isExist, "www.")
	subdomain::String, domain::String, tld::String = split_domain(host)
	port::String = parts["port"] |> isExist
	path::String = parts["path"] |> isExist
	directory::String = dirname(path)
	file::String = basename(path)
	file_name::String, file_ext::String = split_file(file)
	query::String = parts["query"] |> isExist
	fragment::String = parts[18] |> isExist

	_scheme::String = parts[1] |> isExist
	_auth::String = _scheme * isExist(parts[4])
	_host::String = _auth * isExist(parts[10])
	_port::String = isempty(port) ? _host * port : _host * ":" * port
	_path::String = _port * path
	_query::String = _path * query
	_fragment::String = decoded_url

	return URL(
		raw_url, decoded_url, scheme,
		username, password, auth,
		host, subdomain, domain,
		tld, port, path, directory,
		file, file_name, file_ext,
		query, fragment, _scheme,
		_auth, _host, _port, _path,
		_query, _fragment,
	)
end

isExist(input) = isnothing(input) ? "" : input

function URL_Decode(url::String)::String
	while occursin(r"(\%[0-9a-fA-F]{2})", url)         # As long as the %hex exists, it will continue to url docode
		curl = curl_easy_init()
		output_ptr = C_NULL
		output_len = Ref{Cint}()
		output_ptr = curl_easy_unescape(curl, url, 0, output_len)
		url = unsafe_string(output_ptr)
		curl_free(output_ptr)
		curl_easy_cleanup(curl)
	end
	return url
end


# HTML Decode (HEX / DEC)
function HTML_Decode(url::String)::String
	# As long as the &#(hex|dec) exists, it will continue to url docode
	while occursin(r"&#(?<number>[a-zA-Z0-9]+);", url)
		for encoded in eachmatch(r"&#(?<number>[a-zA-Z0-9]+);", url)
			n = encoded["number"]
			num = parse(Int, startswith(n, "x") ? "0$n" : n)
			url = replace(url, encoded.match => Char(num))
		end
	end

	# HTML Symbol Decode
	while occursin(r"&(gt|lt|quot|apos|amp);"i, url)
		url = replace(
			url,
			r"&gt;"i => ">",
			r"&lt;"i => "<",
			r"&quot;"i => "\"",
			r"&apos;"i => "'",
			r"&amp;"i => "&",
		)
	end
	return url
end

const TLDs = begin
	file = isfile("tlds.txt") ? "tlds.txt" : "src/tlds.txt"
	readlines(file) |> Set
end

# extract subdomain, domain & tld from host
function split_domain(host::String)
	# extract tld
	tlds = Set{String}()
	for tld in TLDs
		endswith(host, tld) && push!(tlds, tld)
	end

	tld = argmax(length, tlds)[2:end]

	# extract subdomain & domain
	host = replace(host, ".$tld" => "")
	rest = rsplit(host, ".", limit = 2)
	if length(rest) > 1
		subdomain, domain = rest
	else
		subdomain = ""
		domain = rest[1]
	end

	return (subdomain, domain, tld)
end


"""
make combination of subdomain 
login.admin-auth => ["login.admin-auth", "login", "admin", "auth", "admin-auth"]
"""
function SubCombination(subdomain::String)::Vector{String}
	unique(vcat(
		[subdomain],
		split(subdomain, r"[\.\-]"),
		split(subdomain, "."))
	)
end

# split name & extension of file
function split_file(file::String)::Vector{String}
	if occursin(".", file)
		split(file, ".", limit = 2, keepempty = true)
	else
		split(file * ".", ".", limit = 2, keepempty = true)
	end
end

# Extract Query Parameters
function QueryParams(query::String)::Vector{String}
	result = String[]
	regex::Regex = r"[\?\&\;]([\w\-\~\+\%]+)"
	for param in eachmatch(regex, query)
		append!(result, param.captures)
	end
	return unique(result)
end

# Extract Query Parameters Values
function QueryParamsValues(query::String)::Vector{String}
	result = String[]
	regex::Regex = r"\=([\w\-\%\.\:\~\,\"\'\<\>\=\(\)\`\{\}\$\+\/\;\#]*)?"
	for param in eachmatch(regex, query)
		append!(result, param.captures)
	end
	return unique(filter(!isempty, result))
end

# extract Query parameters - values in key:value pairs
function QueryPairs(query::String)
	d = OrderedDict{String, Any}()
	query = chopprefix(query, "?")
	isempty(query) && return d

	for item in eachsplit(query, "&")
		if !occursin("=", item)
			item *= "="
		end
		k, v = split(item, "=")
		v == "null" && (v = nothing)
		d[k] = v
	end
	return d
end


@inline function url_vars(url::URL)
	Dict{String, Vector{String}}(
		"scheme" => String[url.scheme],
		"username" => String[url.username],
		"password" => String[url.password],
		"host" => String[url.host],
		"domain" => String[url.domain],
		"tld" => String[url.tld],
		"port" => String[url.port],
		"path" => String[url.path],
		"directory" => String[url.directory],
		"file" => String[url.file],
		"fileN" => String[url.file_name],
		"fileE" => String[url.file_ext],
		"query" => String[url.query],
		"fragment" => String[url.fragment],
		"subdomain" => SubCombination(url.subdomain),
	)
end
