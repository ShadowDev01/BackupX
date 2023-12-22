using JSON
using OrderedCollections
using LibCURL


"""
USE TO PARSE DIFFERENT PARTS OF URL

for example:
    
https://admin:test1234@login.admin-auth.company.co.com:443/admin/desk/master.js?A=line+25&B=#12&C#justfortest

"""
struct URL
    rawurl::String                          # raw url without decode
    url::String                             # decoded url
    scheme::String                          # https
    username::String                        # admin
    password::String                        # test1234
    authenticate::String                    # admin:test1234
    host::String                            # login.admin-auth.company.co.com 
    subdomain::String                       # login.admin-auth
    domain::String                          # company
    tld::String                             # co.com
    port::String                            # 443
    path::String                            # /admin/desk/master.js
    directory::String                       # /admin/desk
    file::String                            # master.js
    file_name::String                       # master
    file_extension::String                  # js
    query::String                           # A=line+25&B=#12&C
    fragment::String                        # justfortest
    parameters::Vector{String}              # ["A", "B", "C"]
    parameters_count::Int32                 # 3
    parameters_value::Vector{String}        # ["line+25", "#12"]
    parameters_value_count::Int32           # 2

    # From the beginning of URL to the given section
    _scheme::String                         # https://
    _auth::String                           # https://admin:test1234@
    _host::String                           # https://admin:test1234@login.admin-auth.company.co.com:
    _port::String                           # https://admin:test1234@login.admin-auth.company.co.com:443
    _path::String                           # https://admin:test1234@login.admin-auth.company.co.com:443/admin/desk/master.js
    _query::String                          # https://admin:test1234@login.admin-auth.company.co.com:443/admin/desk/master.js?A=line+25&B=#12&C
    _fragment::String                       # https://admin:test1234@login.admin-auth.company.co.com:443/admin/desk/master.js?A=line+25&B=#12&C#justfortest
end

function URL_Decode(url::AbstractString)
    while occursin(r"(\%[0-9a-fA-F]{2})", url)                    # As long as the %hex exists, it will continue to url docode
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

function HTML_Decode(url::AbstractString)
    # HTML HEX, DEC Decode
    while occursin(r"&#(?<number>[a-zA-Z0-9]+);", url)                  # As long as the &#(hex|dec) exists, it will continue to url docode
        for encoded in eachmatch(r"&#(?<number>[a-zA-Z0-9]+);", url)
            n = encoded["number"]
            num = parse(Int, startswith(n, "x") ? "0$n" : n)
            url = replace(url, encoded.match => Char(num))
        end
    end

    # HTML Symbol Decode
    while occursin(r"&(gt|lt|quot|apos|amp);"i, url)
        url = replace(url, r"&gt;"i => ">", r"&lt;"i => "<", r"&quot;"i => "\"", r"&apos;"i => "'", r"&amp;"i => "&")
    end

    return url
end

# replace nothing type with ""
function check_str(input::Union{AbstractString,Nothing})
    !isnothing(input) ? input : ""
end

# extract subdomain, domain & tld from host
function split_domain(host::String)
    # extract tld
    file = isfile("tlds.txt") ? "tlds.txt" : "src/tlds.txt"
    tlds = Set{AbstractString}()
    for line in eachline(file)
        occursin(Regex("\\b$line\\b\\Z"), host) && push!(tlds, line)
    end
    tld = argmax(length, tlds)[2:end]

    # extract subdomain & domain
    host = replace(host, ".$tld" => "")
    rest = rsplit(host, ".", limit=2)
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
function SubCombination(url::URL)
    subdomain::String = url.subdomain
    unique(vcat([subdomain], split(subdomain, r"[\.\-]"), split(subdomain, ".")))
end

# split name & extension of file
function split_file(file::String)
    if occursin(".", file)
        split(file, ".", limit=2, keepempty=true)
    else
        split(file * ".", ".", limit=2, keepempty=true)
    end
end

