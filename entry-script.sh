 #!/bin/bash
 sudo apt update -y && sudo apt upgrade -y
 sudo apt install docker -y
 sudo usermod -aG docker ubuntu
 docker run -p 8080:80 nginx
