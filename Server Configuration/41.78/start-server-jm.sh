#!/bin/bash
#
###############################################################################
#
# Edit memory option -Xmx in ProjectZomboid64.json for 64bit servers (common)
#   or ProjectZomboid32.json for 32bit servers (rare)
#
############

INSTDIR="`dirname $0`" ; cd "${INSTDIR}" ; INSTDIR="`pwd`"

if ! jq --version > /dev/null 2>&1
then
	printf "Missing required library: jq.\nInstall using 'sudo apt install jq' command\n"
	exit
fi

if "${INSTDIR}/jre64/bin/java" -version > /dev/null 2>&1; then
	echo "64-bit java detected"
	export PATH="${INSTDIR}/jre64/bin:$PATH"
	export LD_LIBRARY_PATH="${INSTDIR}/linux64:${INSTDIR}/natives:${INSTDIR}:${INSTDIR}/jre64/lib/amd64:${LD_LIBRARY_PATH}"
	#JSIG="libjsig.so"
	#LD_PRELOAD="${LD_PRELOAD}:${JSIG}" ./ProjectZomboid64 "$@"
	PZ_CLASSPATH=$(jq ".classpath" ProjectZomboid64.json | tr -d '\n\" []' | tr ',' ':')
	PZ_ARGS=$(jq ".vmArgs" ProjectZomboid64.json | tr -d '\n\" []' | tr ',' ' ')
	./jre64/bin/java $PZ_ARGS -cp $PZ_CLASSPATH zombie.SSROverride $@
elif "${INSTDIR}/jre/bin/java" -client -version > /dev/null 2>&1; then
	echo "32-bit java detected"
	export PATH="${INSTDIR}/jre/bin:$PATH"
	export LD_LIBRARY_PATH="${INSTDIR}/linux32:${INSTDIR}/natives:${INSTDIR}:${INSTDIR}/jre/lib/i386:${LD_LIBRARY_PATH}"
	#JSIG="libjsig.so"
	#LD_PRELOAD="${LD_PRELOAD}:${JSIG}" ./ProjectZomboid32 "$@"
	PZ_CLASSPATH=$(jq ".classpath" ProjectZomboid32.json | tr -d '\n\" []' | tr ',' ':')
	PZ_ARGS=$(jq ".vmArgs" ProjectZomboid32.json | tr -d '\n\" []' | tr ',' ' ')
	./jre/bin/java $PZ_ARGS -cp $PZ_CLASSPATH zombie.SSROverride $@
else
	echo "couldn't determine 32/64 bit of java"
	exit
fi
exit 0

#
# EOF
#
###############################################################################