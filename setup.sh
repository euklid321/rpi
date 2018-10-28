#!/bin/bash

cat /etc/os-release | perl -ne "exit(1), if (/ID_LIKE=debian/)"
if [ $? != 1 ]; then
	echo "** Looks like you're not on a Debian-like system, and I need 'apt'. Sorry."
	exit -1
fi

IS_RPI=1
REQ_FILE=requirements.txt

cat /etc/os-release | perl -ne "exit(1), if (/ID=raspbian/)"
if [ $? != 1 ]; then
	echo "* Looks like you're installing on a non-RPi platform; omitting unneeded modules."
	IS_RPI=0
	REQ_FILE=requirements-nonRPi.txt
fi

echo -n "* Checking for virtualenv: "
which virtualenv > /dev/null

if [ $? == 1 ]; then
	echo "NOT FOUND"
	echo "* Trying to 'sudo apt -y install virtualenv':"
	sudo apt -y install virtualenv
else
	echo "OK"
fi

echo -n "* Checking for redis: "
which redis-server > /dev/null

if [ $? == 1 ]; then
	echo "NOT FOUND"
	echo "* Trying to 'sudo apt -y install redis':"
	sudo apt -y install redis
else
	echo "OK"
fi

if [ ${IS_RPI} == 1 ]; then
	echo -n "* Checking for python-smbus: "
	apt list --installed 2> /dev/null | grep python-smbus > /dev/null

	if [ $? == 1 ]; then
		echo "NOT FOUND"
		echo "* Trying to 'sudo apt -y install python-smbus':"
		sudo apt -y install python-smbus
	else
		echo "OK"
	fi
fi

if [ ! -d "./env" ]; then
	echo "* Initializing virtualenv:"
	virtualenv --system-site-packages --prompt="(rpjios virtualenv) " ./env
fi

echo "* Activating virtualenv"
source env/bin/activate

echo "* Linking lib/rpjios"
if [ ! -L "env/lib/python2.7/site-packages/rpjios" ]; then
	pushd "env/lib/python2.7/site-packages/" > /dev/null
	ln -s "../../../../lib/rpjios"
	popd > /dev/null
fi

echo -n "* Installing required python modules from '${REQ_FILE}': "
pip install -r ${REQ_FILE}

if [ $? == 0 ]; then
	echo ""
	echo "*** Done! Run 'source env/bin/activate' to get started."
else
	echo "*** ERROR ***"
fi
