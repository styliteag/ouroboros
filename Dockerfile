FROM python:3.14.5-alpine

ARG VERSION=custom
ARG VCS_REF=unknown
LABEL org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.title="ouroboros" \
      org.opencontainers.image.description="Automatically update running docker containers" \
      org.opencontainers.image.source="https://github.com/styliteag/ouroboros"

ENV TZ=UTC

WORKDIR /app

COPY /setup.py /ouroboros /README.md /app/

COPY /requirements.txt /app/

RUN apk update && apk upgrade \
    && apk add --no-cache --virtual .build-deps gcc build-base linux-headers \
    ca-certificates musl-dev python3-dev libffi-dev openssl-dev cargo \
    && pip install --upgrade pip \
    && pip install --upgrade setuptools \
    && pip install --no-cache-dir -r requirements.txt \
    && apk del .build-deps

COPY /locales /app/locales

COPY /pyouroboros /app/pyouroboros

RUN pip install --no-cache-dir .

RUN mkdir /app/pyouroboros/hooks

VOLUME /app/pyouroboros/hooks

ENTRYPOINT ["ouroboros"]
