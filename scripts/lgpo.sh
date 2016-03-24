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

echo "Policy script applied to this machine"
sqlite3 -column -header  "${sqlitedb}" "SELECT * FROM jobs;"


exit 0
