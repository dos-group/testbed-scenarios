# hub.docker.com/r/antongulenko/rtmp-client
FROM jrottenberg/ffmpeg
COPY run.sh /run.sh
ENTRYPOINT ["/run.sh"]

# Define as <= 0 for infinite loop
ENV LOOP="1"

ENV MRL=""
# The below variables are evaluated if MRL is not set.
# Default values (except for MRL_SERVER) are assigned in run.sh.
ENV MRL_SERVER=""
ENV MRL_PORT=""
ENV MRL_PATH=""
ENV MRL_PROTO=""
