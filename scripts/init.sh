#!/bin/bash
sourceBase=$(dirname $SOURCE)/../
cd ${basedir:-$sourceBase}

basedir=$(pwd -P)
cd -

FORK_NAME="LightPaper"
API_REPO=""
SERVER_REPO=""
PAPER_API_REPO=""
PAPER_SERVER_REPO=""
MCDEV_REPO=""

function bashColor {
if [ $2 ]; then
	echo -e "\e[$1;$2m"
else
	echo -e "\e[$1m"
fi
}
function bashColorReset {
	echo -e "\e[m"
}

function pushRepo {
	if [ "$(git config minecraft.push-${FORK_NAME})" == "1" ]; then
	echo "Pushing - $1 ($3) to $2"
	(
		cd "$1"
		git remote rm emc-push > /dev/null 2>&1
		git remote add emc-push $2 >/dev/null 2>&1
		git push emc-push $3 -f
	)
	fi
}
function basedir {
	cd "$basedir"
}
function gethead {
	(
		cd "$1"
		#git log -1 --oneline
		git rev-parse --short HEAD
	)
}
