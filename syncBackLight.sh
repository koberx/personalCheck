#!/bin/bash
sysMaxBltPath="/sys/class/backlight/intel_backlight/max_brightness"
sysBltPath="/sys/class/backlight/intel_backlight/brightness"
sysActualBltPath="/sys/class/backlight/intel_backlight/actual_brightness"
bltConfPath="/etc/UserCfg/backlightBrightness"

function checkGpuDriverExist()
{
	local name=`lsmod | grep -i i915 | head -n 1 | awk '{print $1}'`
	if [ "$name" = "i915" ]; then
		echo "true"
	else
		echo "false"
	fi
}

function checkBackLightDriverExist()
{
	if [ -f $sysBltPath ]; then 
		echo "true"
	else
		echo "false"
	fi
}

function loadGpuDriver()
{
	/sbin/modprobe i915
	echo 0000:00:02.0 > /sys/bus/pci/devices/0000\:00\:02.0/driver/unbind
	echo 0000:00:02.0 > /sys/bus/pci/drivers/i915/bind
}

function restoreBltValue()
{
	if [ "$(checkGpuDriverExist)" = "true" ] && [ "$(checkBackLightDriverExist)" = "true" ]; then # check  the i915 and backlight driver
		if [ ! -f $bltConfPath ]; then    # if the file no exist set the backlight value in 80% of the maximum
			bltMax=`cat $sysMaxBltPath`
			bltDefault=$(expr $bltMax \* 8 / 10)
			echo "maxBrightness=$bltMax" > $bltConfPath
			echo "brightness=$bltDefault" >> $bltConfPath
			echo $bltDefault > $sysBltPath
		else
				bltDefault=`cat $bltConfPath | grep '^brightness' | awk -F "=" '{print $2}'`  # set the backlight value which save in file
				echo $bltDefault > $sysBltPath
		fi
	fi
}

function checkMaxBlt()
{
	if [ $1 -ne $2 ]; then #if the maxValue of backlight changed
		sed -i "s/^maxBrightness=.*/maxBrightness=$2/" $bltConfPath 
		sed -i "s/^brightness=.*/brightness=$(expr $2 \* $3 / $1)/" $bltConfPath #save the new brightness in old percent
	fi
}

function checkUserBlt()
{
	local bltUser=`cat $sysActualBltPath`
    local bltDefault=`cat $bltConfPath | grep '^brightness' | awk -F "=" '{print $2}'`
	echo "bltUser=$bltUser bltDefault=$bltDefault"
	if [ $bltUser -eq 0 ]; then  # if the backlight value is zero , set the 10% of max_brightness and save it.
		bltDefault=$(expr $1 / 10)
		sed -i "s/^brightness=.*/brightness=$bltDefault/" $bltConfPath
		echo $bltDefault > $sysBltPath
	else
		if [ $bltUser -ne $bltDefault ]; then
			sed -i "s/^brightness=.*/brightness=$bltUser/" $bltConfPath
		fi
	fi
}

function checkAndSaveBlt()
{	
	if [ "$(checkBackLightDriverExist)" = "true" ]; then #check the backlight driver
		local maxDefaultBltMax=`cat $bltConfPath | grep '^maxBrightness' | awk -F "=" '{print $2}'`
		local bltDefault=`cat $bltConfPath | grep '^brightness' | awk -F "=" '{print $2}'`
		local sysBltMax=`cat $sysMaxBltPath`
		checkMaxBlt $maxDefaultBltMax $sysBltMax $bltDefault # if maxBrightness change update the maxBrightness and brightness
		checkUserBlt $sysBltMax
	fi
}

function saveBltValue()
{
	if [ "$(checkGpuDriverExist)" = "true" ]; then  	# if i915 driver is exist.
		checkAndSaveBlt
	else
		loadGpuDriver   # i915 driver not exist add the i915 driver for sync the backlight value.	
		checkAndSaveBlt
	fi
}

if [ $# -ne 0 ]; then
	case "$1" in
		poweroff)
			saveBltValue
			/bin/systemctl --force poweroff
			;;
		reboot)
			saveBltValue
			/bin/systemctl --force reboot
			;;
		restoreBlt)
			restoreBltValue
			;;
		saveBlt)
			saveBltValue
			;;
		*)
			echo "Error: Unknown argument \"$1\""
			;;
	esac
fi

