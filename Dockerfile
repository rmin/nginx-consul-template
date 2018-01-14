FROM nginx:1.13

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    apt-get -y install wget runit unzip && \
    rm -rf /var/lib/apt/lists/*

# Install latest Consul-Template from https://releases.hashicorp.com/consul-template
RUN wget https://releases.hashicorp.com/consul-template/0.19.4/consul-template_0.19.4_linux_amd64.zip \
	&& unzip -d /usr/local/bin consul-template_0.19.4_linux_amd64.zip \
	&& rm -f consul-template_0.19.4_linux_amd64.zip

ADD nginx.service /etc/service/nginx/run
ADD consul-template.service /etc/service/consul-template/run

RUN mkdir /etc/consul-template \
    && chmod +x /etc/service/nginx/run \
    && chmod +x /etc/service/consul-template/run \
    && rm -f /etc/nginx/conf.d/*

ADD nginx.conf /etc/nginx/nginx.conf
ADD consul-template.hcl /etc/consul-template/consul-template.hcl
ADD template.ctmpl /etc/consul-template/template.ctmpl

EXPOSE 80
CMD ["/usr/bin/runsvdir", "/etc/service"]