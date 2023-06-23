include("src/args.jl")
include("src/URL.jl")
using JSON
using Printf

function generate(;urls, patterns, words, nums, years, months, days, exts, output)
    res = String[]

    for url in urls
        u = URL(url)
        global scheme, username, password, host, subdomain, domain, tld, port, path, directory, file, query, fragment = map(x -> [x], u.all)
        global word = words
        global num = nums
        global y = years
        global m = months
        global d  = days
        global ext = exts

        for pattern in patterns
            printf = replace(pattern, "\$" => "%s" ,"%" => "%d", isletter => "") |> Printf.Format
            edit = split(pattern, !isletter, keepempty=false)
            mix = map(eval ∘ Meta.parse, edit)
            for items in Iterators.product(mix...)
               push!(res, Printf.format(printf, items...))
            end
        end
    end

    if !isnothing(output)
        open(output, "w+") do f
            write(f, join(res, "\n"))
        end
    else
        print(join(res, "\n"))
    end
end

function main()
    arguments = ARGUMENTS()
    patterns = open(arguments["pattern"], "r") do f
        D = read(f, String) |> JSON.parse
        A = String[]
        for key in keys(D)
            append!(A, D[key])
        end
        A
    end
    words = !isnothing(arguments["wordlist"]) ? readlines(arguments["wordlist"]) : [""]
    ext = !isnothing(arguments["extension"]) ? readlines(arguments["extension"]) : [""]
    number = if !isnothing(arguments["number"])
        x = map(n -> parse(Int64, strip(n)), split(arguments["number"], "-"))
        collect(x[1]:x[2])
    else
        [""]
    end
    years = if !isnothing(arguments["year"])
        x = map(n -> parse(Int64, strip(n)), split(arguments["year"], "-"))
        collect(x[1]:x[2])
    else
        [""]
    end
    months = if !isnothing(arguments["month"])
        x = map(n -> parse(Int64, strip(n)), split(arguments["month"], "-"))
        collect(x[1]:x[2])
    else
        [""]
    end
    days = if !isnothing(arguments["day"])
        x = map(n -> parse(Int64, strip(n)), split(arguments["day"], "-"))
        collect(x[1]:x[2])
    else
        [""]
    end
    output = arguments["output"]
    if arguments["stdin"]
        generate(urls=readlines(stdin), patterns=patterns, words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)
    elseif !isnothing(arguments["url"])
        generate(urls=[arguments["url"]], patterns=patterns, words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)
    elseif !isnothing(arguments["urls"])
        generate(urls=arguments["urls"], patterns=patterns, words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)
    end
end

main()