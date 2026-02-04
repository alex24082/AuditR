# AuditR - Dockerfile
FROM debian:bullseye-slim

# Instaleaza dependentele
RUN apt-get update && apt-get install -y \
    bash procps iproute2 findutils coreutils \
    && rm -rf /var/lib/apt/lists/*

# Copie scriptul
WORKDIR /app
COPY auditr.sh .
COPY asciiart .
RUN chmod +x auditr.sh

# Creeaza folder output
RUN mkdir -p output

ENTRYPOINT ["./auditr.sh"]
CMD ["-h"]
