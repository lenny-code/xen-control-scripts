# full-virtual-machines-upgrade

This script is my approach to simplify the updating and upgrading process of our via XEN virtualised machines on our server.

## Requirements

The script assumes the server is running a distribution which handles its package management via 'apt-get'.

I would recommend to have a working ssh environment on your domain-0 with one specific user having a SSH config somewhat like this:

```bash
$ cat ~/.ssh/config
Host machine-1-name
HostName 10.0.0.0
User root

Host machine-2-name
HostName 10.0.0.1
User root

Host machine-x-name
HostName 10.0.0.x
User root
```

The important part of this is the 'Host' line. The script uses the machine name as the ssh target like

```bash
ssh machine-1-name
```

Copy the public key of the domain-0 only SSH key into each virtual machines ~/.ssh/authorized_keys.

As the amount of virtual machines probably grows over time it might be a good idea to add the domain-0 only SSH key to the ssh-agent. This allows you to have a private key password and still don't have to retype this password each time the script attempts to update the next machine. The other way would be a SSH key without a password which is something to avoid. So, in order to add the SSH key to your ssh-agent first make sure the ssh-agent is running, by executing

```bash
eval $(ssh-agent)
```

After that you should be able to add your domain-0 only SSH key to the agent by running

```bash
ssh-add ~/.ssh/your_id_file
```

It will prompt you to enter the private key password just one time each session and after that uses it to automatically submit the private key password request.

# Usage

After the SSH setup is done the usage of this script is simple. You can either just update and upgrade every machine or trigger an additional reboot of each machine with the extra flag "--reboot".

So to just update and upgrade run this from domain-0 on the user which SSH key is on each machine

```bash
./full-virtual-machines-upgrade.sh
```

and enter the user's password.

To trigger an additional reboot of each machine after the updates, run

```bash
./full-virtual-machines-upgrade.sh --reboot
```

and enter the user's password.

You should see some logging about which machine is updated at the moment and also the SSH output (complete apt-get output).
