#!/bin/bash

initialSync="initialSync.config"
exec `dos2unix DirsToBackup.config` #convert Windows EOL to Unix
dirs="DirsToBackup.config"
tempFolder="/tmp"
accountId=$(cat apikey.config | cut -f1 -d :)
apiKey=$(cat apikey.config | cut -f2 -d :)

echo "Account ID: $accountId"
echo `b2 authorize-account $accountId $apiKey`
echo "Checking config files"

#check initialSync file exists
echo "Checking sync file"
if [ -f "$initialSync" ]; then 
	initialSync=$(<$initialSync)
	if [ -z $initialSync ]; then #check if the file is empty or null
		echo "Empty Sync file"
	else
		echo "Sync File Read"
	fi
else 
	echo "No sync file"
fi #initialSync check end

#check dirs file exists
echo "Checking dirs file"
if [ -f "$dirs" ]; then
	dirs=$(<$dirs)
	echo "Dirs loaded"
else
	echo "No directory list - touching to create file"
	touch $dirs
fi 

if [ $initialSync = 1 ]; then
	echo "Initial Sync running..."
	#simplistic encryption of the full path and name to obfuscate the backup names
	for i in ${dirs[@]}
	do
		files=(`find $i -type f`)
		#echo ${#dirs[@]}
		#echo ${#files[@]}
		#echo ${files[*]}
		for j in ${files[@]}
		do
			fullpath=(`realpath $j`)
			filename=(`echo $fullpath | openssl enc -e -base64 -aes-256-cbc -pass file:id_rsa.pub.key -nosalt | tr -d "/"`) #access array item ${files[0]}
			echo `realpath $j`
			#echo $filename
			#echo -en "\n"
			checksum=(`sha1sum ${fullpath}`); #create a file checksum
			echo "checksum $checksum"
			filename="$filename-$checksum.enc"
			openssl enc -e -in $fullpath -out "/tmp/$filename" -aes-256-cbc -pass file:id_rsa.key -nosalt
			
			b2 upload-file --sha1 $checksum --threads 4 mybuckets "c:\cygwin64\tmp\\$filename" $filename
			
			
		done
	done
else
	echo "Starting find files changed..."
	for i in $dirs
	do
		changed=$(find $i -cmin -3600 -type f)
		echo $changed 
	done
fi



