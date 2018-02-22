# hub.docker.com/r/antongulenko/rtmp-nginx-server
FROM tiangolo/nginx-rtmp
WORKDIR /opt/rtmp/http
RUN curl -sL https://raw.githubusercontent.com/arut/nginx-rtmp-module/master/stat.xsl > stat.xsl
EXPOSE 8080

# Download some example videos for streaming
WORKDIR /opt/rtmp/vod
RUN curl -sL http://www.sample-videos.com/video/flv/720/big_buck_bunny_720p_1mb.flv > example-6s.flv
RUN curl -sL http://www.sample-videos.com/video/flv/480/big_buck_bunny_480p_1mb.flv > example-7s.flv
RUN curl -sL http://www.sample-videos.com/video/flv/240/big_buck_bunny_240p_1mb.flv > example-11s.flv
RUN curl -sL http://www.sample-videos.com/video/flv/720/big_buck_bunny_720p_50mb.flv > example-big.flv
RUN mkdir -p /opt/rtmp/vod_mirror && chmod 777 /opt/rtmp/vod_mirror

COPY nginx.conf /etc/nginx/nginx.conf
ENTRYPOINT ["nginx", "-g", "daemon off;"]

# cvlc rtmp://172.17.0.1:1935/vod/example.flv -V dummy -A dummy

# ffplay rtmp://172.17.0.1:1935/vod/example.flv -autoexit -nodisp

# ffmpeg -i rtmp://172.17.0.1:1935/vod/example.flv -f null /dev/null

# docker run -ti --entrypoint bash jrottenberg/ffmpeg

# docker run -ti jrottenberg/ffmpeg -i rtmp://172.17.0.1:1935/vod/example.flv -f null /dev/null
