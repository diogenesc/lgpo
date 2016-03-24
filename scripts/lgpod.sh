#!/bin/bash -l
#
#####
#
# $Id$
#
# Author: Daniel Roque, 2006roque@gmail.com
# Project: Dfirewall, https://github.com/tiekookeit/dfirewall
# License: GPL v2 or later (http://www.gnu.org/licenses/gpl.html)
#
# Copyright (C) 2007-2015 Daniel Roque
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#####


conf_file='/etc/lgpo.conf'
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/X11R6/bin/:/usr/games"
export version=0.1
export script_path=/usr/sbin/lgpd
export log_cmd="/usr/bin/logger -t ${script_path} -i -"

shopt -s expand_aliases;

# generic exit procedure
die(){
	[ $1 -gt 0 ] && echo "error: ${2}"
	rm -f "${pid_file}"
	${log_cmd} "daemon quit with error: ${2}"
	exit $1
}

debug(){
	[ "${debug}" != '' ] && echo ${1}
}

# make a trap for sinal sent by kill command
trap "die 0 'lgpod ended'" INT TERM EXIT QUIT KILL STOP PWR SYS

# check if script was run by root
[ "$(whoami)" != root ] && die 1 "this script must be run by root"

# check if config file exists
[ -e "${conf_file}" ] || die 1 "could not find config file ${conf_file}"
source "${conf_file}"

[ "${enabled}" != 'yes' ] && die 2 "daemon disabled"

# check if pid file already exists
[ -e "${pid_file}" ] && die 2 "pid file exists ${pid_file}"
echo $$ >${pid_file}

# look for empty variables
[ "${server_address}" == '' ] && die 1 "empty server address - variable:server_address";
[ "${rsync_user}" == '' ] && die 1 "empty server address - variable:rsync_user";
[ "${rsync_passwd}" == '' ] && die 1 "empty server address - variable:rsync_passwd";

# check permissions to write on pool
local_pool=$(echo "${local_pool}"|sed 's:/$::g')
mkdir -p ${local_pool}
[ $? == 0 ] || die 1 "could not create local pool - path=${local_pool} - variable=local_pool"

# procedures to sync with pool
rsync_pool(){
	RSYNC_PASSWORD=${rsync_passwd} rsync --ignore-errors --delete -a rsync://${rsync_user}@${server_address}/lgpo ${local_pool}
	[ $? != 0 ] && ${log_cmd} "could not link to server ${server_address}"
}


runjob(){
	job_name=$(sed -n 's:\(^job_name=\)\(.*\):\2:p' "${1}"|sed "s:'::g"|sed 's:"::g')
	job_version=$(sed -n 's:\(^job_version=\)\(.*\):\2:p' "${1}"|sed "s:'::g"|sed 's:"::g')
	
	if [ "${job_name}" == '' ]
	then
		debug "invalid job name for job '${1}'"
	else
		debug "job name ${job_name}"
		if [ "${job_version}" == '' ]
		then
			debug "invalid job version for job '${1}'"
		else
			debug "job version ${job_version}"
			query_job="SELECT * FROM jobs WHERE name='${job_name}' AND role='${role}' AND version='${job_version}'"
			if [ "$(sqlite3 "${sqlitedb}" "${query_job}")" == '' ]
			then	
				${log_cmd} "job ${1} started"
				if [ -x "${1}" ]
				then
					script_name=$(basename "${1}")
					mkdir -p ${jobs_log}
					echo "############# $(date) JOB STARTED" >>${jobs_log}/${script_name}
					${1} 2>&1 >>${jobs_log}/${script_name}
					echo "############# $(date) JOB ENDED " >>${jobs_log}/${script_name}
					insert_job="INSERT INTO jobs(name,role,version,date,script) VALUES ('${job_name}','${role}','${job_version}','$(date)','${script_name}')"
					sqlite3 "${sqlitedb}" "${insert_job}"
				else
					debug "wrong permissions, skipping job ${1}"
				fi
			else
				debug "job already on database"
			fi
		fi
	fi
}

${log_cmd} "daemon started"

[ ! -e "${sqlitedb}" ] && sqlite3 "${sqlitedb}" "CREATE TABLE jobs(date TEXT, role TEXT, name TEXT, version TEXT, script TEXT);"
while [ -e ${pid_file} ] && [ "$(cat ${pid_file})" == $$ ]
do
	rsync_pool
	for role in ${roles}
	do
		if [ ! -e "${local_pool}/roles/${role}" ]
		then
			${log_cmd} "empty role '${role}'"
		else
			for file in ${local_pool}/roles/${role}/*.job
			do
				runjob "${file}"
			done
		fi
	done
	sleep ${pool_time}
	[ $? != 0 ] && die 1 "${pool_time} is not a valid sleep time"
done

exit 0
