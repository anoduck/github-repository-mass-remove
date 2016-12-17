#!/bin/sh
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`
COUNT=1;
linkPermission='https://github.com/settings/tokens/new?scopes=delete_repo&description=Mass+remove+repository'

countSuccessfully=0;
countFailed=0;

echo "${yellow}Head to ${reset}${linkPermission} ${yellow}to retrieve a token.${reset}"
echo "${green}Please enter your GitHub token from removed repositories:${reset}"

promptAccessToken() {
	read -p "${yellow}Access Token${reset}: " access_token
}

promptAccessToken

while true; do
	if [[ $(curl -H "Authorization: token $access_token" -s "https://api.github.com/user" -I | grep -i "HTTP/1.1 200 OK") != "" ]]
		then
			printf "\n"
			echo "${green}Wow. Great token. I begin to remove the repository:${reset}";
			break
		else
			echo "${red}Bad access_token. Try again.${reset}"
			promptAccessToken
	fi
done

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
done < repositories.txt

echo "${yellow}Script has completed execution.${reset}"
printf "$green - Successfully removed:$reset $countSuccessfully"
printf "$red\n - Failed removed:$reset $countFailed"
