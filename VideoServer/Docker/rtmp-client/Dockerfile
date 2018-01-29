# hub.docker.com/r/antongulenko/rtmp-client
FROM jrottenberg/ffmpeg
COPY run.sh /run.sh
ENTRYPOINT ["/run.sh"]

# Define as <= 0 for infinite loop
ENV LOOP="1"

ENV MRL=""
# The below variables are evaluated if MRL is not set
ENV MRL_SERVER=""
ENV MRL_PORT="1935"
ENV MRL_PATH="/vod/example.flv"
ENV MRL_PROTO="rtmp"
