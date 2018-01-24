# Clearwater Docker 
This project will enable you deploy Clearwater project's components in a Docker swarm on an Openstack environment.

# Getting Started
### Prerequisites
- Running Openstack environment

### Installation and Deployment
-  Update number of VMs that need to be create for each component of clearwater project in ```parameters.txt``` file.
    (Note: There should be only one Ellis container in order to pass the live-test.)
    (Note: To understand about fault tolerance of docker swarm,  please see the following link: https://docs.docker.com/engine/swarm/admin_guide/#add-manager-nodes-for-fault-tolerance )

- Run ```./create.sh``` file and wait for the VMs to be created

- Run ```./swarm_init.sh``` file with passing stack name as an argument.

- Wait for the swarm to be created and all clearwater containers are deployed.

    ~~The following steps (strikedthrough) are not needed for the new images.~~
    ~~After all containers are runing, to perform the live test, we need to do some manual steps:~~~
    ~~login to ellis VM and exectue bash for ellis container,  and create numbers manually by executing the following:~~
    ~~go to ```/usr/share/clearwater/ellis```~~
    ~~run ```./create_numbers.sh```~~
    ~~this will create 1000 numnbers in mysql database running inside ellis container.~~

- Log in to bono VM and execute bash for ```live-test``` container by executing the following command: 
    ```sudo docker exec -ti <live-test container id> bash```

- Now run the following command to run the live test for the deployed clearwater component:
      ```rake test[example.com] PROXY=bono ELLIS=ellis SIGNUP_CODE=secret```


All tests should pass now. If tests are failing then do the following steps:
- login to astaire container and check whether astaire and rogers services are running by executing ```service --status-all```. 
- if they are not running then start both services by executing the following commands: ```service astaire start``` and ```service rogers start```.
- login to ellis container and check whether mysql is working. you can check it by executing ```mysql``` command or by checking whether mysql service is running.

#### To Update a Stack:

- To update a stack, update the parameteres in ```parameters.txt``` file and use ```./create.sh update <existing-stack-name>```. It will update the number of VMs.
- To enable the newly created VM(s) in a stack to join the swarm, run the ```swarm_init``` script again. 
It will add the VMs to a swarm cluster.

Once VMs are created and joined the swarm, it will automatically deploy clearwater components on respective machines (because the mode is set to ```global``` in ```docker-compose``` file).
