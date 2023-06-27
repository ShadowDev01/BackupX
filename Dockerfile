FROM julia:1.9.1
RUN julia -e 'using Pkg; Pkg.add("ArgParse"); Pkg.add("JSON")'
RUN mkdir /BackupX
WORKDIR /BackupX/
COPY . /BackupX/
CMD [ "julia" ]