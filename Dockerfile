FROM ubuntu:14.04
MAINTAINER Nathaniel Ritholtz <nritholtz@gmail.com>

# Install required packages
RUN apt-get update -y && apt-get install -y \
              autoconf \
              bison \
              build-essential \
              curl \      
              git \
              supervisor \
              wget \ 
              libffi-dev \              
              libgdbm3 \
              libgdbm-dev \
              libncurses5-dev \
              libreadline6-dev \              
              libssl-dev \
              libyaml-dev \
              zlib1g-dev \              
        && rm -rf /var/lib/apt/lists/*

# Install Ruby
RUN git clone https://github.com/tagomoris/xbuild.git /.xbuild && \
    /.xbuild/ruby-install 2.2.2 /ruby && \
    rm -rf /.xbuild

# Install Fluentd
ENV PATH /ruby/bin:$PATH
RUN gem install fluentd -v 0.12.16 --no-rdoc --no-ri && \
  fluent-gem install fluent-plugin-cloudwatch-logs -v 0.1.2 

# Install docker-gen
RUN wget https://github.com/jwilder/docker-gen/releases/download/0.4.2/docker-gen-linux-amd64-0.4.2.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-0.4.2.tar.gz \
 && rm docker-gen-linux-amd64-0.4.2.tar.gz

# Copy fluentd config file
COPY fluent.conf /etc/fluent/

ADD . /

EXPOSE 24224

CMD ["/bin/bash", "./bootstrap.sh"]