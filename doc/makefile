#!/bin/env make
#
# Copyright 2006 Suraj N. Kurapati.
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

srcDir=src
outputs=man html text

all: $(outputs)

clean:
	rm -rf $(outputs)

dist-clean: clean
	rm -f ../README ../HISTORY ../*.html

spotless: dist-clean

man: $(srcDir)/manual.xml
	xmlto -o $@/$@1 $@ $<

html: $(srcDir)/manual.xml
	xmlto -o $@/manual xhtml $<
	xmlto -o $@ xhtml-nochunks $(srcDir)/history.xml
	xmlto -o $@ xhtml-nochunks $(srcDir)/readme.xml

text: $(srcDir)/manual.xml
	xmlto -o $@ txt $<
	xmlto -o $@ txt $(srcDir)/history.xml
	xmlto -o $@ txt $(srcDir)/readme.xml

dist: all
	cp text/readme.txt ../README
	cp text/history.txt ../HISTORY
	cp html/*.html ..

