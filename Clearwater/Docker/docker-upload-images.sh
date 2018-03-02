#/bin/bash

read -sp 'Enter you sudo password: ' sudo_password # or may be use sudo chmod +s docker-upload-images.sh

echo -e "\n"
read -p 'Enter Docker Hub username: ' username
read -sp 'Enter Docker Hub Password: ' password
echo -e "\n"
read -p 'Any prefix (to avoid naming collision): ' prefix

export DOCKER_ID_USER=$username

###############################################

echo  "$sudo_password" | sudo  -S  docker build -t clearwater/base clearwater-docker/base

echo  "$sudo_password" | sudo  -S docker login -u $DOCKER_ID_USER -p $password

images='ellis astaire bono sprout chronos cassandra homer homestead homestead-prov ralf sip-stress' 

for image in $images; 
do 
	echo  "$sudo_password" | sudo  -S docker build -t clearwater/$image clearwater-docker/$image
	echo "Tagging $image as $DOCKER_ID_USER/$image"
	echo "$sudo_password" | sudo  -S docker tag clearwater/$image $DOCKER_ID_USER/$prefix$image
	echo "Uploading $image to $DOCKER_ID_USER/$image"
	echo "$sudo_password" | sudo  -S  docker push $DOCKER_ID_USER/$prefix$image
done
exit 0
