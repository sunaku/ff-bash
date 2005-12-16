#!/bin/bash
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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with "For each File"; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#



# Localization
	# Localized string bundle for the English language.
	function ffL10nBundle_en() {
		# Command-line options
		# @note the following values are extended shell globs
		ffOption_showHelp='@(h|help)'
		ffOption_showVersion='@(V|version)'
		ffOption_beVerbose='@(v|verbose)'
		ffOption_pipeObjects='@(p|pipe)'
		ffOption_suffixDelim='suffix-delim'

		ffOption_evalExpr='@(e|expression)'
		ffOption_evalFile='@(f|file)'

		ffOption_beRecursive='@(r|recursive)'
		ffOption_handleHidden='@(a|all)'
		ffOption_ignoreLinks='@(L|ignore-links)'
		ffOption_objectMask='@(m|mask)'


		# Text messages
		ffText_errorInvalidOption="I do not recognize this option: %s"
		ffText_errorCannotReadFile="I could not read this file: %s"
		ffText_errorNeedMoreArguments="This option needs more arguments: %s"
		ffText_errorBadUserScript="I could not process your script: %s"

		ffText_helpSeeUserManual="See the user's manual for explanations and examples."
		ffText_helpUsage="Usage"
		ffText_helpOptions="Options"
		ffText_helpOptionGlob="Option glob"
		ffText_helpDescription="Description"

		ffText_version="version"
		ffText_forEachFile="For each File"
		ffText_disclaimer="This is free software; see the source for copying conditions. There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."
	}



# Variables
	declare -r ffReleaseVersion=2.0
	declare -r ffWebsite="http://ff-bash.sf.net"
	declare -r ffOptionsHelpFormat="%20s\t%s\n"

	declare -r ffNewLine=$'\n'
	declare -r ffExtDelim_default=.
	declare -r ffLanguageCode_default=en


	# indices within a ffOption_* array
	declare -r ffOptionIndex_isOn=1
	declare -r ffOptionIndex_arg=2


	# prefixes that appear before command-line options and distinguish them from regular command-line arguments
	declare -r ffOptionPrefix_short=-
	declare -r ffOptionPrefix_long=--


	# exit status diagnostics
	declare -r ffExitCode_success=0
	declare -r ffExitCode_internalError=1
	declare -r ffExitCode_userError=2
	declare -r ffExitCode_systemError=3
	declare -r ffExitCode_scriptError=4



