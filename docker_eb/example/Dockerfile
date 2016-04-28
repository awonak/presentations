FROM golang:1.6

# Copy the app source
RUN mkdir -p /go/src/example
WORKDIR /go/src/example
ADD . /go/src/example

# Build & Install the application
RUN go install

# Expose the default gin port
EXPOSE 8080
CMD ["example"]
