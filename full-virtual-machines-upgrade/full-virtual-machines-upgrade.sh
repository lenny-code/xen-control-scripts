#!/bin/bash

# This script accepts either none arguments or just one.
# So let's make sure to catch all other cases.
if [ $# -gt 1 ]
then
	printf "usage: ./full-virtual-machines-upgrade.sh [--reboot]\n"

	exit 3
fi

dom0=`cat /etc/hostname`

# First, let's update and upgrade Domain-0
printf "Updating your Domain-0 (${dom0}):\n"
sudo apt-get update

printf "\nUpgrading Domain-0:\n"
sudo apt-get upgrade

printf "\nPossible autoremove on Domain-0:\n"
sudo apt-get autoremove

printf "\nDone.\n\n\n"

# After that, we need all running virtual machines except for Domain-0 (thus NR>2).
allMachines="$(sudo xm list | awk -F '[ ]' '{ print $1 }' | awk 'NR>2')"

# Now we iterate over each found machine name.
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

	# We assume that everything went smoothely.
	printf "\nDone.\n\n\n"
done


# If the "--reboot" flag was selected, let's reboot
# every virtual machine after the full system upgrade.
if [[ $# == 1 && "${1}" == "--reboot" ]]
then
	printf "\n\nA reboot of the upgraded virtual machines was selected.\n"

	# We make use of the XEN internal tools here.
	sudo xm reboot -aw

	printf "\n\nAll upgrades and reboots done."
fi


# Return a success exit code
exit 0
