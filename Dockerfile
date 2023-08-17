FROM julia:1.9.2
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("ArgParse"); Pkg.add("OrderedCollections")'
RUN mkdir /BackupX
WORKDIR /BackupX/
COPY . /BackupX/
CMD [ "julia" ]