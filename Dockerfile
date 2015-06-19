FROM ubuntu:14.04

MAINTAINER Anton Belov <anton4@bk.ru>

RUN echo "deb http://repo.percona.com/apt trusty main" > /etc/apt/sources.list.d/percona.list && \
    echo "deb-src http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list.d/percona.list && \
    apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A && \
    apt-get update && \
    apt-get -y install percona-xtradb-cluster-56 pwgen supervisor nano mc openssh-server sshpass xinetd && \
    apt-get clean && \
	rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /download/directory

# download latest stable etcdctl
ADD https://s3-us-west-2.amazonaws.com/opdemand/etcdctl-v0.4.5 /usr/local/bin/etcdctl
RUN chmod +x /usr/local/bin/etcdctl

RUN mkdir -p /var/log/supervisor /var/run/sshd && \
 perl -p -i -e "s/#?PasswordAuthentication .*/PasswordAuthentication yes/g" /etc/ssh/sshd_config && \
 perl -p -i -e "s/#?PermitRootLogin .*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
 grep ClientAliveInterval /etc/ssh/sshd_config >/dev/null 2>&1 || echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config

ENV PXC_NODES **ChangeMe**
ENV PXC_BOOTSTRAP **ChangeMe**
ENV PXC_SST_PASSWORD **ChangeMe**
ENV PXC_ROOT_PASSWORD **ChangeMe**
ENV CREATE_DATABASES **ChangeMe**

ENV PXC_VOLUME /var/lib/mysql
ENV PXC_CONF /etc/mysql/conf.d/pxc.cnf
ENV PXC_CONF_FLAG /etc/pxc.configured
ENV SSH_OPTS -p 22 -o ConnectTimeout=4 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

VOLUME ["${PXC_VOLUME}"]

ADD ./bin /usr/local/bin

RUN mkdir -p /usr/local/bin && \
    echo "mysqlchk 9200/tcp #mysqlchk" >> /etc/services && \
    chmod +x /usr/local/bin/*.sh

ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD ./etc/supervisord_bootstrap.conf /etc/supervisor/conf.d/supervisord_bootstrap.conf
ADD ./etc/mysql/conf.d/pxc.cnf /etc/mysql/conf.d/pxc.cnf

CMD ["/usr/local/bin/run.sh"]
