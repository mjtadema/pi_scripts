#!/bin/bash

########################################
##	Written by Matthijs Tadema    ##
########################################
	
ver="0.1.0"

set -e

# TODO: parse arguments
# make sending mail optional
# make service info optional
o_sendmail=1
o_details=0

addr="M.J.Tadema@protonmail.com"

# Function to handle failing properly

function fail()
{
	msg=$1
	echo "Failure with message:" 1>&2
	echo "$msg" 1>&2
	echo "Now exiting" 1>&2
	exit 1
}

# Check if user is root
if [[ $EUID -ne 0 ]]
then
	fail "User is not root"
fi

# For service in list
services=(
	"syncthing@matthijs.service"
	"lighttpd.service"
	"sshd.service"
	"httpd.service"
	"pihole-FTL.service"
	"postgresql.service"
	"openvpn-server@server.service"
)

notrunning=()
for s in ${services[@]}
do
	# Check if service is running
	if [ "$(systemctl is-active $s)" != "active" ]
	then
		# Add non running service to list
		notrunning+=("$s")
	fi
done

# Function to make reporting easier
function report()
{
	toadd="$1"
	reporttext="$reporttext $toadd \n"
}

# Small function to send mails to M.J.Tadema@protonmail.com
function mailtext()
{
	subj="Report from $0 \@ raspberry pi"
	msg="$1"
	mail -s "$subj" "$addr" <<< "$(echo -e "$msg" | sed 's/\n/\r/g')"
	return $?
}


# Compile report of running services
# If there is anything to report
if [ ${#notrunning[@]} -ne 0 ]
then
	reporttext=""
	report "Some services are not running:" # header
	report "\n"
	
	for s in ${notrunning[@]}
	do
		# TODO Gather information about service
		# Append name service name to list
		report "\t$s"
	done
	
	report "\n"
	report "This concludes the report"
	
	# Print report
	echo -e "$reporttext"
	
	# Send email only if service is not running
	if [ $o_sendmail -eq 1 ]
	then
		mailtext "$reporttext" && echo "mail was sent to $addr" || fail "Mail could not be send"
	fi
fi

# Exit gracefully
exit 0

