# Django + PaddleOCR API image (CPU).
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DISABLE_MODEL_SOURCE_CHECK=True \
    PADDLE_PDX_CACHE_HOME=/models

# Shared libraries needed by OpenCV and Paddle.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libgomp1 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1000 app
WORKDIR /app

COPY requirements.txt requirements-prod.txt ./
RUN pip install -r requirements-prod.txt

COPY . .
RUN mkdir -p /app/storage /models && chown -R app:app /app /models
USER app

# Download the OCR models into the image so containers start offline.
RUN DJANGO_SECRET_KEY=build-only DJANGO_DEBUG=false python manage.py download_models

EXPOSE 8000
CMD ["sh", "-c", "python manage.py migrate --noinput && gunicorn -c deploy/gunicorn.conf.py --bind 0.0.0.0:8000 config.wsgi:application"]
