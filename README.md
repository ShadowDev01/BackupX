# Install
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            *** julia ***

# install julia: https://julialang.org/downloads/
# then run this commands in terminal:

* 1. julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("ArgParse")'
* 2. git clone https://github.com/mrmeeseeks01/BackupX.git
* 3. cd BackupX/
* 4. julia BackupX.jl -h


# or you can use docker:

* 1. git clone https://github.com/mrmeeseeks01/BackupX.git
* 2. cd BackupX/
* 3. docker build -t backupx .
* 4. docker run -it backupx
* 5. press ; to enabled shell mode
* 6. julia BackupX.jl -h
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Intro
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# help to generate wordlist based on patterns to fuzz backup files

# read from:
* Url
* File
* STDIN
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Switches
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# optional arguments:
*  -h, --help            show this help message and exit
*  -u, --url             single url
*  -U, --urls            multiple urls in file
*  -s, --stdin           read url(s) from stdin
*  -p, --pattern         pattern file
*  -w, --wordlist        wordlist file
*  -e, --extension       extensions file
*  -n, --number          number range (i.e. 1-100)
*  -y, --year            year range (i.e. 2022-2023)
*  -m, --month           month range (i.e. 1-12)
*  -d, --day             day range (i.e. 1-30)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Examples
* for custom threads, should pass -t [int] to julia
~~~
> julia -t 2 BackupX.jl [switches]
~~~
* generate wordlist by your custom input
~~~
> julia BackupX.jl -U [file] -p [file] -w [file] -e [file] -n [min-max] -y [min-max] -m [min-max] -d [min-max]
~~~