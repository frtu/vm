# https://hub.docker.com/r/continuumio/anaconda3/tags
FROM continuumio/anaconda3:2020.07

# Creating directories
RUN mkdir -p /data /notebooks/local

# Setting up volumes
VOLUME ["/data", "/notebooks/local"]

#Set working directory
# WORKDIR /notebooks

# jupyter
EXPOSE 8888

ENTRYPOINT ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''", "--notebook-dir=/notebooks", "--no-browser"]


