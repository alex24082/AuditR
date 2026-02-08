
FROM debian:bullseye-slim


RUN apt-get update && apt-get install -y \
    bash procps iproute2 findutils coreutils \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /app
COPY auditr.sh .
COPY asciiart .
RUN chmod +x auditr.sh


RUN mkdir -p output

ENTRYPOINT ["./auditr.sh"]
CMD ["-h"]
