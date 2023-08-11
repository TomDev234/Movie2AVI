#!/bin/sh

#  encodeFile.sh
#  Movie2AVI
#
#  Created by Tom on 13.10.14.
#  Copyright (c) 2014 Thomas Bodlien Software. All rights reserved.

echo "Starting Encoder"
"${1}" -i "${2}" -c:v mpeg4 -qscale:v "${3}" -c:a libmp3lame -qscale:a "${4}" ${5} "${6}"
echo "Encoder finished"
