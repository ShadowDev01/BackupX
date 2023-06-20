struct URL
    scheme::String
    username::String
    password::String
    host::String
    subdomain::String
    domain::String
    tld::String
    port::String
    path::String
    directory::String
    file::String
    query::String
    fragment::String
end

function extract(host)
    tlds = Set()
    for line in eachline("tlds.txt")
        occursin(Regex("\\b$line\\b"), host) && push!(tlds, line)
    end
    tld = collect(tlds)[findmax(length, collect(tlds))[2]]
    rest = rsplit(replace(host, tld => ""), ".", limit=2)
    if length(rest) > 1
        subdomain, domain = rest
    else
        subdomain = ""
        domain = rest[1]
    end
    return (subdomain, domain, strip(tld, '.'))
end

function URL(url::AbstractString)
    url::String = replace(url, "www." => "")
    parts = match(r"^(\w+):\/\/(([\w\-]+):(.+)\@)?([\w\-\.]+):?(\d+)?([\/,\w\.]+)?(\?[^\#]*)?(\#.*)?", url).captures
    replace!(parts, nothing => "")
    deleteat!(parts, 2)
    scheme::String = parts[1]
    username::String = parts[2]
    password::String = parts[3]
    host::String = parts[4]
    subdomain::String, domain::String, tld::String = extract(host)
    port::String = parts[5]
    path::String = parts[6]
    dirctory::String = dirname(path)
    file::String = basename(path)
    query::String = parts[7]
    fragment::String  = parts[8]
    return URL(scheme, username, password, host, subdomain, domain, tld, port, path, dirctory, file, query, fragment)
end