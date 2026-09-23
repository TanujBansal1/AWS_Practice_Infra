# --- builder stage: install dependencies into a venv ---
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m venv /venv \
    && /venv/bin/pip install --no-cache-dir --upgrade pip \
    && /venv/bin/pip install --no-cache-dir -r requirements.txt

# --- final stage: copy only the venv + app code, run as non-root ---
FROM python:3.12-slim

RUN useradd --create-home --shell /usr/sbin/nologin appuser
WORKDIR /app

COPY --from=builder /venv /venv
COPY main.py .

USER appuser
ENV PATH="/venv/bin:$PATH"
EXPOSE 8000

# Uses python (already in the base image) instead of curl, so no extra
# package install is needed just for the healthcheck.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=2)" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
