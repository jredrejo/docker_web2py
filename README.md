# docker_web2py
[web2py](http://www.web2py.com) docker image
Only one environment parameter:
_PW_
to set the password of the web2py admin interface.

Built over a Debian Jessie platforms, using uwsgi and nginx.
Both http and https setup are done.

The application is built over the directory
**/app/web2py**

It's recommended to mount a Docker volume over
**/app/web2py/applications**
so the code can be edited easily.


