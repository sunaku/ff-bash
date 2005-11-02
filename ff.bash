#!/bin/bash
#
# For each File enables one to execute an arbitrary set of GNU BASH shell
# commands upon an arbitrary set of files. It can be used for performing
# repetitive file-system manipulation procedures, such as mass file renaming
# and gathering file-system statistics.
#
#
# Usage:
#	1. Load this file into GNU BASH:
#		$ source ff.bash
#
#	2. Invoke the 'ff' function:
#		$ ff
#
###
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
###



# Localized string bundles
	# Localized string bundle for the English language.
	function ffL10nBundle_en() {
		# Command-line options
		# @note the following values are extended shell globs
		ffOption_showHelp='+(h|help)'
		ffOption_showVersion='+(V|version)'
		ffOption_beVerbose='+(v|verbose)'
		ffOption_pipeTargets='+(p|pipe)'
		ffOption_extDelim='extension-delim'

		ffOption_evalExpr='+(e|expression)'
		ffOption_evalFile='+(f|file)'

		ffOption_beRecursive='+(r|recursive)'
		ffOption_handleHidden='+(a|all)'
		ffOption_ignoreLinks='+(L|ignore-links)'
		ffOption_targetMask='+(m|mask)'


		# Text messages
		ffText_errorInvalidOption="Error: You specified an invalid option: %s"
		ffText_errorCannotReadFile="Error: I could not read the following file: %s"
		ffText_errorNeedMoreArguments="Error: You must specify more arguments for option: %s"
		ffText_errorBadUserScript="Error: I could not process your script: %s"

		ffText_helpSeeUserManual="See the User's Manual for explanations and examples."
		ffText_helpUsage="Usage"
		ffText_helpOptions="Options"
		ffText_helpOptionGlob="Option Glob"
		ffText_helpDescription="Description"

		ffText_forEachFile="For each File"
		ffText_disclaimer="This is free software; see the source for copying conditions. There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."
	}



# Internal variables
	declare -r ffReleaseVersion=2.0
	declare -r ffWebsite="http://ff-bash.sf.net"
	declare -r ffOptionsHelpFormat="%20s\t%s\n"

	declare -r ffNewLine=$'\n'
	declare -r ffExtDelim_default=.
	declare -r ffUserTerminal_default=/dev/tty
	declare -r ffLanguageCode_default=en


	# indices within a ffOption_* array
	declare -r ffOptionIndex_isOn=1
	declare -r ffOptionIndex_arg=2


	# prefixes that appear before command-line options and distinguish them from regular command-line arguments
	declare -r ffOptionPrefix_short=-
	declare -r ffOptionPrefix_long=--


	declare -r ffExitCode_success=0
	declare -r ffExitCode_userError=1
	declare -r ffExitCode_systemError=2
	declare -r ffExitCode_internalError=3



