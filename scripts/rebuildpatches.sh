#!/bin/bash
# get base dir regardless of execution location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ ${SOURCE} != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
. $(dirname ${SOURCE})/init.sh

gitcmd="git -c commit.gpgsign=false -c core.safecrlf=false"

PS1="$"
nofilter="0"
if [ "$2" = "nofilter" ]; then
    nofilter="1"
fi

function cleanupPatches {
	cd "$1"
	for patch in *.patch; do

		diffs=$($gitcmd diff --staged "$patch" | grep --color=none -E "^(\+|\-)" | grep --color=none -Ev "(\-\-\- a|\+\+\+ b|^.index)")

		if [ "x$diffs" == "x" ] ; then
			git reset HEAD $patch >/dev/null
			git checkout -- $patch >/dev/null
		fi
	done
}

echo "Rebuilding patch files from current fork state..."
function savePatches {
	what=$1
	cd ${basedir}/${what}/

	mkdir -p ${basedir}/patches/$2
	if [ -d ".git/rebase-apply" ]; then
		# in middle of a rebase, be smarter
		echo "REBASE DETECTED - PARTIAL SAVE"
		last=$(cat ".git/rebase-apply/last")
		next=$(cat ".git/rebase-apply/next")
		declare -a files=("$basedir/patches/$2/"*.patch)
		for i in $(seq -f "%04g" 1 1 ${last})
		do
			if [ ${i} -lt ${next} ]; then
				rm "${files[`expr ${i} - 1`]}"
			fi
		done
	else
		rm ${basedir}/patches/$2/*.patch
	fi

	$gitcmd format-patch --zero-commit --full-index --no-signature -N -o ${basedir}/patches/$2 upstream/upstream
	cd ${basedir}
	$gitcmd add -A ${basedir}/patches/$2
	if [ "$nofilter" == "0" ]; then
		cleanupPatches ${basedir}/patches/$2/
	fi
	echo "  Patches saved for $what to patches/$2"
}

savePatches ${FORK_NAME}-API api
if [ -f "$basedir/${FORK_NAME}-API/.git/patch-apply-failed" ]; then
	echo "$(bashColor 1 31)[[[ WARNING ]]] $(bashColor 1 33)- Not saving Paper-Server as it appears ${FORK_NAME}-API did not apply clean.$(bashColorReset)"
	echo "$(bashColor 1 33)If this is a mistake, delete $(bashColor 1 34)${FORK_NAME}-API/.git/patch-apply-failed$(bashColor 1 33) and run rebuild again.$(bashColorReset)"
	echo "$(bashColor 1 33)Otherwise, rerun ./paper patch to have a clean Paper-API apply so the latest Paper-Server can build.$(bashColorReset)"
else
	savePatches ${FORK_NAME}-Server server
	${basedir}/scripts/push.sh
fi


