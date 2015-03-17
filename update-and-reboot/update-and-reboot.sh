#!/usr/bin/env bash

# This is a control script for XEN virtualized servers.
# It aims to provide a simple update and upgrade as well
# as a simple reboot functionality.
# If rebooted we assume there is a NFS instance running
# anywhere which we need to restart first and mount on
# each other machine after successfull reboot.



# Variables

# Save the Domain-0 host name for later use.
dom0=$(cat /etc/hostname)

# Define your NFS machine here.
nfsMachine=<NFS-MACHINE>

# After that, we need all running virtual machines except for Domain-0 (thus NR>2).
allMachines=$(sudo xm list | awk '{if(NR>2){print $1}}')

# Specify your XEN domains path.
xenDomPath=/etc/xen/domains

# Set the timeout in seconds after NFS start.
nfsTimeout=120



# Functions

# Prints usage of script and exits with failure return value.
usage() {

	printf "Usage: ${0} [ -u | -r | -s | -m ]\n"
	printf "   -u: update and upgrade all domains\n"
	printf "   -r: reboot all Domain-Us and Domain-0 after that\n"
	printf "   -s: start all Domain-Us\n"
	printf "   -m: mount NFS shares on all Domain-Us (mount -a)\n\n"
	printf "Usually you'll do -u and -r in the first run.\n"
	printf "After successfull reboot you'll run the script again with -s and -m only.\n"

	exit 1
}


# Update and upgrade all machines.
updAndUpg() {

	# First, let's update and upgrade Domain-0
	printf "Updating your Domain-0 (${dom0}):\n"
	sudo apt-get update

	printf "\nUpgrading Domain-0:\n"
	sudo apt-get upgrade

	printf "\nPossible autoremove on Domain-0:\n"
	sudo apt-get autoremove

	printf "\nDone.\n\n\n"


	# Now iterate over each found machine name.
	for line in ${allMachines}
	do
		# Log what we are about to do.
		printf "Updating machine: ${line}.\n"

		# SSH onto each machine, execute a full system upgrade
		# and clean up unused packages after that.
		ssh "${line}" /bin/bash << EOF
			apt-get update;
			printf "\nUpgrading:\n";
			apt-get upgrade -y;
			printf "\nPossible autoremove:\n";
			apt-get autoremove -y;
			exit;
EOF

		# We assume everything went smoothely.
		printf "\nDone.\n\n"
	done

	printf "Done updating and upgrading.\n\n\n"

	exit 0
}


# Reboot all Domain-Us and Domain-0.
rebAllDoms() {

	# Iterate over machines and shut each one down gracefully.
	for line in ${allMachines}
	do
		printf "Gracefully shutting down machine: ${line}.\n"

		sudo xm shutdown ${line}

		printf "Shut down successfull: ${line}.\n\n"
	done

	printf "Shutting down Domain-0 (${dom0}).\n"

	# Now reboot Domain-0. Maybe manual interaction is required.
	sudo reboot

	exit 0
}


# Start all Domain-Us in $xenDomPath.
startAllDoms() {

	printf "Starting the NFS machine (${nfsMachine}) first.\n"

	# First, start the NFS machine.
	sudo xm create ${xenDomPath}/${nfsMachine}.cfg

	printf "Started domain: ${nfsMachine}.\n\n"
	printf "Now, wait for some time to be sure the NFS machine is up (${nfsTimeout} seconds).\n"

	# Increase this variable each second by 1.
	nfsStart=0

	while [ ${nfsStart} -lt ${nfsTimeout} ]
	do
		printf "."
		sleep 1
		nfsStart=$((${nfsStart}+1))
	done

	printf "\n\n"


	# Iterate over all existing configuration
	# files in $xenDomPath.
	for dom in ${xenDomPath}/*
	do

		# Only start found domain if it is not
		# the NFS machine.
		if [ "${dom}" != "${xenDomPath}/${nfsMachine}.cfg" ]
		then
			printf "Found domain: ${dom}.\n"

			# Create a machine instance with XEN.
			sudo xm create ${dom}

			printf "Started domain: ${dom}.\n\n"
		fi
	done

	printf "Done starting all domains.\n\n\n"

	exit 0
}


# SSH onto each machine and execute 'mount -a'.
mountNFS() {

	# Iterate over each found machine name.
	for line in ${allMachines}
	do
		# Log what we are about to do.
		printf "Mounting NFS shares on machine: ${line}.\n"

		# SSH onto each machine and execute mount.
		ssh "${line}" /bin/bash << EOF
			mount -a;
			exit;
EOF

		# We assume everything went smoothely.
		printf "\nDone mounting.\n\n\n"
	done

	printf "Done mounting on all machines.\n\n\n"

	exit 0
}




# Main

# We expect at least one argument.
if [ $# -eq 0 ]
then
	usage
fi


# Get passed arguments with getopts.
while getopts ":ursm" opt; do

	case $opt in

		u)
			printf "Starting update and upgrade routine (-u).\n\n"
			updAndUpg
			;;
		r)
			printf "Rebooting all Domain-Us and Domain-0 (-r).\n\n"
			rebAllDoms
			;;
		s)
			printf "Starting all Domain-Us (-s). First one will be the NFS machine.\n\n"
			startAllDoms
			;;
		m)
			printf "Mounting NFS shares on all Domain-Us (-m).\n\n"
			mountNFS
			;;
		\?)
			printf "Invalid argument. See usage below.\n\n"
			usage
			;;
	esac
done


# Return success
exit 0
