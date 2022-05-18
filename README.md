# jetson_setup
Tested on AGX Xavier and Xavier NX.

The script can setup SSH keys for github access and setup and start wireguard for vpn access.

To setup ssh keys add your key(s) to the directory ssh_keys_host, they will be copied to ~/.ssh.
Private keys will be added to an ssh agent.
If no ssh keys are found a pair will be generated and public key displayed by the script.

To setup wireguard simply add .conf file(s) to the wg_conf directory.
All wireguard configurations will be added as systemd services.

**For personal machines, make sure you have access to smarc-project on github and gitr.
Otherwise make sure you have Carl ready to add your SSH key to the machine accounts for you**

To setup a new xavier, clone the repo and run basic-setup.sh

It will ask for the password twice, after asking the second time it will present you with a SSH key if one is not already available.
The script will pause for 30 min to give you time to add a generated SSH key, you can conntinue earlier by clicking any key.

Once you are past the SSH configuration you can leave the installation and have some coffee :)
