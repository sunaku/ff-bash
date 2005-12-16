#!/bin/bash

# A library for reading and writing ID3v1 and ID3v1.1 tags (see http://en.wikipedia.org/wiki/Id3).

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

	id3NulByte=$'\1'
	id3NulPadding=$'\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1'



# Logic
	# Parses an ID3v1 or ID3v1.1 tag from the given file and stores the results into an array named "$RESULT".
	# @param	.	Path to the MP3 file whose tag you want to read.
	# @global	$RESULT	Array containing data (see id3TagIndex_*) read from the given file.
	# @return	1	The given file does not have an ID3 tag.
	function id3_readTag() {
		local tempFile=$( util_getTempFile )

		# read ID3 tag
		tail -c 128 "$1" > "$tempFile"


		# ensure tag is valid
		if [ "$( head -c 3 "$tempFile" )" != 'TAG' ]; then
			rm -f "$tempFile"
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
				RESULT[$id3TagIndex_genre]=$( id3_ord "$genre" )
			fi


			# source: http://www.id3.org/id3v2-00.txt (section A.4)
			# In ID3v1.1, Michael Mutschler revised the specification of the comment field in order to implement the track number. The new format of the comment field is a 28 character string followed by a mandatory null ($00) character and the original album tracknumber stored as an unsigned byte-size integer. In such cases where the 29th byte is not the null character or when the 30th is a null character, the tracknumber is to be considered undefined.
			if [ -z "$( cut -c 126 "$tempFile" )" ]; then
				RESULT[$id3TagIndex_version]=1.1
				RESULT[$id3TagIndex_comment]=$( cut -c 98-125 "$tempFile" )
				RESULT[$id3TagIndex_track]=$( id3_ord "$( cut -c 127 "$tempFile" )" )
			else
				RESULT[$id3TagIndex_version]=1
				RESULT[$id3TagIndex_comment]=$( cut -c 98-127 "$tempFile" )
				RESULT[$id3TagIndex_track]=
			fi


		rm -f "$tempFile"
		return 0
	}



	# Writes an ID3v1 or ID3v1.1 tag to the given file.
	# @param	.	Path to the MP3 file whose tag you want to write.
	# @param	$SOURCE	Array containing data (see $id3TagIndex_*) that is to be written to the given file.
	function id3_writeTag() {
		# get access to a non-existent temporary file
		local tempFile=$( util_getTempFile )


		# copy non-tag data from mp3 file to temporary file
		if id3_readTag "$1"; then
			head -c -128 "$1" > "$tempFile"
		else
			cp -f "$1" "$tempFile"
		fi



		# write new tag data to temporary file
		# @see note about ID3v1.1 inside id3_readTag()
		echo -n "TAG" >> "$tempFile"

		id3_writeField "${SOURCE[$id3TagIndex_title]}" 30 "$tempFile"
		id3_writeField "${SOURCE[$id3TagIndex_artist]}" 30 "$tempFile"
		id3_writeField "${SOURCE[$id3TagIndex_album]}" 30 "$tempFile"
		id3_writeField "${SOURCE[$id3TagIndex_year]}" 4 "$tempFile"

		if [ "${SOURCE[$id3TagIndex_version]}" == 1.1 ]; then
			id3_writeField "${SOURCE[$id3TagIndex_comment]}" 28 "$tempFile"
			echo -ne '\0' >> "$tempFile"	# zero-byte separator
			id3_chr "${SOURCE[$id3TagIndex_track]}" >> "$tempFile"
		else
			id3_writeField "${SOURCE[$id3TagIndex_comment]}" 30 "$tempFile"
		fi

		id3_chr "${SOURCE[$id3TagIndex_genre]}" >> "$tempFile"


		# apply the new tag to the mp3 file
		mv -f "$tempFile" "$1"
	}



	# Writes the given field to the given file.
	# @param	.	Value of the field.
	# @param	.	Maximum (exclusive limit) length of the field.
	# @param	.	Path to the file in which the field is to be written.
	function id3_writeField() {
		count=$(( count + $2 ))
		echo "COUNT=$count"

		if [ ${#1} -lt $2 ]; then
			# write the field
			echo -n "$1" >> "$3"


			# fill the remaining space with NUL bytes
			echo "remaining space=$(( $2 - ${#1} ))" > /dev/tty
			local i
			for (( i=${#1}; i < $2; i++ )); do
				echo -ne '\0' >> "$3"
			done
		else
			echo -n "${1:0:$2}" >> "$3"
		fi

		echo "SIZE=$( wc -c "$3" )"
	}



	# Prints the given base-10 ASCII code as a binary byte.
	# @param	.	The base-10 ASCII code to convert.
	function id3_chr() {
		# convert the argument into a number if possible. otherwise consider it to be zero
		local -i num=$1


		echo -ne "$( printf '\\%o' "$num" )"
	}



	# Prints a base-10 ASCII code corresponding to the given binary byte.
	# @param	.	The binary bite to convert.
	function id3_ord() {
		od -An -N1 -tu1 <<< "$1" | tr -d '[:space:]'
	}
