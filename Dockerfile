# To build, cd to this directory, then:
#   docker build -t ss-shiny-devel .
#
# To run with the built-in shiny-examples:
#   docker run --rm -p 3333:3333 --name ss ss-shiny-devel

FROM ubuntu:16.04

MAINTAINER Bruce Zhao "brucezhaor2016@gmail.com"

# the codes below were borrowed from Winston Chang "winston@rstudio.com".
#
# Bruce changed the cran mirrors in order to download faster in China

# =====================================================================
# R
# =====================================================================

# Don't print "debconf: unable to initialize frontend: Dialog" messages
ARG DEBIAN_FRONTED=noninteractive

# Need this to add R repo
RUN apt-get update && apt-get install -y software-properties-common

# Add R apt repository
RUN add-apt-repository "deb http://cran.r-project.org/bin/linux/ubuntu $(lsb_release -cs)/"
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

# Install basic stuff and R
RUN apt-get update \
&& apt-get install -y \
    sudo \
    git \
    vim-tiny \
    less \
    wget \
    r-base \
    r-base-dev \
    r-recommended \
    fonts-texgyre \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libxml2-dev \
&& apt-get clean \
&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
&& rm -rf /var/lib/apt/lists/*

RUN echo 'options(\n\
  repos = c(CRAN = "https://mirrors.ustc.edu.cn/CRAN/"),\n\
  download.file.method = "libcurl",\n\
  # Detect number of physical cores\n\
  Ncpus = parallel::detectCores(logical=FALSE)\n\
)' >> /etc/R/Rprofile.site

# Create docker user with empty password (will have uid and gid 1000)
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

# =====================================================================
# Shiny Server
# =====================================================================

RUN R -e "install.packages(c('shiny', 'rmarkdown', 'devtools', 'packrat', 'rsconnect'))"

# Download and install shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/

EXPOSE 3333

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]

# =====================================================================
# Shiny Examples
# =====================================================================

# Examples needed to be added

# Install shiny-examples
# RUN cd /srv && \
#     mv shiny-server shiny-server-orig && \
#     wget -nv https://github.com/rstudio/shiny-examples/archive/master.zip && \
#     unzip -x master.zip && \
#     mv shiny-examples-master shiny-server && \
#     rm master.zip
# 
# Autodetect packages needed for the examples (will install from CRAN)
# RUN R -e "install.packages(packrat:::dirDependencies('/srv/shiny-server'))"

# Install latest shiny from GitHub
RUN R -e "devtools::install_github('rstudio/shiny')"
