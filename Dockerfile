FROM nginx AS build

WORKDIR /src
RUN apt-get update && \
  apt-get install -y git gcc make g++ cmake perl libunwind-dev golang && \
  git clone https://github.com/quictls/openssl.git && \
  mkdir openssl/build && \
  cd openssl/build && \
  cd .. && \
  ./Configure && \
  make

# RUN \
#   echo "Cloning brotli main ..." \
#   && apt-get install -y gnutls-bin\
#   && git config --global http.sslVerify false \
#   && git config --global http.postBuffer 1048576000 \
#   && mkdir /usr/src/ngx_brotli \
#   && cd /usr/src/ngx_brotli \
#   && git init \
#   && git remote add origin https://github.com/google/ngx_brotli.git \
#   && git fetch --depth 1 origin master \
#   && git checkout --recurse-submodules -q FETCH_HEAD \
#   && git submodule update --init --depth 1

RUN apt-get install -y mercurial libperl-dev libpcre3-dev zlib1g-dev libxslt1-dev libgd-ocaml-dev libgeoip-dev && \
  hg clone https://hg.nginx.org/nginx-quic && \
  hg clone http://hg.nginx.org/njs && \
  cd nginx-quic && \
  hg update quic && \
  auto/configure `nginx -V 2>&1 | sed "s/ \-\-/ \\\ \n\t--/g" | grep "\-\-" | grep -ve opt= -e param= -e build=` \
  --build=nginx-quic \
  # --with-debug \
  --with-http_auth_request_module \
  --with-http_v3_module \
  --with-stream_quic_module \ 
  # --add-module=/usr/src/ngx_brotli \
  --with-openssl="/src/openssl" && \
  make


FROM nginx
COPY --from=build /src/nginx-quic/objs/nginx /usr/sbin
RUN /usr/sbin/nginx -V > /dev/stderr

# http3 need udp
EXPOSE 443/tcp
EXPOSE 443/udp