# Internal logic
	# Says the given message to the user via 'printf'
	# @param	.	The format string used by printf
	# @param	...	The arguments for the format string
	function ffLogic_say() {
		echo "ff: $( printf "$@" )"
	}



	function ffLogic_showVersion() {
		echo "$ffText_forEachFile $ffReleaseVersion <$ffWebsite>"
	}



	function ffLogic_showDisclaimer() {
		echo "Copyright 2003, 2004, 2005 Suraj N. Kurapati."
		echo "$ffText_disclaimer"
	}



	# Enables the given option and associates the given arguments with it
	# @param	.	Number of arguments available to the given option
	# @param	.	Option flag (how the user specifies the option)
	# @param	.	Variable name associated with option (callback)
	# @param	.	Argument to associate with option
	function ffLogic_enableOption() {
		if [ $1 -lt 1 ]; then
			ffLogic_say "$ffText_errorNeedMoreArguments" "$2"
			exit $ffExitCode_userError
		fi

		eval "$3[$ffOptionIndex_isOn]=true"
		eval "$3[$ffOptionIndex_arg]=\$4"
	}



	# Handles command-line options
	# @param	.	The command-line option to handle
	# @param	.	All command-line arguments that follow the given option
	# @return	The number of command-line arguments consumed by the given option
	function ffLogic_handleOption() {
		local option=$1
		shift

		case "$option" in
			$ffOption_showHelp)
				# show description
				ffLogic_showVersion
				echo "$ffText_helpSeeUserManual"
				echo


				# show invocation syntax
				echo "$ffText_helpUsage:"
				echo "ff [option|target]..."
				echo


				# show a list of available options
				echo "$ffText_helpOptions:"

				printf "$ffOptionsHelpFormat" "{$ffText_helpOptionGlob}" "{$ffText_helpDescription}"
				for option in ${!ffOption_*}; do
					printf "$ffOptionsHelpFormat" "${!option}" "${option#*_}"
				done
				echo


				# show a disclaimer
				ffLogic_showDisclaimer


				exit $ffExitCode_success
			;;

			$ffOption_showVersion)
				ffLogic_showVersion
				echo
				ffLogic_showDisclaimer

				exit $ffExitCode_success
			;;

			$ffOption_beVerbose)
				ffOption_beVerbose[$ffOptionIndex_isOn]=true
				set -x
				return 0
			;;

			$ffOption_pipeTargets)
				ffOption_pipeTargets[$ffOptionIndex_isOn]=true
				return 0
			;;

			$ffOption_extDelim)
				ffLogic_enableOption $# "$option" ffOption_extDelim "$1"
				return 1
			;;

			$ffOption_evalExpr)
				ffLogic_enableOption $# "$option" ffOption_evalExpr "$1"
				return 1
			;;

			$ffOption_evalFile)
				ffLogic_enableOption $# "$option" ffOption_evalFile "$1"
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

			$ffOption_targetMask)
				ffLogic_enableOption $# "$option" ffOption_targetMask "$1"
				return 1
			;;

			*)
				ffLogic_say "$ffText_errorInvalidOption" "$option"
				exit $ffExitCode_userError
			;;
		esac
	}



	# Parses command-line arguments
	# @param	.	Name of an array which will hold the parsed arguments
	function ffLogic_parseArgs() {
		local -a arguments
		local arg arguments_callBack=$1
		shift

		while (( $# > 0 )); do
			arg=$1
			shift

			case "$arg" in
				$ffOptionPrefix_long)
					# stop parsing and consider the remaining command-line arguments as arguments
					arguments=( "${arguments[@]}" "$@" )
					break
				;;

				${ffOptionPrefix_long}*)
					ffLogic_handleOption ${arg:${#ffOptionPrefix_long}} "$@"
					shift $?
				;;

				${ffOptionPrefix_short}*)
					local i options=${arg:${#ffOptionPrefix_short}}

					# handle mulitple short options that have been grouped together into a single word
					for (( i = 0; i < ${#options}; i++ )); do
						ffLogic_handleOption ${options:$i:1} "$@"
						shift $?
					done
				;;

				*)
					arguments[${#arguments[@]}]=$arg
				;;
			esac
		done


		# propogate parsed arguments back to caller
		eval "$arguments_callBack=( \"\${arguments[@]}\" )"
	}



	# Loads the user's script from command-line argument or user's terminal.
	function ffLogic_loadScript() {
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
				ffLogic_say "$ffText_errorCannotReadFile" "$scriptFile"
				exit 2
			fi

		else
			# read user's terminal
			while read -er < $ffUserTerminal_default; do
				expression="$expression${ffNewLine}$REPLY"
			done
		fi


		# ensure that user's script has the required control function
		if ! grep 'during[:space:]*([:space:]*)' <<< "$expression" >& /dev/null; then
			expression="during(){ $expression; }"
		fi


		# load the user's script, and perform a sanity check to see if the script *really* does have the required control function
		eval "$expression"

		if ! declare -F during >& /dev/null; then
			ffLogic_say "$ffText_errorBadUserScript" "$expression"
			exit $ffExitCode_internalError
		fi
	}



	# Recursively executes 'during()' on the given directory
	# @param	...	directories upon which to perform
	function ffLogic_recursiveMode() {
		while (( $# > 0 )); do
			# handle files which match the target mask
			ffLogic_linearMode "$1"/${ffOption_targetMask[$ffOptionIndex_arg]:-*}


			# handle directories recursively
			for o in "$1"/*; do
				if [ -d "$o" ]; then
					# skip links if user has specified so
					if [ -L "$o" ] && ${ffOption_ignoreLinks[$ffOptionIndex_isOn]:-false}; then
						continue
					fi


					ffLogic_recursiveMode "$o"
				fi
			done


			shift
		done
	}



	# Linearly executes 'during()' on the given argument
	# @param	...	the files upon which to perform
	function ffLogic_linearMode() {
		for o; do
			# update preset variables
				# handle special cases just like basename(1) and dirname(1)
				case "$o" in
					/)
						p=/
						d=/
						n=/
						b=/
					;;

					.)
						p=./.
						d=.
						n=.
						b=.
					;;

					..)
						p=./..
						d=.
						n=..
						b=..
					;;

					*)
						p=${o//+(\/)/\/}
						p=${p%/}

						d=${p%/*}
						d=${d:-/}	# special case: $d is empty when it should be /

						n=${p##*/}
						b=${n%${ffOption_extDelim[ffOptionIndex_arg]:-$ffExtDelim_default}*}
					;;
				esac


				# parse the file extension
				if expr index "$n" "${ffOption_extDelim[ffOptionIndex_arg]:-$ffExtDelim_default}" >& /dev/null; then
					e=${n##*${ffOption_extDelim[ffOptionIndex_arg]:-$ffExtDelim_default}}
				else
					e=
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

			if declare -F "ffL10nBundle_$ffLanguageCode" >& /dev/null; then
				ffL10nBundle_$ffLanguageCode
			else
				ffL10nBundle_$ffLanguageCode_default
			fi


			# parse command-line arguments
			local -a parsedArgs
			ffLogic_parseArgs parsedArgs "$@"


			# parse piped arguments
			local -a pipedArgs
			if ${ffOption_pipeTargets[$ffOptionIndex_isOn]:-false}; then
				while read -r "pipedArgs[${#pipedArgs[@]}]"; do
					:
				done
			fi


			# determine which mode (linear or recursive) to execute in
			local mode=ffLogic_linearMode

			if ${ffOption_beRecursive[$ffOptionIndex_isOn]:-false}; then
				mode=ffLogic_recursiveMode
			fi


			# load and execute user's script
			ffLogic_loadScript

			local o p d n b e
			before "${parsedArgs[@]}"
			$mode "${parsedArgs[@]}" "${pipedArgs[@]}"
			after "${parsedArgs[@]}"

			# @note end() is automatically called by the EXIT trap
		)
	}

