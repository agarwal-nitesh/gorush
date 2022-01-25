FROM golang:1.16-alpine as builder
WORKDIR /app
COPY Makefile .
COPY certificate certificate
COPY config config
COPY core core
COPY logx logx
COPY metric metric
COPY notify notify
COPY release release
COPY router router
COPY status status
COPY storage storage
COPY main.go .
COPY go.mod .
COPY go.sum .
COPY Procfile .

ARG VERSION="latest"
ENV VERSION="$VERSION"

RUN echo "$VERSION"
RUN apk add build-base
RUN make clean build

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY config config
COPY certificate certificate
COPY --from=builder /app/release release
RUN ls

EXPOSE 8088
CMD [ "./release/gorush" ]
