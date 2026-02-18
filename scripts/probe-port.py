#!/usr/bin/env python3
# much more elaborate version of
# nc -zv <host> <port>
import argparse
import socket
import sys
import time


def probe(target, port, timeout=10):
    sock = socket.socket()
    sock.settimeout(timeout)
    print("\033[K", end='')
    try:
        sock.connect((target, port))
    except Exception as e:
        print(f"NO! - {e}", end="\r")
        return False
    else:
        print("YES!", end="\r")
        return True
    finally:
        sock.close()


def main():
    parser = argparse.ArgumentParser(prog="probe-port",formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("target", help="Host or IP to test ready port on")
    parser.add_argument("port", type=int, help="Port number to test ready")
    parser.add_argument("-w", "--watch", action="store_true", help="continue polling")
    parser.add_argument("--timeout", type=int, default=10, help="Connection timeout in seconds")
    parser.add_argument("--interval", type=int, default=1, help="Interval between polling attempts")
    args = parser.parse_args()
    res = probe(args.target, args.port, timeout=args.timeout)
    while args.watch:
        try:
            res = probe(args.target, args.port, timeout=args.timeout)
            time.sleep(args.interval)
        except KeyboardInterrupt:
            break
    print("\n")
    return res


if __name__ == "__main__":
    res = main()
    sys.exit(int(not res))
