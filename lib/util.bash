#!/bin/bash

# Utility functions library.


#
# Copyright 2003, 2004, 2005 Suraj N. Kurapati.
#
# This file is part of "For each File".
#
# "For each File" is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# "For each File" is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with "For each File"; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#



# Localization
	# Localized string bundle for the English language.
	function utilL10nBundle_en() {
		utilText_yes="Yes"
		utilText_no="No"
		utilText_default="Default"
		utilText_pleaseAnswer__Or__="Please answer %s or %s."
	}



# Static initialization
	ff_loadL10nBundle "utilL10nBundle"



# Logic
	# Reads and returns the user's choice.
	# @stdin	user's terminal device
	# @return	0 if the user answered "no"
	# @return	1 if the user answered "yes"
	function util_queryYesNo() {
		while true; do
			read -erp "( 0 = $utilText_no | 1 = $utilText_yes ) "
			[[ $REPLY == [01] ]] && return $REPLY

			printf "$utilText_pleaseAnswer__Or__" 0 1
		done
	}



	# Reads and stores the user's reply in $REPLY
	# @global	$REPLY	The user's reply.
	# @stdin	user's terminal device
	# @param	.	The default answer, if user gives no reply.
	# @return	0	User chose the default answer.
	# @return	1	User did not choose the default answer.
	function util_query() {
		while read -erp "( $utilText_default: $1 ) "; do
			if [ -z "$REPLY" ]; then
				REPLY=$1
				return 0
			fi
		done

		return 1
	}



	# Prints the path to a non-existant temporary file, which is ready for your use. If the file is created (when you write to it), you are responsible for cleaning up that file once you are finished with it.
	# @stdout	The path to a non-existant temporary file.
	function util_getTempFile() {
		local path="${TMPDIR:-/tmp}/${0}${RANDOM}"

		while [ -e "$path" ]; do
			path="${path}${RANDOM}"
		done

		echo "$path"
	}



	# Prints the name of a non-existant temporary variable, which is ready for your use.
	# @stdout	Name of a non-existant temporary variable.
	function util_getTempVar() {
		local var="tmp$RANDOM"

		while [ -z "${var:+ }" ]; do
			var="${var}${RANDOM}"
		done

		echo "$var"
	}


	# Prints the given base-10 ASCII code as a binary byte.
	# @param	.	The base-10 ASCII code to convert.
	# @stdout	the converted value
	function util_chr() {
		# convert the argument into a number if possible. otherwise consider it to be zero
		local -i num=$1


		echo -ne "$( printf '\\%o' "$num" )"
	}



	# Prints a base-10 ASCII code corresponding to the given binary byte.
	# @param	.	The binary bite to convert.
	# @stdout	the converted value
	function util_ord() {
		od -An -N1 -tu1 <<< "$1" | tr -d '[:space:]'
	}

