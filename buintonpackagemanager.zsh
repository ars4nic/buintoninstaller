#!/bin/zsh
SCRIPTPATH=$(dirname "$SCRIPT")

retry=0
force=0
quiet=0

while [ $# -gt 0 ]; do
	case $1 in
		-d|--debug)
			inst=$(dpkg -l | grep 'zsh')

			if [ "$EUID" -ne 0 ]; then
				echo "You are not SUDO, run as SUDO"
			elif [ -x $inst ]; then
				echo "ZSH is not installed, would you like me to intall if for you (y/n)"
				read uinput
				if [ "$uinput" = "y" ]; then
					apt-get install zsh
				fi
			else
				echo "Dude I have I idea whats wrong, if you believe there is a bug see my repo with -a"
				fi

				return
				;;
			-a|--about)
				echo "Devloped by buinton"
				echo "Checkout my repo"
				echo "https://github.com/buinton/buintoninstaller"
				return
				;;
			-h|--help)
				printf "
				-d(--debug) | Helps you debug common errors\n
				-a(--about) | About this program\n
				-h(--help)  | ...\n
				-r(--retry) | If a package failed to install on the first use of the program a fails.txt file will be generated using this flag will run this program again with that file\n
				-F(--force) | Won't ask for user input while running \n
				-q(--quiet) | Will print less text to console also invokes -f, force. \n
				-f(--file)  | specifies an alternate path within the the installers location #experimental \n"
				return
				;;
			-r|--retry)
				retry=1
				shift
				;;
			-F|--force)
				force=1
				shift
				;;
			-q|--quiet)
				force=1
				quiet=1
				shift
				;;
			-f|--file)
				shift
				ufile=$1
				shift
				;;
			*)
				break
				;;
		esac
	done




	if [ $retry -eq 1 ]; then
		input="$SCRIPTPATH/fails.txt"

	else
		if [ $ufile != "" ]; then
			input="$SCRIPTPATH/$ufile"
		else
			input="$SCRIPTPATH/aptinstall.txt"
		fi
	fi


	

	
while IFS= read -r line
do
	
	if [ -n "${line// }" ] && [ ${line//--} = $line ]; then
		pkgct=$(expr $pkgct + 1)
	fi

done  < "$input"


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
			itemct=$2
			printf -v progout "\r[%-${progbarl}s](%2d%%)" "" ""
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
if [ "$force" -eq 0 ]; then
	echo "You are about to install $pkgct packages, do you want to contuine? (y/n)"
	read uinput

	if [ $uinput = "y" ]; then

		echo "Installing..."
		clear
	else
		break
	fi
fi

progbar "-i" "$pkgct"
linect=0
while IFS= read -r line
do
	
	if [ -n "${line// }" ] && [ ${line//--} = $line ]; then



		progbar
		nltobt='' #Number of lines to botton of the terminal

		while [ "`echo "$nltobt" | wc -l`" -lt "$(expr $h - "`echo $output | wc -l`" )" ]; do
			#While the number of lines in nltobt is less than the height of the window minus the number of lines of the installed commands

			if [ -n "$nltobt" ]; then #if nltobt is non empty then a newline plus the existing string
				printf -v nltobt "%s\n" "$nltobt"
			else
				printf -v nltobt "\n"
			fi
		done


		clear
		if [ "$quite" -eq 0 ]; then
			printf "\e[0;49m\r%s\n(%d out of %d) Packages have been installed %s \e[0;49m%s %s" "$progout" "$linect" "$pkgct" "$output" "$nltobt" "$mbb"
		fi

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
	fi
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

