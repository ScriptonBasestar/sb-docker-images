FROM jenkins/jenkins:lts-jdk21
COPY --chown=jenkins:jenkins conf/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
