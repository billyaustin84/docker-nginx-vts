ARG NGINX_VERSION="1.27.3"
ARG NGINX_VTS_VERSION="0.2.2"
ARG DEBIAN_CODENAME="bookworm"

FROM nginx:${NGINX_VERSION} AS build

ARG NGINX_VERSION
ARG NGINX_VTS_VERSION
ARG DEBIAN_CODENAME

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
  && cd /opt/rebuildnginx


FROM nginx:${NGINX_VERSION} AS final

ARG NGINX_VERSION
ARG NGINX_VTS_VERSION
ARG DEBIAN_CODENAME

COPY --from=build /opt/rebuildnginx/nginx_${NGINX_VERSION}-*~${DEBIAN_CODENAME}_amd64.deb /tmp/nginx_${NGINX_VERSION}-${DEBIAN_CODENAME}_amd64.deb
RUN dpkg --install /tmp/nginx_${NGINX_VERSION}-${DEBIAN_CODENAME}_amd64.deb && rm /tmp/nginx_${NGINX_VERSION}-${DEBIAN_CODENAME}_amd64.deb

CMD ["nginx", "-g", "daemon off;"]
