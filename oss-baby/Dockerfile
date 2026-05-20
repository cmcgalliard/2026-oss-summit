FROM nginx:alpine

COPY austin-powers.jpg /usr/share/nginx/html/austin-powers.jpg
COPY qrcode_demo2.oss.baby.png /usr/share/nginx/html/qrcode_demo2.oss.baby.png

RUN printf '%s\n' \
  '<!doctype html>' \
  '<html lang="en">' \
  '<head>' \
  '  <meta charset="utf-8">' \
  '  <meta name="viewport" content="width=device-width, initial-scale=1">' \
  '  <title>OSS Baby</title>' \
  '  <style>' \
  '    :root { color-scheme: dark; }' \
  '    body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #111; font-family: Arial, sans-serif; }' \
  '    main { display: grid; gap: 16px; justify-items: center; padding: 16px; }' \
  '    .hero { max-width: min(92vw, 900px); max-height: 70vh; display: block; }' \
  '    .qr { width: min(60vw, 220px); height: auto; display: block; background: #fff; padding: 8px; border-radius: 8px; }' \
  '  </style>' \
  '</head>' \
  '<body>' \
  '  <main>' \
  '    <img class="hero" src="/austin-powers.jpg" alt="OSS Baby">' \
  '    <img class="qr" src="/qrcode_demo2.oss.baby.png" alt="QR code for OSS Baby">' \
  '  </main>' \
  '</body>' \
  '</html>' \
  > /usr/share/nginx/html/index.html

EXPOSE 80