# Extract Query Parameters
function QueryParams(query::AbstractString)
    result = String[]
    regex::Regex = r"[\?\&\;]([\w\-\~\+\%]+)"
    for param in eachmatch(regex, query)
        append!(result, param.captures)
    end
    return unique(result)
end

# Extract Query Parameters Values
function QueryParamsValues(query::AbstractString)
    result = String[]
    regex::Regex = r"\=([\w\-\%\.\:\~\,\"\'\<\>\=\(\)\`\{\}\$\+\/\;\#]*)?"
    for param in eachmatch(regex, query)
        append!(result, param.captures)
    end
    return unique(filter(!isempty, result))
end

function URL(Url::AbstractString)
    url::String = Url |> URL_Decode |> HTML_Decode
    url = chopprefix(url, "*.")
    regex::Regex = r"^((?<scheme>([a-zA-Z]+)):\/\/)?((?<username>([\w\-]+))\:?(?<password>(.*?))\@)?(?<host>([\w\-\.]+)):?(?<port>(\d+))?(?<path>([\/\w\-\.\%\,\"\'\<\>\=\(\)]+))?(?<query>\?(.*?))?(?<fragment>(?<!\=)\#([^\#]*?))?$"
    parts = match(regex, url)

    rawurl::String = Url
    Url::String = url
    scheme::String = check_str(parts["scheme"])
    username::String = check_str(parts["username"])
    password::String = check_str(parts["password"])
    authenticate::String = chopsuffix(check_str(parts[4]), "@")
    host::String = chopprefix(check_str(parts["host"]), "www.")
    subdomain::String, domain::String, tld::String = split_domain(host)
    port::String = check_str(parts["port"])
    path::String = check_str(parts["path"])
    directory::String = dirname(path)
    file::String = basename(path)
    file_name::String, file_extension::String = split_file(file)
    query::String = check_str(parts["query"])
    fragment::String = check_str(parts[18])
    parameters::Vector{String} = QueryParams(query)
    parameters_count::Int32 = length(parameters)
    parameters_value::Vector{String} = QueryParamsValues(query)
    parameters_value_count::Int32 = length(parameters_value)

    _scheme::String = check_str(parts[1])
    _auth::String = _scheme * check_str(parts[4])
    _host::String = match(r"^((?<scheme>([a-zA-Z]+)):\/\/)?((?<username>([\w\-]+))\:?(?<password>(.*?))\@)?(?<host>([\w\-\.]+)):?", url).match
    _port::String = _host * port
    _path::String = _port * path
    _query::String = _path * query
    _fragment::String = url

    return URL(rawurl, Url, scheme, username, password, authenticate, host, subdomain, domain, tld, port, path, directory, file, file_name, file_extension, query, fragment, parameters, parameters_count, parameters_value, parameters_value_count, _scheme, _auth, _host, _port, _path, _query, _fragment)
end

# JSON output of URL sections
function Json(url::URL)
    push!(JSON_DATA, OrderedDict{String,Any}(
        "rawurl" => url.rawurl,
        "url" => url.url,
        "scheme" => url.scheme,
        "username" => url.username,
        "password" => url.password,
        "authenticate" => url.authenticate,
        "host" => url.host,
        "subdomain" => url.subdomain,
        "subdomain_combination" => SubCombination(url),
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
    ))
end

# text output of URL sections
function SHOW(url::URL)
    cyan::String = "\u001b[36m"
    yellow::String = "\u001b[33m"
    nc::String = "\033[0m"

    items = """
    * $(cyan)rawurl:$(nc)         $(url.rawurl)
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
    * $(cyan)subdomain_comb:$(nc) $(join(SubCombination(url), " "))
    * $(cyan)parameters:$(nc)     $(join(url.parameters, " "))
    * $(cyan)params count:$(nc)   $(url.parameters_count)
    * $(cyan)values:$(nc)         $(join(url.parameters_value, " "))
    * $(cyan)value count:$(nc)    $(url.parameters_value_count)
    """
    println(items)
end