#!/bin/bash
sysMaxBltPath="/sys/class/backlight/intel_backlight/max_brightness"
sysBltPath="/sys/class/backlight/intel_backlight/brightness"
sysActualBltPath="/sys/class/backlight/intel_backlight/actual_brightness"
bltConfPath="/etc/UserCfg/backlightBrightness"
bltConfDir="/etc/UserCfg"
sysPciDriverUnbind="/sys/bus/pci/devices/0000\:00\:02.0/driver/unbind"
sysPciDriverBind="/sys/bus/pci/drivers/i915/bind"

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
	if [ -f $sysPciDriverUnbind ]; then
		echo 0000:00:02.0 > $sysPciDriverUnbind
	fi
	echo 0000:00:02.0 > $sysPciDriverBind
}

function setDefaultBrightness()
{
	local bltMax=`cat $sysMaxBltPath`
	local bltDefault=$(expr $bltMax \* 8 / 10)
	if [ ! -f $bltConfPath ]; then
		echo "maxBrightness=$bltMax" > $bltConfPath
		echo "actBrightness=$bltDefault" >> $bltConfPath
	fi
	echo $bltDefault > $sysBltPath
}

function restoreBltValue()
{
	if [ "$(checkGpuDriverExist)" = "true" ] && [ "$(checkBackLightDriverExist)" = "true" ]; then # check  the i915 and backlight driver
		if [ ! -f $bltConfPath ]; then    # if the file not exist set the backlight value in 80% of the maximum
			if [ ! -f $bltConfDir ]; then  #if the config dir not exist , create it
				mkdir $bltConfDir
			fi
			setDefaultBrightness
		else
				bltDefault=`cat $bltConfPath | grep '^actBrightness' | awk -F "=" '{print $2}'`  # set the backlight value which save in file
				if [ ! $bltDefault ]; then # if not get brightness, set the backlight value in 80% of the maximum
					setDefaultBrightness
				else
					echo $bltDefault > $sysBltPath
				fi
		fi
	fi
}

#param: $1(maxBrightness of save) $2(maxBrightness of sys) $3(brightness of save)
function checkMaxBlt()
{
	if [ $1 -ne $2 ]; then #if the maxValue of backlight changed
		sed -i "s/^maxBrightness=.*/maxBrightness=$2/" $bltConfPath 
		sed -i "s/^actBrightness=.*/actBrightness=$(expr $2 \* $3 / $1)/" $bltConfPath #save the new brightness in old percent
	fi
}

#param: $1(maxBrightness of sys)
function checkUserBlt()
{
	local bltUser=`cat $sysActualBltPath`
	local bltDefault=`cat $bltConfPath | grep '^actBrightness' | awk -F "=" '{print $2}'`
	if [ $bltUser -eq 0 ]; then  # if the backlight value is zero , set the 10% of max_brightness and save it.
		bltDefault=$(expr $1 / 10)
		sed -i "s/^actBrightness=.*/actBrightness=$bltDefault/" $bltConfPath
		echo $bltDefault > $sysBltPath
	else
		if [ $bltUser -ne $bltDefault ]; then
			sed -i "s/^actBrightness=.*/actBrightness=$bltUser/" $bltConfPath
		fi
	fi
}

function checkAndSaveBlt()
{	
	if [ "$(checkBackLightDriverExist)" = "true" ]; then #check the backlight driver
		local maxDefaultBltMax=`cat $bltConfPath | grep '^maxBrightness' | awk -F "=" '{print $2}'`
		local bltDefault=`cat $bltConfPath | grep '^actBrightness' | awk -F "=" '{print $2}'`
		local sysBltMax=`cat $sysMaxBltPath`
		checkMaxBlt $maxDefaultBltMax $sysBltMax $bltDefault # if maxBrightness change update the maxBrightness and brightness
		checkUserBlt $sysBltMax
	fi
}

function saveBltValue()
{	
	if [ "$(checkGpuDriverExist)" = "false" ]; then  	# if i915 driver is exist.
		loadGpuDriver   # i915 driver not exist add the i915 driver for sync the backlight value.
	fi	
	checkAndSaveBlt
}

if [ $# -ne 0 ]; then
	case "$1" in
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


