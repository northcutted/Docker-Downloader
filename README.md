# Docker Downloader

## Sets up everything you need to download linux distros.

Requires: Docker, Docker-Compose

Usage:

```shell
init.sh path/to/install/location path/to/media/storage/location
```

First time set up will install the compose file in `INSTALL_LOCATION` and will exit, prompting you to add your username and password to the compose file to authenticate with PIA. Any runs after that will just start up the stack.

To start at boot:

```shell
crontab -e
```

Add this and next time you reboot, it'll start back up next time you reboot:

```cron
@reboot sleep 5 && /path/to/init.sh INSTALL_LOCATION MEDIA_LOCATION
```