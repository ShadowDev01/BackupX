
# Intro
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# help to generate wordlist based on patterns to fuzz backup files (backup killer)

# read from:
* Url
* File
* STDIN
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Install
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                       *** julia ***

# install julia: https://julialang.org/downloads/    or    snap install julia --classic
# then run this commands in terminal:

* 1. julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("ArgParse"); Pkg.add("OrderedCollections")'
* 2. git clone https://github.com/mrmeeseeks01/BackupX.git
* 3. cd BackupX/
* 4. julia BackupX.jl -h


# or you can use docker:

* 1. git clone https://github.com/mrmeeseeks01/BackupX.git
* 2. cd BackupX/
* 3. docker build -t backupx .
* 4. docker run backupx
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Switches
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# optional switches:

* -h            Show help message and exit
* -u            Specify a single URL to process.
* -ul           Provide a file containing multiple URLs to process
* -s            Read URL(s) from standard input (stdin)
* -p            Specify a file containing patterns to use in JSON format
* -w            Provide a wordlist file for processing
* -e            Specify a file containing extensions to use
* -n            Define a number range (e.g., 1-100)
* -y            Define a year range (e.g., 2022-2023)
* -m            Define a month range (e.g., 1-12)
* -d            Define a day range (e.g., 1-30)
* -o            Save the output to a file (default: empty)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Examples
* for custom threads, should pass -t [int] to julia
~~~
> julia -t 2 BackupX.jl [switches]
~~~
* generate wordlist by your custom input
~~~
> julia BackupX.jl -ul [file] -p [file] -w [file] -e [file] -n [min-max] -y [min-max] -m [min-max] -d [min-max]
~~~
* for example generate wordlist by single url with this pattern: $subdomain.$domain.$ext$num.$y-$m-$d
~~~
> julia BackupX.jl -u https://sub1-sub2.sub3.domain.tld -p pattern.json  -w wordlist.txt -e extensions.txt -n 1-100 -y 2021-2023 -m 1-12 -d 1-30
~~~

# Variables
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# optional variables:

* scheme
* username
* password
* host
* subdomain
* domain
* tld
* port
* path
* directory
* file
* fileN          file name
* fileE          file extension
* query
* fragment
* word           wordlist
* ext            extensions
* num            number range
* y              year range
* m              month range
* d              day range


# you can use $ or % to define your variables in pattern: $num or %num     $ext or %ext
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Example of using Variables in Patterns.json
~~~
{
    "patterns":[
        "$domain.$ext",
        "$host.$ext",
        "$subdomain.$domain.$ext",
        "$host%num.$ext",
        "$domain%num.$ext",
        "$subdomain.$ext",
        "$file.$ext",
        "$file~",
        "$path.$ext",
        ".$file",
        ".$domain.$ext",
        ".$file.$ext",
        "$path~",
        "$directory/.$file.$ext",
        "$word.$ext",
        "$directory/$word.$ext",
        "$directory/$word"
    ],
     "date-formats":[
         "$domain.%y.$ext",
         "$domain.%y-%m-%d.$ext",
         "$host.%y-%m-%d.$ext",
         "$host.%y%m%d.$ext",
         "$host.%y%m%d.$ext",
         "$directory/%y-%m-%d.$ext"
    ]
}
~~~