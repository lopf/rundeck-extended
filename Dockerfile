FROM rundeck/rundeck:5.15.0

ENV RDECK_BASE=/home/rundeck
ENV MANPATH=${MANPATH}:${RDECK_BASE}/docs/man
ENV PATH=${PATH}:${RDECK_BASE}/tools/bin

COPY --chown=rundeck:rundeck requirements.txt ${RDECK_BASE}/

# install pip packages
# base image already installed: curl, openjdk-8-jdk-headless, ssh-client, sudo, uuid-runtime, wget
# (see https://github.com/rundeck/rundeck/blob/master/docker/ubuntu-base/Dockerfile)
RUN sudo apt-get -y update \
  && sudo apt-get -y --no-install-recommends install ca-certificates python3-pip sshpass \
  && sudo -H pip3 --no-cache-dir install --upgrade pip setuptools \
  # https://pypi.org/project/ansible/#history
  && sudo -H pip3 --no-cache-dir install -r requirements.txt \
  && sudo rm -rf /var/lib/apt/lists/*

# as rundeck user
RUN mkdir /home/rundeck/ansible \
  && echo "localhost" > /home/rundeck/ansible/hosts

# install powershell
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb \
  && sudo dpkg -i packages-microsoft-prod.deb \
  && sudo apt-get update \
  && sudo apt-get install -y powershell \
  && pwsh -c 'Install-Module -Name VMware.PowerCLI -Force'

# install additional packages
RUN sudo apt-get update \
  && sudo apt-get install -y jq

# see https://github.com/rundeck/docker-zoo/tree/master/config
COPY --chown=rundeck:root remco /etc/remco

# set
#RUN echo "rundeck.feature.option-values-plugin.enabled=true" >> ${RDECK_BASE}/server/config/rundeck-config.properties

# add default project
#COPY --chown=rundeck:rundeck docker/project.properties ${PROJECT_BASE}/etc/

# add locally built ansible plugin
#COPY --chown=rundeck:rundeck build/libs/ansible-plugin-*.jar ${RDECK_BASE}/libext/
COPY --chown=rundeck:rundeck ./plugins/*.zip ${RDECK_BASE}/libext/
COPY --chown=rundeck:rundeck ./plugins/*.jar ${RDECK_BASE}/libext/

# patch jira.py, open issue https://github.com/ansible-collections/community.general/issues/10786
COPY --chown=rundeck:rundeck patches/jira.py /usr/local/lib/python3.10/dist-packages/ansible_collections/community/general/plugins/modules/web_infrastructure/jira.py
