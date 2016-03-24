# LGPO
Linux Group Policy

This is a simple implementation of a basic system
where administrator may send administrative jobs to
a scpecific network


It works as follow on server you have a rsync
repository at /var/lib/lgpo called lgpo


Server Config:
Example of rsync server conf /etc/rsyncd.conf
	lock file = /var/run/rsync.lock
	log file = /var/log/rsyncd.log
	pid file = /var/run/rsyncd.pid

	[lgpo]
    path = /var/lib/lgpo
    comment = Linux Group Policys
    uid = root
    gid = root
    read only = yes
    list = yes
    auth users = lgpo
    secrets file = /etc/rsyncd.secrets
    hosts allow = 192.168.0.0/255.255.255.0

Rsync password file /etc/rsyncd.secrets add
the line below
	lgpo:Secret


Roles:
inside /var/lib/lgpo or anywere you decided to place it
create a folder called roles.
Roles are folders inside the folder roles can be aniyhing
you wanna name like: general, frontoffice, backoffice,
servers, gateway etc... on client side you gonna point that.

Jobs:
Inside roles you will create scripts that will run on
clientes, you need 3 things on scripts to be recognized
by clients as valid job.

script mode must be 500
script name must have extension .job
inside script must have 2 variables
    job_name='something'
    job_version='today'

Every job will run once, to run a job again, you must change
its version on server side.
Example of job /var/lib/lgpo/roles/general/first.job 
    #!/bin/bash
    #This will be the name of you job, after a
    #job is ran on the client they will record
    #o inner database the name and the version
    #of job, and will compare that on next run
	job_name='anything'

    #If you change the version, clients will see
    #that as an not executed job yet, but history
    #from previous versions will be see on client
    #inner database
	job_version='1.0'

	exit 0


Client Dependency:
    shc compiler
    sqlite3 database
    rsync sincronization software


Client instalation:
On server you dont need to install lgpo just rsync
on clients clone repository make install on debian
systems I recomend make debian then dpkg -i *.deb.


Client Config:
instalation may place a config file ate /etc/lgpo.conf
Example:

    #aemon pid file
	pid_file=/var/run/lgpod.pid
    #pool were server request will be placed
	local_pool=/var/lib/lgpo/
    #if you chance job_log value, consider editing
    #logrotate file to reflect your changes
	jobs_log=/var/log/lgpo
    #remote rsync user
	rsync_user='lgpo'
    #remote rsync user password
	rsync_passwd='Secret'
    #if you set this to anything different of yes daemon
    #wont run
	enabled=yes
    #see roles
	roles='station general'
    #rsync server addres
	server_address='192.168.0.2'
    #sqlite database, this small db store ran jobs
	sqlitedb='/etc/lgpo.db'
    #frequency of new jobs check
	pool_time='15m'



Good Luck!
