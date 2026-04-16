# 🚀 x64-webserver

A minimal HTTP server written in x86-64 assembly for Linux, using only syscalls.

---

## ✨ Features

* **Zero Dependencies:** No `libc` or external libraries. Just raw assembly and the Linux kernel.
* **Concurrent:** Uses the `fork` model to handle multiple incoming connections simultaneously.
* **Ultra Lightweight:** Compiles to a tiny binary (typically < 5KB).
* **I/O:** Implements basic `GET` and `POST` methods for file interaction.
* **Pure Syscalls:** Leverages `sys_socket`, `sys_bind`, `sys_fork`, and more.

---

## 🏗 Project Structure

an example of the request flow will be:

socket → bind → listen → accept → fork → parse → open, read/write, close → respond

The codebase is modularized to separate networking logic from request handling:

| File | Description | Key Syscalls |
| :--- | :--- | :--- |
| **`main.s`** | The entry point (`_start`). Orchestrates the `accept` loop and process forking. | `fork`, `exit` |
| **`network.s`** | Socket abstraction layer. Handles IPv4 binding on port 80. | `socket`, `bind`, `listen`, `accept` |
| **`req_handler.s`** | Parses HTTP headers and routes `GET`/`POST` logic. | — |
| **`io.s`** | Lightweight wrappers for file and stream operations. | `open`, `read`, `write`, `close` |
| **`Makefile`** | Simple build script using `as` and `ld`. | — |

---

## Getting Started

### Prerequisites

You need a Linux environment with `binutils` (specifically `as` and `ld`) installed, which are installed by default with `gcc`.

### Build

To assemble and link the server, simply run:

```bash
make
```

### Run

Port 80 requires elevated privileges on most systems, so run it with sudo

```bash
sudo make run
```

### Behavior

* Listens on IPv4 `0.0.0.0:80`, looking at all available interfaces
* Uses a fork-per-connection model
* Reads request data into a fixed-size buffer
* Returns an HTTP response header: `HTTP/1.0 200 OK`

---

## Usage

A basic usage example will be to run the server in a terminal then in another one do

```bash
curl http://127.0.0.1/<path-to-file-to-be-read>
```

to perform a `GET` request, or

```bash
curl -X POST http://127.0.0.1/<path-to-file-to-be-created-or-updated> -d "<content>"
```

for a `POST` request

---

## License

This project is licensed under the MIT License - see the LICENSE.md file for details
