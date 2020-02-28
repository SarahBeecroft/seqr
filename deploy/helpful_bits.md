check if gunicorn is running

```
ps ax|grep gunicorn 
```

kill gunicorn with django

```
pkill gunicorn
```
what ports are running/being used?

```
netstat -natp
```

You can start the postgresql database server using:

```
/usr/lib/postgresql/10/bin/pg_ctl -D /var/lib/postgresql/10/main -l logfile start
```
