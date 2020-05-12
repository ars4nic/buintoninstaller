#!/bin/zsh
SCRIPTPATH=$(dirname "$SCRIPT")
if [ $1 = "-r" ]; then 
	input="$SCRIPTPATH/fails.txt"
else 
	input="$SCRIPTPATH/aptinstall.txt"
fi

pkgct=`wc -l < $input`

progbar=""

w=`tput cols`
h=`tput lines`
clear
printf -v mbb "\e[32m Buinton Package Manager 1.0"



progbar()
{
	

	if [ $# -eq 2 ]; then  
	
		if [ "$1" = "-i" ]; then 
			currentct="0"
       			n=0		
		fi	

		progbarl=$(expr $w - 10)
		itemct=$(expr $2 - 1)
#		printf "\r[%-${progbarl}s](%2d%%)" "" ""
	fi
	


	progbarc=`echo "${progbarl}/${itemct}*${currentct}" | bc -l | awk '{print int($1+0.5)}'`
	

	while [ $n -lt $progbarc ]; do
		progbar="${progbar}#"
		n=$(expr $n + 1)



		printf -v progout "[\e[32m%-${progbarl}s\e[39m](%2d%%)\e[0;49m" "$progbar" "`echo "${progbarc}/${progbarl}*100" | bc -l | awk '{print int($1+0.5)}'`" 
	done

	if [ "$currentct" -le "$itemct" ]; then
   		if [ "$1" != "-i" ]; then
			currentct=$(expr $currentct + 1)
		fi
	fi

}

echo "You are about to install $pkgct packages, do you want to contuine? (y/n)"
read uinput

if [ $uinput = "y" ]; then
		
	echo "Installing..."
	clear
else
	break
fi

	progbar "-i" "$pkgct"
linect=1	
while IFS= read -r line
do
	progbar	
	nltobt=''
	
	while [ "`echo "$nltobt" | wc -l`" -lt "$(expr $h - "`echo $output | wc -l`" )" ]; do

		if [ -n "$nltobt" ]; then 
			printf -v nltobt "%s\n" "$nltobt"
		else
			printf -v nltobt "\n"
		fi
	done

	clear
	
 	printf "\e[0;49m\r%s\n(%d out of %d) Packages have been installed %s \e[0;49m%s %s" "$progout" "$linect" "$pkgct" "$output" "$nltobt" "$mbb"
      	
	
	apt-get -f install "$line" -qq >> /dev/null
	if [ $? -eq 0 ]; then
		printf -v output "${output}\n\e[0mInstalled: ${line}"
	else 
		
		printf -v output "\e[0m${output}\n\e[31mError: ${line}"

		if [ -n "$fails" ]; then
			printf -v fails "${fails}\n${line}"
		else 
			printf -v fails "${line}"
		fi
	fi
	
	
	linect=$(expr $linect + 1)
	[ "$linect" -gt "$(expr $h - 4 )" ] && \
	      output=${output#"`echo "$output" | head -2`"}
		
done < "$input"


printf "\n"
apt-get autoremove -qq

if [ -n "$fails" ]; then
	printf "\e[0mThere was %d package(s) that failed to install \n
	The name(s) of the failed packages were written to fails.txt \n
	To retry, execute again with the -r modifier \n
	The failed packages were \n
	%s\n" "`echo "$fails" | wc -l`" "$fails"
	echo "$fails" > fails.txt
else 
	printf "\e[0m%d Pacakages installed sucessfully \n" "$pkgct"
fi

