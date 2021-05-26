FROM centos
COPY waitForExGw.py /root/
RUN yum -y install python3 python3-pip
RUN pip3 install requests

