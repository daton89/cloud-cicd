# cloud-cicd
Setup environment for cloud based containerized application with continuous integration and delivery

## Install Jenkins 
```sh
docker run -d -u root --name jenkins \
    -p 8080:8080 -p 50000:50000 \
    -v /root/jenkins:/var/jenkins_home \
    jenkins:alpine  
```
The environment has a Jenkins server running as a Docker Container.
All plugins and configurations get persisted to the host at /root/jenkins. Port 8080 opens the web dashboard, 50000 is used to communicate with other Jenkins agents. Finally, the image has an alpine base to reduce the size footprint.

## Configure Docker Plugin
The next step is to configure the [Docker plugin](https://wiki.jenkins-ci.org/display/JENKINS/Docker+Plugin). The plugin is based on a Jenkins Cloud plugin. When a build requires Docker, it will create a "Cloud Agent" via the plugin. The agent will be a Docker Container configured to talk to our Docker Daemon.

The Jenkins build job will use this container to execute the build and create the image before being stopped. The Docker Image will be stored on the configured Docker Daemon. The Image can then be pushed to a Docker Registry ready for deployment.

### Task: Install Plugin
- Within the Dashboard, select **Manage Jenkins** on the left.
- On the Configuration page, select **Manage Plugins**.
- Manage Plugins page will give you a tabbed interface. Click **Available** to view all the Jenkins plugins that can be installed.
- Using the search box, search for **Docker plugin**. There are multiple Docker plugins, select **Docker plugin** using the checkbox.
- While on this page, install the **Git plugin** for obtaining the source code from a Git repository.
- Click **Install without Restart** at the bottom.
- The plugins will now be downloaded and installed. Once complete, click the link **Go back to the top page**.
Your Jenkins server can now be configured to build Docker Images.

## Add Docker Agent
Once the plugins have been installed, you can configure how they launch the Docker Containers. The configuration will tell the plugin which Docker Image to use for the agent and which Docker daemon to run the containers and builds on.

The plugin treats Docker as a cloud provider, spinning up containers as and when the build requires them.
### Task: Configure Plugin
This step configures the plugin to communicate with a Docker host/daemon.
- Once again, select **Manage Jenkins**.
- Select **Configure System** to access the main Jenkins settings.
- At the bottom, there is a dropdown called **Add a new cloud**. Select **Docker** from the list.
- You can now configure the container options. Set the name of the agent to **docker-agent**.
- The "Docker URL" is where Jenkins launches the agent container. In this case, we'll use the same daemon as running Jenkins, but you could split the two for scaling. Enter the URL tcp://172.17.0.61:2345
- Use **Test Connection** to verify Jenkins can talk to the Docker Daemon. You should see the Docker version number returned.

### Task: Configure Image
Our plugin can now communicate with Docker. In this step, we'll configure how to launch the Docker Image for the agent.
- Using the Images dropdown, select **Add Docker Template** dropdown.
- For the Docker Image, use [**benhall/dind-jenkins-agent**](https://hub.docker.com/r/benhall/dind-jenkins-agent/). This image is configured with a Docker client.
- To enable builds to specify Docker as a build agent, set a label of **docker-agent**.
- Jenkins uses SSH to communicate with agents. Add a new set of "Credentials". The username is **jenkins** and the password is **jenkins**.
- Finally, expand the Container Settings section by clicking the button. In the "Volumes" text box enter **/var/run/docker.sock:/var/run/docker.sock**
- Click Save.
Jenkins can now start a Build Agent as a container when required.

## Create Build Project
This step creates a new project which Jenkins will build via our new agent. The project source code is at https://github.com/katacoda/katacoda-jenkins-demo. The repository has a Dockerfile; this defines the instructions on how to produce the Docker Image. Jenkins doesn't need to know the details of how our project is built.

### Task: Create New Job
- On the Jenkins dashboard, select **Create new jobs**
- Give the job a friendly name such as **Build Docker Jenkins Demo** and select **Freestyle project**.
- The build will depend on having access to Docker. Using the "Restrict where this project can be run" we can define the label we set of our configured Docker agent. The set "Label Expression" to **docker-agent**. You should have a configuration of "Label is serviced by no nodes and 1 cloud".
- Select the Repository type as **Git** and set the Repository. If Git is not in the "Source Code Management" list, you need to install the Git plugin as mentioned in step 2.
- We can now add a new Build Step using the dropdown. Select **Execute Shell**.
- Because the logical of how to build is specified in our Dockerfile, Jenkins only needs to call build and specify a friendly name.
In this example, use the following commands.
```sh
ls
docker info
docker build -t katacoda/jenkins-demo:${BUILD_NUMBER} .
docker tag katacoda/jenkins-demo:${BUILD_NUMBER} katacoda/jenkins-demo:latest
docker images
```
The first stage lists all the files in the directory which will be built. When calling docker build we use the Jenkins build number as the image tag. This allows us to version our Docker Images. We also tag the build with latest.

At this point, or in an additional step, you could execute a docker push to upload the image to a centralised Docker Registry.

- Our build is now complete. Click **Save**.

## Build Project
We now have a configured job that will build Docker Images based on our Git repository. The next stage is to test and try it.
### Task: Build
On the left-hand side, select Build Now. You should see a build scheduled with a message "(pending—Waiting for next available executor)".

In the background, Jenkins is launching the container and connecting to it via SSH. Sometimes this can take a moment or two.

You can see the progress using `docker logs --tail=10 jenkins`

As it's a container, you can view it using the Docker CLI tools `docker ps -a`

It's normal for this to take a few moments to complete.

## View Console Output
Once the build has completed you should see the Image and Tags using the Docker CLI `docker images`.

What was built into the Docker Image was a small HTTP server. You can launch it using: `docker run -d -p 80:80 katacoda/jenkins-demo:latest`

Using cURL you should see the server respond: `curl docker`

Jenkins will have the console output of our build, available via the dashboard.

If you rebuilt the project, you would see a version 2 image created and the :latest tag reattached.
