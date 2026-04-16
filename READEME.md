# x64-webserver

A minimal HTTP server written in x86-64 assembly for Linux.

It builds a single binary named `server`, listens on TCP port `80`, forks for each accepted connection, and supports two basic request types:

- `GET /path` reads a file from disk and returns its contents after `HTTP/1.0 200 OK`
- `POST /path` creates or overwrites a file with the request body, then returns `HTTP/1.0 200 OK`

## Files

- `main.s` starts the server, accepts connections, and forks child processes
- `network.s` wraps the socket-related syscalls
- `io.s` wraps `open`, `read`, `write`, and `close`
- `req_handler.s` parses `GET` and `POST` requests and performs file I/O
- `Makefile` builds the project

## Build

```bash
make
```

This produces:

```bash
./server
```

## Run

```bash
make run
```

Or:

```bash
./server
```

Note: the server binds to port `80`, which usually requires root privileges on Linux.

## Behavior

- Listens on IPv4 `0.0.0.0:80`
- Uses a fork-per-connection model
- Reads request data into a fixed-size buffer
- Returns a very small HTTP response header: `HTTP/1.0 200 OK`

## Limitations

- Linux only
- x86-64 only
- No error handling or status codes other than `200 OK`
- No directory handling, routing, MIME types, or persistent connections
- Request parsing is very minimal and only expects simple `GET` and `POST` requests
