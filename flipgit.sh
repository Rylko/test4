#!/bin/sh

source conf.sh

echo

status_code=1
rof=$((status_code/100))
while [ $rof -ne 2 ]
do

echo
#echo "Enter your GitHub login: "
read -p "Enter your GitHub login: " gh_user
echo -n "Password: "
read -s password
echo
read -p "Enter name for new repository: " reponame

response=$(curl -u $gh_user:$password \
--write-out \\n%{http_code} \
--silent \
https://api.github.com/user/repos \
-d "{\"name\":\"$reponame\"}")

status_code=$(echo "$response" | sed -n '$p')
html=$(echo "$response" | sed '$d')
echo status_code=$status_code
rof=$((status_code/100))

done

echo "git@github.com:$gh_user/$reponame.git"
