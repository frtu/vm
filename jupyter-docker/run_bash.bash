# docker run -i -t continuumio/anaconda3:2020.07 /bin/bash

docker run -t --rm -p 8888:8888 -v $(PWD):/opt/notebooks continuumio/anaconda3:2020.07 /bin/bash -c "/opt/conda/bin/jupyter notebook --ip=0.0.0.0 --port=8888 --notebook-dir=/opt/notebooks --allow-root --no-browser"