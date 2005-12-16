#!/bin/bash

# A library for reading and writing ID3v1 and ID3v1.1 tags of MP3 files.

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
	# @result	$RESULT	Array containing data (see id3TagIndex_*) read from the given file.
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
		echo -n "TAG" >> "$tempFile"

		id3_writeField "${SOURCE[$id3TagIndex_title]}" 30 "$tempFile"
		id3_writeField "${SOURCE[$id3TagIndex_artist]}" 30 "$tempFile"
		id3_writeField "${SOURCE[$id3TagIndex_album]}" 30 "$tempFile"
		id3_writeField "${SOURCE[$id3TagIndex_year]}" 4 "$tempFile"


		if [ "${SOURCE[$id3TagIndex_version]}" == 1 ]; then
			id3_writeField "${SOURCE[$id3TagIndex_comment]}" 30 "$tempFile"
		else
			id3_writeField "${SOURCE[$id3TagIndex_comment]}" 29 "$tempFile"
			printf "%b" "\\x$( printf "%x" "${SOURCE[$id3TagIndex_track]}" )" >> "$tempFile"
		fi

		printf "%b" "\\x$( printf "%x" "${SOURCE[$id3TagIndex_genre]}" )" >> "$tempFile"

		# apply the new tag to the mp3 file
		mv -f "$tempFile" "$1"
	}



	# Writes the given field to the given file.
	# @param	.	Value of the field.
	# @param	.	Maximum (exclusive limit) length of the field.
	# @param	.	Path to the file in which the field is to be written.
	function id3_writeField() {
		# write the field
		echo -n "$1" >> "$3"


		# pad the remaining space with NUL bytes
		local i
		for (( i=${#1}; i < $2; i++ )); do
			echo -ne '\0' >> "$3"
		done
	}
