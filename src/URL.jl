using JSON
using OrderedCollections
using LibCURL

struct URL
    url::String
    scheme::String
    username::String
    password::String
    authenticate::String
    host::String
    subdomain::String
    domain::String
    tld::String
    port::String
    path::String
    directory::String
    file::String
    file_name::String
    file_extension::String
    query::String
    fragment::String
    parameters::Vector{String}
    parameters_count::Int32
    parameters_value::Vector{String}
    parameters_value_count::Int32

    _scheme::String
    _auth::String
    _host::String
    _port::String
    _path::String
    _query::String
    _fragment::String
end

function Decode(st::AbstractString)
    while occursin(r"(\%[0-9a-fA-F]{2})", st)
        curl = curl_easy_init()
        output_ptr = C_NULL
        output_len = Ref{Cint}()
        output_ptr = curl_easy_unescape(curl, st, 0, output_len)
        st = unsafe_string(output_ptr)
        curl_free(output_ptr)
        curl_easy_cleanup(curl)
    end

    decode = Dict{Regex,String}(
        r"&quot;" => "\"",
        r"amp;" => "",
        r"&lt;" => "<",
        r"&gt;" => ">",
        r"&#39;" => "'"
    )
    return replace(replace(st, decode...), "&&" => "&")
end

function check_str(input::Union{AbstractString,Nothing})
    !isnothing(input) ? input : ""
end

function extract(host::String)
    tlds = Set()
    for line in eachline("src/tlds.txt")
        occursin(Regex("\\b$line\\b\\Z"), host) && push!(tlds, line)
    end
    tld = argmax(length, tlds)
    rest = rsplit(replace(host, tld => ""), ".", limit=2)
    if length(rest) > 1
        subdomain, domain = rest
    else
        subdomain = ""
        domain = rest[1]
    end
    return (subdomain, domain, strip(tld, '.'))
end

function file_apart(file::String)
    file_name::String, file_extension::String = occursin(".", file) ? split(file, ".", limit=2, keepempty=true) : split(file * ".", ".", limit=2, keepempty=true)
    return file_name, file_extension
end

function _parameters(query::AbstractString)
    res = String[]
    reg = r"[\?\&\;]([\w\-\~\+\%]+)"
    for param in eachmatch(reg, query)
        append!(res, param.captures)
    end
    return unique(res)
end

function _subs(url::URL)
    subdomain::String = url.subdomain
    unique(vcat([subdomain], split(subdomain, r"[\.\-]"), split(subdomain, ".")))
end

function _parameters_value(query::AbstractString; count::Bool=false)
    res = String[]
    reg = r"\=([\w\-\%\.\:\~\,\"\'\<\>\=\(\)\`\{\}\$\+\/\;\#]*)?"
    for param in eachmatch(reg, query)
        append!(res, param.captures)
    end
    if count
        return length(res)
    end
    return unique(filter(!isempty, res))
end

function Json(url::URL)
    parts = OrderedDict{String,Any}(
        "url" => url.url,
        "scheme" => url.scheme,
        "username" => url.username,
        "password" => url.password,
        "authenticate" => url.authenticate,
        "host" => url.host,
        "subdomain" => url.subdomain,
        "subdomain_combination" => _subs(url),
        "domain" => url.domain,
        "tld" => url.tld,
        "port" => url.port,
        "path" => url.path,
        "directory" => url.directory,
        "file" => url.file,
        "file_name" => url.file_name,
        "file_ext" => url.file_extension,
        "query" => chopprefix(url.query, "?"),
        "fragment" => url.fragment,
        "parameters" => url.parameters,
        "parameters_count" => url.parameters_count,
        "parameters_value" => url.parameters_value,
        "parameters_value_count" => url.parameters_value_count,
    )
    JSON.print(parts, 4)
end

function SHOW(url::URL)
    cyan::String = "\u001b[36m"
    yellow::String = "\u001b[33m"
    nc::String = "\033[0m"

    items = """
    * $(cyan)url:$(nc)            $(url.url)
    * $(cyan)scheme:$(nc)         $(url.scheme)
    * $(cyan)username:$(nc)       $(url.username)
    * $(cyan)password:$(nc)       $(url.password)
    * $(cyan)auth:$(nc)           $(url.authenticate)
    * $(cyan)host:$(nc)           $(url.host)
    * $(cyan)subdomain:$(nc)      $(url.subdomain)
    * $(cyan)domain:$(nc)         $(url.domain)
    * $(cyan)tld:$(nc)            $(url.tld)
    * $(cyan)port:$(nc)           $(url.port)
    * $(cyan)path:$(nc)           $(url.path)
    * $(cyan)directory:$(nc)      $(url.directory)
    * $(cyan)file:$(nc)           $(url.file)
    * $(cyan)file_name:$(nc)      $(url.file_name)
    * $(cyan)file_ext:$(nc)       $(url.file_extension)
    * $(cyan)query:$(nc)          $(url.query)
    * $(cyan)fragment:$(nc)       $(url.fragment)
    * $(cyan)subdomain_comb:$(nc) $(join(_subs(url), " "))
    * $(cyan)parameters:$(nc)     $(join(url.parameters, " "))
    * $(cyan)params count:$(nc)   $(url.parameters_count)
    * $(cyan)values:$(nc)         $(join(url.parameters_value, " "))
    * $(cyan)value count:$(nc)    $(url.parameters_value_count)
    """
    println(items)
end


function URL(Url::AbstractString)
    url::String = Decode(Url)
    url = chopprefix(url, "*.")
    parts = match(r"^((?<scheme>([a-zA-Z]+)):\/\/)?((?<username>([\w\-]+))\:?(?<password>(.*?))\@)?(?<host>([\w\-\.]+)):?(?<port>(\d+))?(?<path>([\/\w\-\.\%\,\"\'\<\>\=\(\)]+))?(?<query>\?(.*?))?(?<fragment>(?<!\=)\#([^\#]*?))?$", url)

    Url::String = url
    scheme::String = check_str(parts["scheme"])
    username::String = check_str(parts["username"])
    password::String = check_str(parts["password"])
    authenticate::String = chopsuffix(check_str(parts[4]), "@")
    host::String = chopprefix(check_str(parts["host"]), "www.")
    subdomain::String, domain::String, tld::String = extract(host)
    port::String = check_str(parts["port"])
    path::String = check_str(parts["path"])
    directory::String = dirname(path)
    file::String = basename(path)
    file_name::String, file_extension::String = file_apart(file)
    query::String = check_str(parts["query"])
    fragment::String = check_str(parts[18])
    parameters::Vector{String} = _parameters(query)
    parameters_count::Int32 = length(parameters)
    parameters_value::Vector{String} = _parameters_value(query)
    parameters_value_count::Int32 = _parameters_value(query, count=true)

    _scheme::String = check_str(parts[1])
    _auth::String = _scheme * check_str(parts[4])
    _host::String = match(r"^((?<scheme>([a-zA-Z]+)):\/\/)?((?<username>([\w\-]+))\:?(?<password>(.*?))\@)?(?<host>([\w\-\.]+)):?", url).match
    _port::String = _host * port
    _path::String = _port * path
    _query::String = _path * query
    _fragment::String = url

    return URL(Url, scheme, username, password, authenticate, host, subdomain, domain, tld, port, path, directory, file, file_name, file_extension, query, fragment, parameters, parameters_count, parameters_value, parameters_value_count, _scheme, _auth, _host, _port, _path, _query, _fragment)
end