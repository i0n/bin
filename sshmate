#!/bin/sh

host=`echo $SSH_CLIENT | cut -d' ' -f1`
path=`pwd | sed "s|^$HOME|/Volumes/chaos|"`
app="/Applications/TextMate.app"
file=$1

if [ ! -e $file ]; then
	echo -n "create $file? [Yn] "
	read input
	if [ -z "$input" -o "$input" = "Y" -o "$input" = "y" ]; then
		touch $file
	else
		exit
	fi
fi

ssh $host "open -a $app $path/$file; exit"