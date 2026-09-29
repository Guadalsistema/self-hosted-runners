FROM docker.io/library/odoo:18

###############################################################################
# 1. Paquetes básicos + PGDG + PostgreSQL 16 (solo binarios, sin servicio)
###############################################################################
USER root
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl fonts-liberation git gnupg jq lsb-release procps sudo unzip \
        libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64 libatspi2.0-0t64 \
        libcups2t64 libdbus-1-3 libdrm2 libgbm1 libgtk-3-0t64 \
        libnspr4 libnss3 libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 && \
    \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
        gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
        http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | \
        tee /etc/apt/sources.list.d/pgdg.list > /dev/null && \
    \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-17 postgresql-client-17 && \
    arch="$(dpkg --print-architecture)" && \
    case "$arch" in amd64) chrome_platform=linux64 ;; arm64) chrome_platform=linux-arm64 ;; *) exit 1 ;; esac && \
    curl --fail --location --silent --show-error \
        "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/${chrome_platform}/chrome-${chrome_platform}.zip" \
        --output /tmp/chromium.zip && \
    unzip -q /tmp/chromium.zip -d /opt && \
    ln -s "/opt/chrome-${chrome_platform}/chrome" /usr/local/bin/chromium && \
    rm /tmp/chromium.zip && \
    rm -rf /var/lib/apt/lists/*

RUN python3  -m pip install --break-system-packages ipdb 'ipython<9' setuptools websocket-client \
	git+https://github.com/OCA/openupgradelib.git@master#egg=openupgradelib ipdb

###############################################################################
# 2. Usuario y carpetas del runner
###############################################################################
RUN groupadd -r runner && \
    useradd --no-log-init -r -g runner runner

WORKDIR /home/runner/actions-runner
RUN chown -R runner:runner /home/runner

###############################################################################
# 3. Entrypoint del runner
###############################################################################
COPY entrypoint.sh /home/runner/actions-runner/entrypoint.sh
RUN chmod +x /home/runner/actions-runner/entrypoint.sh

###############################################################################
# 4. Carpeta para add-ons externos
###############################################################################
RUN mkdir -p /mnt/extra-addons && \
    chown -R runner:runner /mnt/extra-addons

###############################################################################
# 5. Usuario de ejecución
###############################################################################
USER runner

RUN pip install --break-system-packages --no-cache-dir 'pypdf'

WORKDIR /home/runner/actions-runner
ENTRYPOINT ["/home/runner/actions-runner/entrypoint.sh"]
