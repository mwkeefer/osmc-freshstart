#!/bin/bash

#
# Filename:		osmc-freshstart.sh
# Description:	Script to restore osmc to system default, removing packages and configuration files
#				of any packages you may have installed on top of the default osmc installed system.
# Author:		Mike Keefer (mwkeefer at gmail dot com)
# Created:		08/14/2015
#

#
# ** WARNING:  USE AT YOUR OWN RISK!
#

#
# * Tested with many packages including: lxde desktop (x desktop), tightvncserver, vim, zip, unzip, mate-desktop, transmission, etc.
#
#	[Example Test]
#
#	Using: sudo apt-get install tightvncserver transmission
#	Pre-install disk usage:						1611816960 Bytes Used, 5633810432 Bytes Free (from df -B1)
#	Packages installed:							97
#	Archives downloaded:						32.7 MB / 99 Archive Files
#	Apt-get indicated additional disk space:	120 MB
#	Post-install disk usage:					1777987584 Bytes Used, 5467639808 Bytes Free  (from df -B1)
#
#	Using: osmc-freshstart.sh and chosing remove package archives:
#	Packages removed:							97
#	Archives removed:							97
#	Post freshstart disk usage:					1612431360 Bytes Used,  5633196032 Bytes Free (from df -B1)
#	Post reboot disk usage:						
# 	*NOTE	Due to disk overheads like journaling, etc... the space available after cleanup will differ from pre-install by a small amount
#			this is normal and should not cause concern.
#	
# * NOTE: After entering Y to confirm package removal and When cleaning up a huge mess (multiple xdesktops, 
#	vnc, misc. apps installed on whim, xorg packages, etc) this script may take quite some time once it launches
#   apt. This is 100% normal and should be allowed to continue without interruption.
#

###################################################################
# Subroutines:
###################################################################

cleanup()
{
	# If temp path exists, remove it to cleanup any previous temporary files which may be present.
	if [ -s .tmp ]
	then
		rm -r .tmp
	fi
	
	# create an empty temp directory
	mkdir .tmp
}

initialize()
{

	#
	# Variables
	_removepackages=false	
	_removearchives=false
	declare -i _pkgcount=0	
	declare -i _archivecount=0
	declare -i _returncode=0
	
	#
	# Paths
	 scriptpath=$PWD						# The current script path
	 temppath=$scriptpath/.tmp				# Temporary files path
	 basepkgspath=$scriptpath/packages-base	# Path containing osmc and user required packages lists
	
	#
	# Files used by script
	 _temp=$temppath/work.tmp				# Single temp file for processing of all the lists.
	 _installed=$temppath/installed-packages
	 _current=$temppath/current-osmc-required-packages
	 _system=$basepkgspath/base-system-osmc-packages
	 _user=$basepkgspath/base-user-osmc-packages
	 _keep=$scriptpath/keep-packages/keep-packages
	 _remove=$temppath/remove-these-packages
	 _removed=$scriptpath/removed-packages.txt
	
	#
	# Clear the temp directory if needed.
	cleanup
	
	clear
}


###################################################################
# Main()
###################################################################

initialize

echo
echo Building list of installed packages to be removed...

#
# Create a list of ALL currently installed packages
dpkg --get-selections | awk '{print $1}' | xargs > "$_temp"
sed -e 's/\s\+/\n/g' "$_temp" > "$_installed"

#
# Create list of currently required osmc installed packages (containing osmc in the name)
dpkg --get-selections | grep "osmc" | awk '{print $1}' | xargs > $_temp
sed -e 's/\s\+/\n/g' $_temp > $_current

#
# Exclude currrent system required packages from remove list
join -v 1 <(sort $_installed) <(sort $_current) > $_remove

#
# Exclude osmc base system required packages from remove list
join -v 1 <(sort $_remove) <(sort $_system) > $_temp
mv $_temp $_remove

#
# Exclude osmc base user required packages from remove list
join -v 1 <(sort $_remove) <(sort $_user) > $_temp
mv $_temp $_remove

#
# Are there any packages still to be removed after above exclusions
if [ -s $_remove ]
then
	
	# Should we exclude any more packages (checks keep-packages in the script folder)
	if [ -s $_keep ]
	then
		# Filter remove packages list, eliminate packages user wants to keep.
		printf %s "$(< $_keep)" > $_temp
		mv $_temp $_keep
		join -v 1 <(sort $_remove) <(sort $_keep) > $_temp
		mv $_temp $_remove
	fi
	
	#
	# Does remove list exist and have entries, if so perform package removal and cleanup
	if [ -s $_remove ]
	then
	
		#
		# Get the number of packages to be removed
		_pkgcount=$(wc -l < $_remove)
		_archivecount=$(ls -1 /var/cache/apt/archives/ | wc -l)
		let _archivecount=_archivecount-2
		
		echo 
		echo "The following "$_pkgcount" package(s) will be removed:"
		echo "---------------------------------------------------------------------"
		#
		# Display list of packages to be removed for the user.
		cat $_remove
		
		echo "---------------------------------------------------------------------"
		echo
		
		#
		# Get user confirmation to remove packages...
		while true; do
			read -p "Remove "$_pkgcount" package(s)? (y or n) " yn
			case $yn in
				[Yy]* ) _removepackages=true; break;;
				[Nn]* ) _removepackages=false; break;;
				* ) echo "Please answer y or n.";;
			esac
		done

		#
		# Does the user want to remove the package archives too?
		if [ "$_removepackages" = true ]
		then
			while true; do
				read -p "Remove "$_archivecount" package archive(s) (y or n) " yn
				case $yn in
					[Yy]* ) _removearchives=true; break;;
					[Nn]* ) _removearchives=false; break;;
					* ) echo "Please answer y or n.";;
				esac
			done
		fi
				
		#
		# Did the user chose to remove packages or not?
		if [ "$_removepackages" = true ]
		then
			#
			# User elected to remove packages, perform removal

			if [ "$_removearchives" = true ]
			then
				echo
				echo "Removing "$_pkgcount" package(s) and "$_archivecount" package archive(s)..."
				echo

				# Remove the selected packages
				sudo apt-get remove --purge -y $(cat $_remove)

				# Remove the package archives
				sudo apt-get clean -y
				
				echo
				echo $_pkgcount" package(s) and "$_archivecount" package archive(s) removed successfully."
				
			else
							echo
				echo 'Removing packages...'
				echo
				
				# Remove the selected packages
				sudo apt-get remove --purge -y $(cat $_remove)

				echo
				echo $_pkgcount" packages removed successfully."
			fi
						#
			# Move the removed packages list to text file.
			mv $_remove $_removed
			
			#
			# Feedback for the user.
			echo
			echo Selected packages have been removed from your OSMC install.
			echo Please reboot your Pi for changes to take effect, using \'shutdown -r now\'
			echo or use the GUI reboot option in Kodi.
			echo
			echo Done.
			exit $returncode
		else
			#
			# Done here too, exit and return success
			echo
			echo User canceled package removal.
			echo Done.
			echo
			exit $returncode
		fi
	fi
fi

#
# If we arrive here, there were NO packages to be removed so
# we simply exit gracefully after notifiying the user.
echo
echo No packages to be removed located, your system is already clean.
echo Done.
echo