# Logic
	# Says the given message to the user via 'printf'
	# @param	.	The format string used by printf
	# @param	...	The arguments for the format string
	function ff_say() {
		echo "ff: $( printf "$@" )"
	}



	# Loads localized string bundles for the user's current language.
	# @param	.	Prefix of the function name which contains localized string bundles
	function ff_loadL10nBundle() {
		if declare -F "${1}_$ffLanguageCode" >& /dev/null; then
			"${1}_$ffLanguageCode"
		else
			"${1}_$ffLanguageCode_default"
		fi
	}



	# Makes the given libraries available for use by your script.
	# @param	...	Names of the libraries you want to use.
	function ff_import() {
		for library; do
			local path="$FF_HOME/libs/$library.bash"

			if [ -f "$path" -a -r "$path" ]; then
				source "$path"
			else
				ff_say "$ffText_errorCannotReadFile" "$path"
				exit $ffExitCode_systemError
			fi
		done
	}



	function ff_showVersion() {
		echo "$ffText_forEachFile, $ffText_version $ffReleaseVersion ($ffWebsite)"
	}



	function ff_showDisclaimer() {
		echo "Copyright 2003, 2004, 2005 Suraj N. Kurapati."
		echo
		echo "$ffText_disclaimer"
	}



	# Enables the given option and associates the given arguments with it
	# @param	.	Number of arguments available to the given option
	# @param	.	Option flag (how the user specifies the option)
	# @param	.	Variable name associated with option (callback)
	# @param	.	Argument to associate with option
	function ff_enableOption() {
		if [ $1 -lt 1 ]; then
			ff_say "$ffText_errorNeedMoreArguments" "$2"
			exit $ffExitCode_userError
		fi

		eval "$3[$ffOptionIndex_isOn]=true"
		eval "$3[$ffOptionIndex_arg]=\$4"
	}



	# Handles command-line options
	# @param	.	The command-line option to handle
	# @param	.	All command-line arguments that follow the given option
	# @return	The number of command-line arguments consumed by the given option
	function ff_handleOption() {
		local option=$1
		shift

		case "$option" in
			$ffOption_showHelp)
				# show description
				ff_showVersion
				echo "$ffText_helpSeeUserManual"
				echo


				# show invocation syntax
				echo "$ffText_helpUsage:	ff [option|object]..."
				echo


				# show a list of available options
				echo "$ffText_helpOptions:"

				printf "$ffOptionsHelpFormat" "$ffText_helpOptionGlob" "$ffText_helpDescription"
				printf "$ffOptionsHelpFormat" "${ffText_helpOptionGlob//?/-}" "${ffText_helpDescription//?/-}"
				for option in ${!ffOption_*}; do
					printf "$ffOptionsHelpFormat" "${!option}" "${option#*_}"
				done
				echo


				# show a disclaimer
				ff_showDisclaimer


				exit $ffExitCode_success
			;;

			$ffOption_showVersion)
				ff_showVersion
				ff_showDisclaimer

				exit $ffExitCode_success
			;;

			$ffOption_beVerbose)
				ffOption_beVerbose[$ffOptionIndex_isOn]=true
				set -x
				return 0
			;;

			$ffOption_pipeObjects)
				ffOption_pipeObjects[$ffOptionIndex_isOn]=true
				return 0
			;;

			$ffOption_suffixDelim)
				ff_enableOption $# "$option" ffOption_suffixDelim "$1"
				return 1
			;;

			$ffOption_evalExpr)
				ff_enableOption $# "$option" ffOption_evalExpr "$1"
				return 1
			;;

			$ffOption_evalFile)
				ff_enableOption $# "$option" ffOption_evalFile "$1"
				return 1
			;;

			$ffOption_beRecursive)
				ffOption_beRecursive[$ffOptionIndex_isOn]=true
				return 0
			;;

			$ffOption_handleHidden)
				ffOption_handleHidden[$ffOptionIndex_isOn]=true
				shopt -s dotglob
				return 0
			;;

			$ffOption_ignoreLinks)
				ffOption_ignoreLinks[$ffOptionIndex_isOn]=true
				return 0
			;;

			$ffOption_objectMask)
				ff_enableOption $# "$option" ffOption_objectMask "$1"
				return 1
			;;

			*)
				ff_say "$ffText_errorInvalidOption" "$option"
				exit $ffExitCode_userError
			;;
		esac
	}



	# Parses command-line arguments into an array named "$RESULT".
	# @param	...	The arguments to be parsed.
	# @result	$RESULT	Array containing parsed arguments.
	function ff_parseArgs() {
		while (( $# > 0 )); do
			local arg=$1
			shift

			case "$arg" in
				$ffOptionPrefix_long)
					# stop parsing and consider the remaining command-line arguments as arguments
					RESULT=( "${RESULT[@]}" "$@" )
					break
				;;

				${ffOptionPrefix_long}*)
					ff_handleOption ${arg:${#ffOptionPrefix_long}} "$@"
					shift $?
				;;

				${ffOptionPrefix_short}*)
					local i options=${arg:${#ffOptionPrefix_short}}

					# handle mulitple short options that have been grouped together into a single word
					for (( i = 0; i < ${#options}; i++ )); do
						ff_handleOption ${options:$i:1} "$@"
						shift $?
					done
				;;

				*)
					RESULT[${#RESULT[@]}]=$arg
				;;
			esac
		done
	}



	# Loads the user's script from command-line argument or user's terminal.
	# @pre	the standard input stream must represent the user's terminal (e.g. /dev/tty)
	function ff_loadScript() {
		local expression=:

		if ${ffOption_evalExpr[$ffOptionIndex_isOn]:-false}; then
			# read command-line argument
			expression=${ffOption_evalExpr[$ffOptionIndex_arg]}

		elif ${ffOption_evalFile[$ffOptionIndex_isOn]:-false}; then
			# read script file
			local scriptFile=${ffOption_evalFile[$ffOptionIndex_arg]}

			if [ -f $scriptFile -a -r $scriptFile ]; then
				expression=$( < $scriptFile )
			else
				ff_say "$ffText_errorCannotReadFile" "$scriptFile"
				exit 2
			fi

		else
			# read user's terminal
			while read -er; do
				expression="$expression${ffNewLine}$REPLY"
			done
		fi


		# ensure that user's script has the required control function
		if ! [[ "$expression" =~ 'during\s*\(\s*\)' ]]; then
			expression="during(){${ffNewLine}$expression${ffNewLine}:;}"
		fi


		# load the user's script, and perform a sanity check to see if the script *really* does have the required control function
		eval "$expression"

		if ! declare -F during >& /dev/null; then
			ff_say "$ffText_errorBadUserScript" "$expression"
			exit $ffExitCode_internalError
		fi
	}



	# Recursively executes 'during()' on the given directory
	# @param	...	directories upon which to perform
	function ff_recursiveMode() {
		while (( $# > 0 )); do
			# handle files which match the target mask
			ff_linearMode "$1"/${ffOption_objectMask[$ffOptionIndex_arg]:-*}


			# handle directories recursively
			for o in "$1"/*; do
				if [ -d "$o" ]; then
					# skip links if user has specified so
					if [ -L "$o" ] && ${ffOption_ignoreLinks[$ffOptionIndex_isOn]:-false}; then
						continue
					fi


					ff_recursiveMode "$o"
				fi
			done


			shift
		done
	}



	# Linearly executes 'during()' on the given argument
	# @param	...	the files upon which to perform
	function ff_linearMode() {
		for o; do
			# update object variables
				# parse the object's name and parent directory, which are separated by a slash.
				case "$o" in
					# special cases from basename(1) and dirname(1)
					/)
						d=/
						n=/
					;;

					.)
						d=.
						n=.
					;;

					..)
						d=.
						n=..
					;;


					*)
						# prepare object to ensure correct parsing
						local oNormalized=${o%%+(\/)}


						if [[ "$oNormalized" =~ / ]]; then
							d=${oNormalized%/*}
							d=${d:-/}	# special case: $d is empty when it should be '/'
							n=${oNormalized##*/}
						else
							# the object has no slashes; it is a simple file name like 'foo.bar' that is relative to the current working directory
							d=.
							n=$oNormalized
						fi
					;;
				esac


				# parse the prefix
				p=${n%${ffOption_suffixDelim[ffOptionIndex_arg]:-$ffExtDelim_default}*}


				# parse the suffix
				if [ "$p" != "$n" ]; then
					s=${n##*${ffOption_suffixDelim[ffOptionIndex_arg]:-$ffExtDelim_default}}
				else
					s=
				fi


			during
		done
	}



	# Primary entry point into this file's logic
	# @param	...	Command-line arguments
	function ff() {
		# run the following code in a sub-shell because it uses the 'exit' command at some point. Without this sub-shell, the 'exit' command will close the user's terminal!
		(
			# create dummy control functions to suppress errors, about non-existent functions, that occur when the user has not overridden the control functions
			function before() { :; }
			function during() { :; }
			function after() { :; }
			function end() { :; }


			# ensure that proper clean up is performed during exit
			trap "exit $ffExitCode_systemError" INT KILL TERM HUP
			trap end EXIT


			# enable support for extended shell globs and nullifying of bogus globs
			shopt -s extglob nullglob


			# load localized string bundles for the user's current language
			ffLanguageCode=$( expr substr ${LANG:-$ffLanguageCode_default} 1 2 )

			ff_loadL10nBundle ffL10nBundle


			# parse command-line arguments
			local -a parsedArgs
			ff_parseArgs "$@"
			parsedArgs=( "${RESULT[@]}" )


			# parse piped arguments
			local -a pipedArgs
			if ${ffOption_pipeObjects[$ffOptionIndex_isOn]:-false}; then
				while read -r "pipedArgs[${#pipedArgs[@]}]"; do
					:
				done
			fi


			# determine which mode (linear or recursive) to execute in
			local mode=ff_linearMode

			if ${ffOption_beRecursive[$ffOptionIndex_isOn]:-false}; then
				mode=ff_recursiveMode
			fi


			# load and execute user's script
			ff_loadScript

			# o = object
			# d = dirname
			# n = basename
			# p = prefix (without file extension)
			# s = suffix (file extension)
			local o d n p s

			before "${parsedArgs[@]}"
			$mode "${parsedArgs[@]}" "${pipedArgs[@]}"
			after "${parsedArgs[@]}"


			# @note end() is automatically called by the EXIT trap
			# @note the default exit status is 0 (same as $ffExitCode_success)
		)
	}

