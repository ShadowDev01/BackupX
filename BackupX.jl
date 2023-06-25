include("src/args.jl")
include("src/URL.jl")
using JSON
using Printf

function generate(; urls, patterns, words, nums, years, months, days, exts, output)
    res = String[]

    for url in urls
        u = URL(url)
        global scheme, username, password, host, subdomain, domain, tld, port, path, directory, file, query, fragment = map(x -> [x], u.all)
        subdomain = _subs(subdomain...)
        global word = words
        global num = nums
        global y = years
        global m = months
        global d = days
        global ext = exts

        for pattern in patterns
            printf = replace(pattern, "\$" => "%s", "%" => "%s", isletter => "") |> Printf.Format
            edit = split(pattern, !isletter, keepempty=false)
            mix = map(eval ∘ Meta.parse, edit)
            for items in Iterators.product(mix...)
                push!(res, Printf.format(printf, items...))
            end
        end
    end

    if !isnothing(output)
        open(output, "w+") do f
            write(f, join(unique(res), "\n"))
        end
    else
        print(join(unique(res), "\n"))
    end
end

function numbers(s::String, p::Int=1)
    x = map(n -> parse(Int64, strip(n)), split(s, "-"))
    map(i -> string(i, pad=p), collect(x[1]:x[2]))
end

function main()
    arguments = ARGUMENTS()
    
    patterns = open(arguments["pattern"], "r") do f
        try
            D = read(f, String) |> JSON.parse
            A = String[]
            for key in keys(D)
                append!(A, D[key])
            end
            A
        catch e
            @warn sprint(showerror, e) file=arguments["pattern"]
            exit(0)
        end
    end

    words = !isnothing(arguments["wordlist"]) ? readlines(arguments["wordlist"]) : [""]
    ext = !isnothing(arguments["extension"]) ? readlines(arguments["extension"]) : [""]
    number = !isnothing(arguments["number"]) ? numbers(arguments["number"]) : [""]
    years = !isnothing(arguments["year"]) ? numbers(arguments["year"]) : [""]
    months = !isnothing(arguments["month"]) ? numbers(arguments["month"], 2) : [""]
    days = !isnothing(arguments["day"]) ? numbers(arguments["day"], 2) : [""]
    output = arguments["output"]

    if arguments["stdin"]
        generate(urls=readlines(stdin), patterns=patterns, words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)
    elseif !isnothing(arguments["url"])
        generate(urls=[arguments["url"]], patterns=patterns, words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)
    elseif !isnothing(arguments["urls"])
        generate(urls=readlines(arguments["urls"]), patterns=patterns, words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)
    end
end

main()