## log processor service

# Stage 1: Dependencies installation
FROM python:3.9-slim AS dependencies

WORKDIR /app
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt


# Stage 2: Production runtime
FROM python:3.9-slim AS production

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -r logprocessor && \
    useradd -r -g logprocessor logprocessor

WORKDIR /app
RUN mkdir -p /var/log/chattingo && \
    chown -R logprocessor:logprocessor /var/log/chattingo /app

COPY --from=dependencies /app/wheels /wheels
COPY requirements.txt .
RUN pip install --no-cache-dir --no-index --find-links /wheels -r requirements.txt && \
    rm -rf /wheels

COPY --chown=logprocessor:logprocessor log_processor.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

USER logprocessor

HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import os; exit(0 if os.path.exists('/var/log/chattingo') else 1)"

ENTRYPOINT ["./entrypoint.sh"]
