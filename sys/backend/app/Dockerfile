# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache gcc musl-dev git

# Install templ CLI
RUN go install github.com/a-h/templ/cmd/templ@v0.2.778

# Copy source code
COPY . .

# Generate templ templates first (creates .go files from .templ files)
RUN templ generate

# Download dependencies
RUN go mod tidy

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o serifu ./main.go

# Runtime stage
FROM alpine:latest

WORKDIR /app

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /app/serifu .

# Copy static files and seeds
COPY --from=builder /app/static ./static
COPY --from=builder /app/seeds ./seeds

# Expose port
EXPOSE 8080

# Run the application
CMD ["./serifu"]
