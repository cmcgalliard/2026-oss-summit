FROM nginx:alpine

COPY austin-powers.jpg /usr/share/nginx/html/austin-powers.jpg

RUN printf '%s\n' \
  '<!doctype html>' \
  '<html lang="en">' \
  '<head>' \
  '  <meta charset="utf-8">' \
  '  <meta name="viewport" content="width=device-width, initial-scale=1">' \
  '  <title>OSS Baby</title>' \
  '  <style>' \
  '    body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #111; }' \
  '    img { max-width: 100%; max-height: 100vh; display: block; }' \
  '  </style>' \
  '</head>' \
  '<body>' \
  '  <img src="/austin-powers.jpg" alt="OSS Baby">' \
  '</body>' \
  '</html>' \
  > /usr/share/nginx/html/index.html

EXPOSE 80
