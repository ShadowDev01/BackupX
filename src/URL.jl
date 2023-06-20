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

function URL(url::String)
    url::String = replace(url, "www." => "")
    parts = match(r"^(\w+):\/\/(([\w\-]+):(.+)\@)?(([\w\-]+\.)?([\w\-]+)\.([\w\-]+)):?(\d+)?([\/,\w\.]+)?(\?[^\#]*)?(\#.*)?", url).captures
    replace!(parts, nothing => "")
    deleteat!(parts,2)
    scheme::String = parts[1]
    username::String = parts[2]
    password::String = parts[3]
    host::String = parts[4]
    subdomain::String = strip(parts[5], '.')
    domain::String = strip(parts[6], '.')
    tld::String = strip(parts[7], '.')
    port::String = parts[8]
    path::String = parts[9]
    dirctory::String = dirname(path)
    file::String = basename(path)
    query::String = parts[10]
    fragment::String  = parts[11]
    return URL(scheme, username, password, host, subdomain, domain, tld, port, path, dirctory, file, query, fragment)
 end