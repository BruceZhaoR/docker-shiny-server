FROM ubuntu:14.04.5
MAINTAINER Bruce Zhao "brucezhaor2016@gmail.com"


#add repository and update the container
#Installation of nesesary package/software for this containers...
RUN echo "deb http://mirrors.aliyun.com/ubuntu `cat /etc/container_environment/DISTRIB_CODENAME`-backports main restricted universe" >> /etc/apt/sources.list
RUN (echo "deb https://mirrors.ustc.edu.cn/CRAN/bin/linux/ubuntu trusty/ `cat /etc/container_environment/DISTRIB_CODENAME`/" >> /etc/apt/sources.list )

RUN apt-get update && apt-get install -y -q r-base  \
                    r-base-dev \
                    gdebi-core \  
                    libapparmor1 \
                    sudo \
                    libssl1.0.0 \
                    libcurl4-openssl-dev \
                    pandoc \
                    pandoc-citeproc \
                    libcairo2-dev/unstable \
                    libxt-dev\
                    && apt-get clean \
                    && rm -rf /tmp/* /var/tmp/*  \
                    && rm -rf /var/lib/apt/lists/*
                    
                    
# Download and install shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

RUN R -e "install.packages(c('shiny', 'rmarkdown', 'shinyAce', 'Rcpp'), repos='https://mirrors.ustc.edu.cn/CRAN/')" && \
    && mkdir -p /srv/shiny-server; sync  \
    && mkdir -p /srv/shiny-server/examples; sync \
    && cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/examples/

# Install common R packages
RUN R -e "install.packages(c('devtools', 'tidyverse', 'htmlwidgets', 'igraph', 'plotly', 'heatmaply', 'RMySQL', 'flexdashboard', 'leaflet', 'LDAvis','wordcloud2'), https://mirrors.ustc.edu.cn/CRAN/')"

RUN R -e "devtools::install_github('ramnathv/rCharts')"


##startup scripts  
#Pre-config scrip that maybe need to be run one time only when the container run the first time .. using a flag to don't 
#run it again ... use for conf for service ... when run the first time ...
RUN mkdir -p /etc/my_init.d
COPY startup.sh /etc/my_init.d/startup.sh
RUN chmod +x /etc/my_init.d/startup.sh

##Adding Deamons to containers
RUN mkdir /etc/service/shiny-server /var/log/shiny-server ; sync 
COPY shiny-server.sh /etc/service/shiny-server/run
RUN chmod +x /etc/service/shiny-server/run  \
    && cp /var/log/cron/config /var/log/shiny-server/ \
    && chown -R shiny /var/log/shiny-server \
    && sed -i '113 a <h2><a href="./examples/">Other examples of Shiny application</a> </h2>' /srv/shiny-server/index.html

#volume for Shiny Apps and static assets. Here is the folder for index.html(link) and sample apps.
VOLUME /srv/shiny-server

# to allow access from outside of the container  to the container service
# at that ports need to allow access from firewall if need to access it outside of the server. 
EXPOSE 3838

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]



# Setup Shiny log
RUN mkdir -p /var/log/shiny-server
RUN chown shiny:shiny /var/log/shiny-server


EXPOSE 3838

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]




