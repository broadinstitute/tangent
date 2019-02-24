#// Pull base image.
FROM ubuntu:14.04
MAINTAINER Coyin Oh (coyin.oh@gmail.com)

ENV TERM=vt100
RUN \
	sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
	apt-get update && \
	apt-get upgrade -y &&  \
	apt-get install -yq  \
	                bc \
	                libxp6 \
	                vcftools \
	                xorg \
	                default-jre \
	                r-base \
	                tcsh \
	                wget && \
	apt-get clean && \
	apt-get purge && \
	rm -rf /var/lib/apt/lists/*

#// Install Conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -p /miniconda -b
RUN rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH=/miniconda/bin:${PATH}
RUN conda update -y conda

#// Install relevant Python packages
RUN conda --version
RUN conda install -y -c miniconda numpy
RUN conda install -y -c miniconda pandas
RUN conda install -y -c miniconda scikit-learn

#// Install relevant R packages
RUN R -e "source('http://bioconductor.org/biocLite.R')"
RUN R -e "BiocInstaller::biocLite('DNAcopy')"
RUN R -e "install.packages('doParallel', repos = 'http://cran.us.r-project.org')"


#// Set environment variables.
COPY . /opt

RUN echo `date`
RUN echo `pwd`

WORKDIR /opt
#RUN chmod 0777 /opt/matlab_2010b/MCRInstaller.bin
RUN ./matlab_2010b/MCRInstaller.bin -silent

ENV MCRROOT=/opt/MATLAB/MATLAB_Compiler_Runtime/v714/

RUN chmod 0774 ./wrapper_overall.sh
# RUN chmod 0777 ./data
# RUN chmod 0777 ./result

ENTRYPOINT ["bash", "-c", "./wrapper_overall.sh -m $MCRROOT -i $0 -o $1 -s $2 -d $3 -t $4 -p $5 -c $6 -a $7 -n $8 -e $9 -x ${10} -y ${11} -z ${12} -r ${13}"]
CMD ["/opt/data/", "/opt/result/", "/opt/sampledata/mysif.txt", "/opt/sampledata/mydata.DOC_interval.avg_cvg.txt", "run1", "exome", "0.23", "0.01", "2", "150", "true", "true", "true", "None"]

