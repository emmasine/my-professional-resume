FROM httpd:2.4
RUN apt update
RUN apt install nano vim -y
COPY ./index.html /usr/local/apache2/htdocs/
EXPOSE 85
