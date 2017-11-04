# cloud-cicd
Setup environment for cloud based containerized application with continuous integration and delivery

## Install Jenkins 
```sh
docker run -d -u root --name jenkins \
    -p 8080:8080 -p 50000:50000 \
    -v /root/jenkins:/var/jenkins_home \
    jenkins:1.651.1-alpine    
```
The environment has a Jenkins server running as a Docker Container.
All plugins and configurations get persisted to the host at /root/jenkins. Port 8080 opens the web dashboard, 50000 is used to communicate with other Jenkins agents. Finally, the image has an alpine base to reduce the size footprint.

