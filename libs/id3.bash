#!/bin/bash

# A library for reading and writing ID3v1 and ID3v1.1 tags for mp3 files.

#
# Copyright 2003, 2004 Suraj N. Kurapati.
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
	function id3L10nBundle_en() {
		id3Text_genreNames=( "Blues" "Classic Rock" "Country" "Dance" "Disco" "Funk" "Grunge" "Hip-Hop" "Jazz" "Metal" "New Age" "Oldies" "Other" "Pop" "R&B" "Rap" "Reggae" "Rock" "Techno" "Industrial" "Alternative" "Ska" "Death Metal" "Pranks" "Soundtrack" "Euro-Techno" "Ambient" "Trip-Hop" "Vocal" "Jazz+Funk" "Fusion" "Trance" "Classical" "Instrumental" "Acid" "House" "Game" "Sound Clip" "Gospel" "Noise" "Alt. Rock" "Bass" "Soul" "Punk" "Space" "Meditative" "Instrum. Pop" "Instrum. Rock" "Ethnic" "Gothic" "Darkwave" "Techno-Indust." "Electronic" "Pop-Folk" "Eurodance" "Dream" "Southern Rock" "Comedy" "Cult" "Gangsta" "Top 40" "Christian Rap" "Pop/Funk" "Jungle" "Native American" "Cabaret" "New Wave" "Psychadelic" "Rave" "Showtunes" "Trailer" "Lo-Fi" "Tribal" "Acid Punk" "Acid Jazz" "Polka" "Retro" "Musical" "Rock & Roll" "Hard Rock" "Folk" "Folk/Rock" "National Folk" "Swing" "Fusion" "Bebob" "Latin" "Revival" "Celtic" "Bluegrass" "Avantgarde" "Gothic Rock" "Progress. Rock" "Psychadel. Rock" "Symphonic Rock" "Slow Rock" "Big Band" "Chorus" "Easy Listening" "Acoustic" "Humour" "Speech" "Chanson" "Opera" "Chamber Music" "Sonata" "Symphony" "Booty Bass" "Primus" "Porn Groove" "Satire" "Slow Jam" "Club" "Tango" "Samba" "Folklore" "Ballad" "Power Ballad" "Rhythmic Soul" "Freestyle" "Duet" "Punk Rock" "Drum Solo" "A Capella" "Euro-House" "Dance Hall" "Goa" "Drum & Bass" "Club-House" "Hardcore" "Terror" "Indie" "BritPop" "Negerpunk" "Polsk Punk" "Beat" "Christian Gangsta Rap" "Heavy Metal" "Black Metal" "Crossover" "Contemporary Christian" "Christian Rock" "Merengue" "Salsa" "Thrash Metal" "Anime" "Jpop" "Synthpop" )
	}



# Static initialization
	ff_loadL10nBundle id3L10nBundle
	ff_import util



# Variables
	id3TagIndex_version=0
	id3TagIndex_title=1
	id3TagIndex_artist=2
	id3TagIndex_album=3
	id3TagIndex_year=4
	id3TagIndex_comment=5
	id3TagIndex_genre=6
	id3TagIndex_track=7

	declare -r id3NulPadding=$'\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1'



# Logic
	# Parses an ID3v1 or ID3v1.1 tag from the given file and stores the results into an array named "$RESULT".
	# @param	.	Path to an MP3 file from which a tag is to be read.
	# @result	$RESULT	Array containing parsed data (see id3TagIndex_*).
	# @return	1	The given file has an invalid ID3 tag.
	function id3_readTag() {
		local tempFile=$( util_getTempFile )

		# read ID3 tag
		tail -c 128 "$1" > "$tempFile"

		# ensure the tag is valid
		if [ "$( head -c 3 "$tempFile" )" != 'TAG' ]; then
			return 1
		fi


		# parse ID3 tag
		RESULT[$id3TagIndex_title]=$( cut -c 4-33 "$tempFile" )
		RESULT[$id3TagIndex_artist]=$( cut -c 34-63 "$tempFile" )
		RESULT[$id3TagIndex_album]=$( cut -c 64-93 "$tempFile" )
		RESULT[$id3TagIndex_year]=$( cut -c 94-97 "$tempFile" )

		# determine the genre ID
		local genre=$( cut -c 128 "$tempFile" )

		if [ -z "$genre" ]; then
			RESULT[$id3TagIndex_genre]=0
		else
			RESULT[$id3TagIndex_genre]=$( echo "$genre" | od -An -N1 -tu1 | tr -d '[:space:]' )
		fi

		# determine the version of the ID3 tag: in the comment field, if the second last byte is NUL and the last byte is not NUL, then the entire tag is ID3v1.1
		if [ -n "$( cut -c 126-127 "$tempFile" )" ]; then
			RESULT[$id3TagIndex_version]=1.1
			RESULT[$id3TagIndex_comment]=$( cut -c 98-126 "$tempFile" )
			RESULT[$id3TagIndex_track]=$( cut -c 127 "$tempFile" | od -An -N1 -tu1 | tr -d '[:space:]' )
		else
			RESULT[$id3TagIndex_version]=1
			RESULT[$id3TagIndex_comment]=$( cut -c 98-127 "$tempFile" )
			RESULT[$id3TagIndex_track]=
		fi


		# clean up
		rm -f "$tempFile"
		return 0
	}



	# Writes an ID3v1 or ID3v1.1 tag to the given file using the tag data  places the result into the array variable whose name is given.
	# @param	.	Name of the array (see $id3TagIndex_*) variable which contains the tag data that is to be written to the file.
	# @param	.	Path to the MP3 file that is to be tagged with the given data.
	function id3_writeTag() {
		# get access to a non-existent temporary file
		local tempFile="$o.tmp"

		while [ -e "$tempFile" ]; do
			tempFile="$tempFile-$$"
		done


		# copy caller's array to local array
		local -a tag
		eval "tag=( \"\${$1[@]}\" )"


		# copy non-tag data from mp3 file to temporary file
		if [ -e "$2" ]; then
			# check if file already has a tag
			if id3_readTag raw "$2"; then
				head -c -128 "$2" > "$tempFile"
			else
				cp -f "$2" "$tempFile"
			fi
		fi


		# pad tag-fields with NUL bytes
			for i in 1 2 3 4 5
			do
				tag[$i]="${tag[$i]}$id3NulPadding"
			done


		# write new tag data to temporary file
		{
			echo -n "TAG${tag[$id3TagIndex_title]:0:30}${tag[$id3TagIndex_artist]:0:30}${tag[$id3TagIndex_album]:0:30}${tag[$id3TagIndex_year]:0:4}"


			# write the comment & 'track number' fields
			if [ "${tag[$id3TagIndex_version]}" == 1 ]; then
				echo -n "${tag[$id3TagIndex_comment]:0:30}"
			else
				echo -n "${tag[$id3TagIndex_comment]:0:28}$id3NulCode$( printf "%b" "\\x$( printf "%x" "${tag[$id3TagIndex_track]}" )" )"
			fi

			# write the genre field
			echo -n "$( printf "%b" "\\x$( printf "%x" "${tag[$id3TagIndex_genre]}" )" )"

		} | tr "$id3NulCode" '\0' | head -c 128 >> "$tempFile"


		# apply the new tag to the mp3 file
		mv -f "$tempFile" "$2"
	}

