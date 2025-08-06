# المرحلة الأولى: مرحلة البناء (Builder Stage)
# استخدام صورة Python الرسمية المحسّنة
FROM python:3.11-slim as builder

# تحديد مجلد العمل داخل الصورة
WORKDIR /app

# تحديث قائمة الحزم وتثبيت التبعيات المطلوبة للبناء
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# نسخ ملف متطلبات Python أولاً للاستفادة من Docker layer caching
COPY requirements.txt .

# إنشاء بيئة افتراضية وتثبيت التبعيات
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# المرحلة الثانية: مرحلة التشغيل (Production Stage)
FROM python:3.11-slim

# تحديد مجلد العمل
WORKDIR /app

# تثبيت التبعيات الأساسية المطلوبة للتشغيل فقط
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# نسخ البيئة الافتراضية من مرحلة البناء
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# نسخ ملفات المشروع
COPY app.py .
COPY cache.py .
COPY requirements.txt .
COPY static/ ./static/

# إنشاء مستخدم غير root للأمان
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --create-home --shell /bin/bash appuser

# تغيير ملكية الملفات للمستخدم الجديد
RUN chown -R appuser:appgroup /app

# التبديل إلى المستخدم غير root
USER appuser

# تحديد المنفذ الذي يستمع عليه التطبيق
EXPOSE 5000

# إضافة فحص صحة التطبيق (Health Check)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# تحديد متغيرات البيئة للإنتاج
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# نقطة البداية لتشغيل التطبيق
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0", "--port=5000"]

# تسميات للتوثيق
LABEL maintainer="Vanna.AI Team"
LABEL version="1.0.0"
LABEL description="Optimized Docker image for Vanna Flask application - AI-powered database chat interface"
LABEL org.opencontainers.image.source="https://github.com/vanna-ai/vanna-flask"
LABEL org.opencontainers.image.title="Vanna Flask App"
LABEL org.opencontainers.image.description="Web server for chatting with your database using Vanna.AI"