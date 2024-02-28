include("src/banner.jl")
include("src/args.jl")
include("src/URL.jl")

using JSON
using Printf
using OrderedCollections

const args = ARGUMENTS()
RESULT = OrderedSet{String}()

const colorReset = "\033[0m"
const colorRed = "\033[31m"
const colorLightRed = "\033[91m"
const colorGreen = "\033[32m"
const colorYellow = "\033[33m"
const colorLightYellow = "\033[93m"
const colorBlue = "\033[34m"
const colorLightBlue = "\033[94m"
const colorCyan = "\033[96m"
const colorMagenta = "\033[35m"
const colorLightMagenta = "\033[95m"
const colorWhite = "\033[97m"
const colorBlack = "\033[30m"
const textItalic = "\033[3m"
const textBold = "\033[1m"
const textBox = "\033[7m"
const textBlink = "\033[5m"

function GenerateBackupNames(; urls, patterns, words, nums, years, months, days, exts)
    Threads.@threads for u in urls
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
            try
                printf = replace(pattern, "\$" => "%s", "%" => "%s", isletter => "") |> Printf.Format
                edit = split(pattern, !isletter, keepempty=false)
                mix = map(eval ∘ Meta.parse, edit)
                for items in Iterators.product(mix...)
                    push!(RESULT, Printf.format(printf, items...))
                end
            catch err
                @error sprint(showerror, err)
                exit(0)
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

function check_pattern_var(patterns::Vector{String})
    pat_vars = ("scheme", "username", "password", "host", "subdomain", "domain", "tld", "port", "path", "directory", "file", "fileN", "fileE", "query", "fragment", "word", "ext", "num", "y", "m", "d")
    found_vars = Set{String}()

    for pat in patterns
        push!(found_vars, split(pat, !isletter, keepempty=false)...)
    end

    if !issubset(found_vars, pat_vars)
        @error "$(setdiff(found_vars, pat_vars) |> collect) variables not supported -> $(args["p"]) ❎"
        exit(0)
    end
end

function OpenPatterns(FilePath::String)
    if !isfile(FilePath)
        @error "No Such File or Directory: $FilePath"
        exit(0)
    end

    File = try
        patterns = read(FilePath, String) |> JSON.parse
        sub_patterns = String[]

        for key in keys(patterns)
            append!(sub_patterns, patterns[key])
        end

        check_pattern_var(sub_patterns)

        sub_patterns
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
    URLS = String[]

    @info "Checking Patterns 🔍"
    patterns = args["p"] |> OpenPatterns
    @info "$colorYellow$(length(patterns))$colorReset Patterns Parsed ✅"

    words = !isempty(args["w"]) ? ReadNonEmptyLines(args["w"]) : [""]
    ext = !isempty(args["e"]) ? ReadNonEmptyLines(args["e"]) : [""]

    # Number Ranges
    number = !isempty(args["n"]) ? NumberSequence(args["n"]) : [""]
    years = !isempty(args["year"]) ? NumberSequence(args["year"]) : [""]
    months = !isempty(args["month"]) ? NumberSequence(args["month"], 2) : [""]
    days = !isempty(args["day"]) ? NumberSequence(args["day"], 2) : [""]

    if args["s"]
        URLS = filter(!isempty, readlines(stdin))
    elseif !isempty(args["u"])
        URLS = [args["u"]]
    elseif !isempty(args["U"])
        URLS = ReadNonEmptyLines(args["U"])
    end

    @info "Generating... 🛠️"
    GenerateBackupNames(urls=URLS, patterns=patterns, words=words, nums=number, years=years, months=months, days=days, exts=ext)
    @info "$colorYellow$(length(RESULT))$colorReset Items Generated ✅"

    if !isempty(args["output"])
        open(args["output"], "w+") do file
            write(file, join(RESULT, "\n"))
            @info "OUTPUT Saved in $colorGreen$textBold$(args["output"])$colorReset 📄"
        end
    else
        print(join(RESULT, "\n"))
    end

end

main()