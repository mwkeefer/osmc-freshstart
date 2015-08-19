#
# Script Package:	osmc-packages-freshstart
#
# Purpose:		This script will enable osmc (www.osmc.tv) users to easily refresh their installs back to fresh installed state by
				removing any user installed packages and configuration files automatically.  The script is written specifically to prevent
				the removal of osmc required or installed packages while performing the cleaning.  The goal is to provide osmc users with a method
				of reversing their changes (x desktop, window managers, etc.) thus enabiling them to experiment without as much concern or the need
				to perform a complete re-install of osmc base to get back to clean install status.
# Author:		Mike Keefer (mwkeefer.github@gmail.com)
# Created:		08/14/2015

# Usage:

#
# If kodi is running, it is a good idea (not required) to shut it down:
#
sudo systemctl stop mediacenter

#
# Execute the osmc-freshstart.sh script.
#
cd
cd osmc-packages-freshstart
./osmc-freshstart.sh

#
# Follow the onscreen prompts answering y or n to removing packages and package archives.
#

#
# Reboot your OSMC system:
#
shutdown -r now

#
# That's it, your done and will have a virgin system on reboot.
#