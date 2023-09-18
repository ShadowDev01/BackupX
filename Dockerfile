FROM julia:1.9.3
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("ArgParse"); Pkg.add("OrderedCollections")'
RUN mkdir /BackupX
WORKDIR /BackupX/
COPY . /BackupX/
ENTRYPOINT [ "julia", "/BackupX/BackupX.jl" ]
CMD [ "-h" ]