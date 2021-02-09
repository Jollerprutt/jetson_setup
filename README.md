# jetson_setup
Tested on AGX xavier.

The script can setup SSH keys for github access and setup and start wireguard for vpn access.

To setup ssh keys add your key(s) to the directory ssh_keys_host, they will be copied to ~/.ssh.
Private keys will be added to an ssh agent.
If no ssh keys are found a pair will be generated and public key displayed by the script.

To setup wireguard simply add .conf file(s) to the wg_conf directory.
All wireguard configurations will be added as systemd services.

To setup a new xavier, clone the repo and run basic-setup.sh
