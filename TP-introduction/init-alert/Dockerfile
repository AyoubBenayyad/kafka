FROM alpine:3.19

RUN apk add --no-cache curl bash

COPY init-alert.sh /init-alert.sh
RUN chmod +x /init-alert.sh

CMD ["/init-alert.sh"]
