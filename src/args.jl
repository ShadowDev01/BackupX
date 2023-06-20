using ArgParse

function ARGUMENTS()
    settings = ArgParseSettings(
        prog="BackupX",
        description="""
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n
        **** generate wordlist by given pattern to find backup files ***
        \n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        """
    )
    @add_arg_table settings begin
        "-u", "--url"
        help = "single url"

        "-U", "--urls"
        help = "multiple targets urls in file to crawl"

        "-s", "--stdin"
        help = "read from stdin"
        action = :store_true

        "-p", "--pattern"
        help = "pattern files"
        required = true

        "-w", "--wordlist"
        help = "words"

        "-e", "--extension"
        help = "extensions"

        "-y", "--year"
        help = "years"

        "-m", "--month"
        help = "month"

        "-d", "--day"
        help = "day"

        "-n", "--number"
        help = "numbers"
        arg_type = String

        "-o", "--output"
        help = "save output in file"
    end
    parsed_args = parse_args(ARGS, settings)
    return parsed_args
end