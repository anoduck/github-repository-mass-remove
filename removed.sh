#!/bin/sh
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`
COUNT=1;
linkPermission='https://github.com/settings/tokens/new?scopes=delete_repo&description=Mass+remove+repository'
access_token=''
repositoriesFile='repositories.txt'
savedTokenFile='token.txt'

countSuccessfully=0;
countFailed=0;
numOfLinesRepositoryList=0

promptAccessToken() {
	read -p "${yellow}Access Token${reset}: " access_token
}

checkToken() {
	while true; do
		if [[ $(curl -H "Authorization: token $access_token" -s "https://api.github.com/user" -I | grep -i "HTTP/1.1 200 OK") != "" ]]
			then
				if [ ! -f $savedTokenFile ];
					then
					echo "${green}Wow. Token is correct. I write your token to ${reset}${yellow}'$savedTokenFile'${reset}"
					echo $access_token > $savedTokenFile
				else
					echo "${green}Token is correct.${reset}"
				fi

				echo "${green}I begin remove repository:${reset}";
				break
			else
				echo "${red}Bad access_token. Try again.${reset}"
				promptAccessToken
		fi
	done
}

printf "\n"
echo "---------------------"
echo "${yellow} Youre running script to remove all github repositories listed in the file :D${reset}"
echo "---------------------"
printf "\n"

if [ ! -f $repositoriesFile ]; 
	then
		echo "${red}You have not create file '${repositoriesFile}'.${reset}"
		exit
	else
	numOfLinesRepositoryList=$(wc -l < ${repositoriesFile})
fi

if [[ $numOfLinesRepositoryList == 0 ]]
	then
	echo "${yellow}File '${repositoriesFile}' the number of rows is equal to zero. Just sad :c ${reset}"
	exit
else
	if [ ! -f $savedTokenFile ]; 
		then
			echo "${yellow}Head to ${reset}${linkPermission} ${yellow}to retrieve a token.${reset}"
			echo "${green}Please enter your GitHub token from removed repositories:${reset}"
			printf "\n"
			promptAccessToken
			checkToken
		else
			while IFS= read -r token || [ -n "$token" ]; do
				access_token=$token
				checkToken
			done < $savedTokenFile
	fi
fi

while IFS= read -r repo || [ -n "$repo" ]; do
	if [[ $(curl -X DELETE -H "Authorization: token $access_token" -s "https://api.github.com/repos/$repo" -I | grep -i "HTTP/1.1 404 Not Found") != "" ]]
		then
			printf " $COUNT) $yellow Repository: $reset[$repo]$red\n  * [404] Repository not found.$reset\n\n";
			countFailed=$(( $countFailed + 1 ))
	elif [[ $(curl -X DELETE -H "Authorization: token $access_token" -s "https://api.github.com/repos/$repo" -I | grep -i "HTTP/1.1 403 Forbidden") != "" ]]
		then
			printf " $COUNT) $yellow Repository: $reset[$repo]$red\n  * [403] You are not have permission.$reset\n\n";
			countFailed=$(( $countFailed + 1 ))
	else
			printf " $COUNT) $yellow Repository: $reset[$repo]$green\n  * [200] Successfully deleted.$reset\n\n";
			countSuccessfully=$(( $countSuccessfully + 1 ))
	fi

	COUNT=$(( $COUNT + 1 ))
	sed -i '1,1 d' ${repositoriesFile}
done < $repositoriesFile

echo "---------------------"
echo "${yellow} Script has completed execution.${reset}"
echo "---------------------"
echo " Statistics: "
printf "$green - Successfully removed:$reset $countSuccessfully"
printf "$red\n - Failed removed:$reset $countFailed\n"
echo "---------------------"
printf "\n"