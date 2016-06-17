FROM centos:centos7
MAINTAINER Benjamin Krein <superbenk@gmail.com>
RUN yum update -y -q
RUN yum install -y -q epel-release
RUN yum install -y -q openssh-server sudo which ansible libselinux-python sshpass
RUN curl -o /tmp/install.sh https://www.getchef.com/chef/install.sh
RUN /bin/sh /tmp/install.sh
RUN /opt/chef/embedded/bin/gem install --no-rdoc --no-ri sfl net-telnet net-ssh net-scp specinfra rspec-support rspec-expectations rspec-core rspec-its rspec-mocks rspec multi_json serverspec

