FROM nginx:1.25.5

ENV NGINX_VERSION     "1.25.5"
ENV NGINX_VTS_VERSION "0.2.2"
ENV DEBIAN_CODENAME   "bookworm"

RUN apt-get update && apt-get install -y gnupg2 && curl http://nginx.org/packages/keys/nginx_signing.key | apt-key add -

RUN echo "deb-src http://nginx.org/packages/mainline/debian/ ${DEBIAN_CODENAME} nginx" >> /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y dpkg-dev curl \
  && mkdir -p /opt/rebuildnginx \
  && chmod 0777 /opt/rebuildnginx \
  && cd /opt/rebuildnginx \
  && su --preserve-environment -s /bin/bash -c "apt-get source nginx=${NGINX_VERSION}" _apt \
  && apt-get build-dep -y nginx=${NGINX_VERSION}

RUN cd /opt \
  && curl -sL https://github.com/vozlt/nginx-module-vts/archive/v${NGINX_VTS_VERSION}.tar.gz | tar -xz \
  && ls -al /opt/rebuildnginx \
  && ls -al /opt \
  && sed -i -r -e "s/\.\/configure(.*)/.\/configure\1 --add-module=\/opt\/nginx-module-vts-${NGINX_VTS_VERSION}/" /opt/rebuildnginx/nginx-${NGINX_VERSION}/debian/rules \
  && cd /opt/rebuildnginx/nginx-${NGINX_VERSION} \
  && dpkg-buildpackage -b \
  && cd /opt/rebuildnginx \
  && dpkg --install nginx_${NGINX_VERSION}-1~${DEBIAN_CODENAME}_amd64.deb \
  && apt-get remove --purge -y dpkg-dev curl && apt-get -y --purge autoremove && rm -rf /var/lib/apt/lists/*

CMD ["nginx", "-g", "daemon off;"]
