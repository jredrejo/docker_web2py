FROM python:2.7

MAINTAINER José L. Redrejo Rodríguez <jredrejo@gmail.com>

ENV PW admin

RUN  apt-get update \
	&& apt-get install -y ca-certificates nginx gettext-base supervisor unzip wget uwsgi\
    && apt-get -y install python-dev libxml2-dev python-pip\
	&& apt-get -y --purge autoremove\
	&& rm -rf /var/lib/apt/lists/*
# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# fix bug in Debian package
RUN  ln -sf /usr/lib/python2.7/plat-x86_64-linux-gnu/_sysconfigdata_nd.py /usr/lib/python2.7/


#uwsgi install
RUN pip install setuptools --no-use-wheel --upgrade && \
    PIPPATH=`which pip` && \
    $PIPPATH install --upgrade uwsgi


# remove unneeded packages

EXPOSE 80

# Disable NGINX and UWSGI daemons
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN echo "RUN_AT_STARTUP=no" >> /etc/default/uwsgi


COPY web2py.ini /etc/uwsgi/apps-enabled/

COPY web2py_nginx /etc/nginx/sites-available/

# setup nginx
RUN ln -s /etc/nginx/sites-available/web2py_nginx /etc/nginx/sites-enabled/web2py_nginx && \
	rm /etc/nginx/sites-enabled/default && \
	mkdir /etc/nginx/ssl && cd /etc/nginx/ssl && \
	openssl genrsa -passout pass:$CERT_PASS 1024 > web2py.key && \
	chmod 400 web2py.key && \
	openssl req -new -x509 -nodes -sha1 -days 1780 -subj "/C=ES/CN=www.example.es" -key web2py.key > web2py.crt && \
	openssl x509 -noout -fingerprint -text < web2py.crt > web2py.info



# get and install web2py
RUN mkdir /app && cd /app && \
	wget http://web2py.com/examples/static/web2py_src.zip && \
	unzip web2py_src.zip && \
	rm web2py_src.zip && \
	mv web2py/handlers/wsgihandler.py web2py/wsgihandler.py && \
	chown -R www-data:www-data web2py && \
	cd /app/web2py && \
	cp examples/routes.patterns.example.py routes.py && \
	python -c "from gluon.main import save_password; save_password('$PW',80)" && \
	python -c "from gluon.main import save_password; save_password('$PW',443)"



# Custom Supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /app/web2py

CMD ["/usr/bin/supervisord"]
