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
RUN wget -q -P /tmp -c 'http://d3kbcqa49mib13.cloudfront.net/spark-1.5.0-bin-hadoop2.6.tgz'

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
RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile
RUN Rscript -e "install.packages('ggplot2')"
RUN Rscript -e "install.packages('dplyr')"
RUN Rscript -e "install.packages('tidyr')"
RUN Rscript -e "install.packages('stringr')"
RUN Rscript -e "install.packages('lubridate')"
RUN Rscript -e "install.packages('randomForest')"
RUN Rscript -e "install.packages('httr')"
RUN Rscript -e "install.packages('rvest')"
RUN Rscript -e "install.packages('shiny')"

## Variables de ambiente para jupyter con pyspark
ENV IPYTHON 1
ENV IPYTHON_OPTS "notebook --no-browser"
ENV PYSPARK_PYTHON /home/itam/.pyenv/shims/python
ENV PYSPARK_DRIVER_PYTHON=ipython3

## Creamos el profile de pyspark para ipython en consola
RUN ipython profile create pyspark
COPY 00-pyspark-setup.py /home/$ITAM_USER/.ipython/profile_pyspark/startup/


## Abrimos el puerto del notebook
EXPOSE 8888 7077

## Montamos un volumen
VOLUME [ "/home/itam/proyectos" ]

CMD ["/bin/zsh"]

#CMD ["/opt/spark-1.5.0-bin-hadoop2.6/bin/pyspark"]
#CMD ["start-notebook.sh"]
## Agregados al final para evitar comportamientos raros en MacOSX y Windoze
##COPY start-notebook.sh /usr/local/bin/
##COPY notebook.conf /etc/supervisor/conf.d/
##COPY jupyter_notebook_config.py /home/$ITAM_USER/.jupyter/
#RUN chown -R $ITAM_USER:users /home/$ITAM_USER/.jupyter
