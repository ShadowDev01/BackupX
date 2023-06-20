include("src/args.jl")
include("src/URL.jl")
import JSON

function generate(;urls, text_patterns, date_ptterns, words, nums, years, months, days, exts, output)
    res = Set{AbstractString}()
    Threads.@threads for url in urls
        u = URL(url)
        for pattern in text_patterns
            pattern = replace(pattern, "\$" => "")
            for num in nums
                for word in words
                    for ext in exts
                        out = replace(
                            pattern,
                            "full_domain" => u.host,
                            "domain_name" => u.domain,
                            "subdomain" => u.subdomain,
                            "full_path" => u.path,
                            "path" => u.directory,
                            "file_name" => u.file,
                            "tld" => u.tld,
                            "num" => num,
                            "word" => word,
                            "ext" => ext
                        )
                        push!(res, out)
                    end
                end
            end
        end
        for pattern in date_ptterns
            pattern = replace(pattern, "\$" => "", "%" => "")
            for year in years
                for month in months
                    for day in days
                        for ext in exts
                            out = replace(
                                pattern,
                                "full_domain" => u.host,
                                "domain_name" => u.domain,
                                "subdomain" => u.subdomain,
                                "full_path" => u.path,
                                "path" => u.directory,
                                "file_name" => u.file,
                                "tld" => u.tld,
                                "y" => year,
                                "m" => month,
                                "d" => day,
                                "ext" => ext
                            )
                            push!(res, out)
                        end
                    end
                end
            end
        end
    end
    if !isnothing(output)
        open(output, "w+") do f
            write(f, join(res, "\n"))
        end
    else
        println(join(res, "\n"))
    end
end

function main()
    arguments = ARGUMENTS()
    AllPatterns::Dict = open(arguments["pattern"]) do f
        JSON.parse(read(f, String))
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
        generate(urls=readlines(stdin), text_patterns=AllPatterns["patterns"], date_ptterns=AllPatterns["date-formats"], words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)
    elseif !isnothing(arguments["url"])
        generate(urls=[arguments["url"]], text_patterns=AllPatterns["patterns"], date_ptterns=AllPatterns["date-formats"], words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)
    elseif !isnothing(arguments["urls"])
        generate(urls=arguments["urls"], text_patterns=AllPatterns["patterns"], date_ptterns=AllPatterns["date-formats"], words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)
    end
end

main()