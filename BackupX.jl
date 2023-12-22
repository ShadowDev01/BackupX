include("src/args.jl")
include("src/URL.jl")

using JSON
using Printf
using OrderedCollections

RESULT = OrderedSet{String}()

function GenerateBackupNames(; urls, patterns, words, nums, years, months, days, exts, output)
    for u in urls
        url = URL(u)
        global scheme = String[url.scheme]
        global username = String[url.username]
        global password = String[url.password]
        global host = String[url.host]
        global subdomain = String[url.subdomain]
        global domain = String[url.domain]
        global tld = String[url.tld]
        global port = String[url.port]
        global path = String[url.path]
        global directory = String[url.directory]
        global file = String[url.file]
        global fileN = String[url.file_name]
        global fileE = String[url.file_extension]
        global query = String[url.query]
        global fragment = String[url.fragment]
        subdomain = SubCombination(url)
        global word = words
        global num = nums
        global y = years
        global m = months
        global d = days
        global ext = exts

        Threads.@threads for pattern in patterns
            printf = replace(pattern, "\$" => "%s", "%" => "%s", isletter => "") |> Printf.Format
            edit = split(pattern, !isletter, keepempty=false)
            mix = map(eval ∘ Meta.parse, edit)
            for items in Iterators.product(mix...)
                push!(RESULT, Printf.format(printf, items...))
            end
        end

    end
end

function NumberSequence(range::String, padding::Int=1)
    try
        numbers = map(number -> parse(Int64, strip(number)), split(range, "-"))
        if numbers[1] > numbers[2]
            @error "Incorrect Range: $range\nCorrect: $(numbers[2])-$(numbers[1])"
            exit(0)
        end
        sequence = map(number -> string(number, pad=padding), collect(numbers[1]:numbers[2]))
    catch e
        if isa(e, ArgumentError)
            @error "Range Should be Numbers: $range"
            exit(0)
        end
    end
end

function OpenPatterns(FilePath::String)
    if !isfile(FilePath)
        @error "No Such File or Directory: $FilePath"
        exit(0)
    end

    File = try
        pattern = read(FilePath, String) |> JSON.parse
        KEYS = String[]
        for key in keys(pattern)
            append!(KEYS, pattern[key])
        end
        KEYS
    catch e
        @warn sprint(showerror, e) file = FilePath
        exit(0)
    end
end

function ReadNonEmptyLines(FilePath::String)
    if isfile(FilePath)
        filter(!isempty, readlines(FilePath))
    else
        @error "Not Such File or Directory: $FilePath"
        exit(0)
    end
end

function main()
    # Get User Passed CLI Argument
    arguments = ARGUMENTS()

    # Extract Arguments
    # Input URLS
    URLS = String[]
    Url = arguments["url"]
    Urls = arguments["urls"]
    stdin = arguments["stdin"]

    # Reading Files
    patterns = arguments["pattern"] |> OpenPatterns
    words = !isnothing(arguments["wordlist"]) ? ReadNonEmptyLines(arguments["wordlist"]) : [""]
    ext = !isnothing(arguments["extension"]) ? ReadNonEmptyLines(arguments["extension"]) : [""]

    # Number Ranges
    number = !isnothing(arguments["number"]) ? NumberSequence(arguments["number"]) : [""]
    years = !isnothing(arguments["year"]) ? NumberSequence(arguments["year"]) : [""]
    months = !isnothing(arguments["month"]) ? NumberSequence(arguments["month"], 2) : [""]
    days = !isnothing(arguments["day"]) ? NumberSequence(arguments["day"], 2) : [""]

    output = arguments["output"]

    if stdin
        URLS = readlines(stdin)
    elseif !isempty(Url)
        URLS = [Url]
    elseif !isempty(Urls)
        URLS = ReadNonEmptyLines(Urls)
    end

    GenerateBackupNames(urls=URLS, patterns=patterns, words=words, nums=number, years=years, months=months, days=days, exts=ext, output=output)

    if !isnothing(output)
        open(output, "w+") do file
            write(file, join(RESULT, "\n"))
        end
    else
        print(join(RESULT, "\n"))
    end

end

main()