# ========== Build Stage ==========
FROM golang:1.25 AS builder

# 设置工作目录
WORKDIR /app

# 先拷贝 go.mod 和 go.sum，加快依赖下载
COPY go.mod go.sum ./
RUN go mod download

# 再拷贝源码
COPY . .

# 关闭 CGO 并指定目标平台，构建静态二进制
RUN CGO_ENABLED=0 GOOS=linux go build -o notification-server .

# ========== Runtime Stage ==========
FROM alpine:3.20

WORKDIR /app

RUN apk add tzdata

COPY --from=builder /app/notification-server .

# 如果你的服务用到配置文件，可以 COPY 进来，比如：
# COPY config.yaml .

EXPOSE 8083
ENTRYPOINT ["./notification-server"]
