# Version: 0.1

FROM docker-base
MAINTAINER Adolfo De Unánue Tiscareño "adolfo.deunanue@itam.mx"

ENV REFRESHED_AT 2015-09-15

ENV DEBIAN-FRONTEND noninteractive

ENV SPARK_VERSION 1.5
ENV SPARK_HOME /opt/spark
ENV SPARK_EXECUTOR_MEMORY "6G"
ENV PYSPARK_PYTHON /home/itam/.pyenv/shims/python
ENV PYSPARK_DRIVER_PYTHON=ipython3



ENV PYENV_ROOT /home/$ITAM_USER/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

USER root

RUN echo "deb http://cran.r-project.org/bin/linux/ubuntu trusty/" >> '/etc/apt/sources.list' \
    && apt-get update


RUN apt-get install -y --force-yes --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev supervisor \
    r-base r-base-dev

USER $ITAM_USER

##  Copiamos archivo requirements.txt
ADD requirements.txt /tmp/requirements.txt

## Descargamos Spark
RUN wget --progress=bar -q -P /tmp -c 'http://d3kbcqa49mib13.cloudfront.net/spark-1.5.0-bin-hadoop2.6.tgz'

RUN tar xfz /tmp/spark-1.5.0-bin-hadoop2.6.tgz -C /opt && \
    ln -s /opt/spark-1.5.0-bin-hadoop2.6 /opt/spark

## Pyenv
RUN curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

## Agregamos pyenv al profile
RUN echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> /home/$ITAM_USER/.zshrc && \
    echo 'eval "$(pyenv init -)"' >> /home/$ITAM_USER/.zshrc && \
    echo 'eval "$(pyenv virtualenv-init -)"' >> /home/$ITAM_USER/.zshrc

## Instalamos Python 3.4
RUN pyenv install 3.4.3 && \
    pyenv rehash && \
    pyenv global 3.4.3

## Actualizamos pip
RUN pip install --upgrade pip

RUN pip install -r /tmp/requirements.txt

RUN pip install --process-dependency-links git+https://github.com/pymc-devs/pymc3

## Instalamos algunos paquetes para R

RUN mkdir -p /home/$ITAM_USER/Rpackages

RUN echo "R_LIBS=/home/itam/Rpackages" > ~/.Renviron
RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile
RUN Rscript -e "install.packages('ggplot2', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('dplyr', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('tidyr', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('stringr', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('lubridate', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('randomForest', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('httr', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('rvest', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('party', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('randomForest', lib='/home/itam/Rpackages')"
RUN Rscript -e "install.packages('shiny', lib='/home/itam/Rpackages')"

## Instalamos IRKernel
RUN Rscript -e "install.packages(c('rzmq','repr','IRkernel','IRdisplay'), repos = c('http://irkernel.github.io/', getOption('repos')), type = 'source', lib='/home/itam/Rpackages')"
RUN Rscript -e "IRkernel::installspec()"


## Variables de ambiente para jupyter con pyspark
ENV IPYTHON 1
ENV IPYTHON_OPTS "notebook --no-browser"
ENV PYSPARK_PYTHON /home/itam/.pyenv/shims/python
ENV PYSPARK_DRIVER_PYTHON ipython3

## Creamos el profile de pyspark para ipython en consola
RUN ipython profile create pyspark
COPY 00-pyspark-setup.py /home/$ITAM_USER/.ipython/profile_pyspark/startup/


## Abrimos el puerto del notebook
EXPOSE 8888 7077


## Hago esto aquí por que ya no quiero correr de nuevo el Dockerfile con la conexión de internet actual... (¬_¬)
USER root
RUN chown -R $ITAM_USER:users /home/$ITAM_USER/.jupyter
RUN chown -R $ITAM_USER:users /home/$ITAM_USER/proyectos
USER $ITAM_USER


## Montamos un volumen
VOLUME [ "/home/$ITAM_USER/proyectos" ]



CMD ["/bin/zsh"]

## Agregados al final para evitar comportamientos raros en MacOSX y Windoze
COPY jupyter_notebook_config.py /home/$ITAM_USER/.jupyter/
