# lgpo
Linux Group Policy

This is a simple implementation of a basic system
where administrator may send administrative jobs to
a network scpecific netwokrk


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

Inside roles you will create scripts that will run on
clientes, you need 3 things to scripts be recognized
by clients as valid.

script mode must be 500
script name must have extension .job
inside script must have 2 variables
    job_name='something'
    job_version='today'

Every job will run once, to run a job again, you must change
its version on server side.
Example:
cat /var/lib/lgpo/roles/general/first.job 
#!/bin/bash
#
#
#
#

# This will be the name of you job, after a
# job is ran on the client they will record
# o inner database the name and the version
# of job, and will compare that on next run
job_name='anything'

# If you change the version, clients will see
# that as an not executed job yet, but history
# from previous versions will be see on client
# inner database
job_version='1.0'


exit 0


Client Dependency:
    you need shc compiler


Client instalation:
On server you dont need to install lgpo just rsync
on clients clone repository make install on debian
systems I recomend make debian then dpkg -i *.deb.


Client Config:
instalation may place a config file ate /etc/lgpo.conf
Example:

pid_file=/var/run/lgpod.pid
local_pool=/var/lib/lgpo/
# if you chance job_log value, consider editing
# logrotate file to reflect your changes
jobs_log=/var/log/lgpo
rsync_user='lgpo'
rsync_passwd='Secret'
enabled=yes
roles='station general'
server_address='192.168.0.2'
sqlitedb='/etc/lgpo.db'
pool_time='1m'



Good Luck