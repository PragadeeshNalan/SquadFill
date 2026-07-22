"""
Mock WebSocket server for backend load testing.
Handles ws:// connections, echoes messages, supports all SecureChat message types.
Run: python mock_ws_server.py --port 8766
"""
import asyncio
import json
import logging
import argparse
import signal

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("MockWSServer")

try:
    import websockets
    HAS_WEBSOCKETS = True
except ImportError:
    HAS_WEBSOCKETS = False


async def handle_client(websocket, path=""):
    peer = websocket.remote_address
    logger.info(f"[+] Client connected: {peer}")
    try:
        async for raw_message in websocket:
            try:
                data = json.loads(raw_message)
                msg_type = data.get("type", "unknown")

                if msg_type == "public_key":
                    # Echo back a mock peer public key
                    response = {
                        "type": "public_key",
                        "key": data.get("key", ""),
                    }
                    await websocket.send(json.dumps(response))

                elif msg_type == "encrypted":
                    # Echo back the encrypted message
                    response = {
                        "type": "encrypted",
                        "sessionKey": data.get("sessionKey", ""),
                        "iv":         data.get("iv", ""),
                        "content":    data.get("content", ""),
                    }
                    await websocket.send(json.dumps(response))

                elif msg_type == "typing":
                    # Echo typing status
                    response = {
                        "type":     "typing",
                        "isTyping": data.get("isTyping", False),
                    }
                    await websocket.send(json.dumps(response))

                elif msg_type == "ping":
                    await websocket.send(json.dumps({"type": "pong"}))

                else:
                    # Echo unknown messages
                    await websocket.send(json.dumps({
                        "type": "echo",
                        "original": data,
                    }))

            except json.JSONDecodeError:
                # Non-JSON message — echo it back as-is
                await websocket.send(f"echo: {raw_message[:100]}")
            except Exception as e:
                logger.error(f"Error handling message: {e}")

    except Exception as e:
        logger.info(f"[-] Client disconnected: {peer} — {type(e).__name__}")


async def run_server(host="localhost", port=8766):
    if not HAS_WEBSOCKETS:
        logger.error("websockets package not installed. Run: pip install websockets")
        return
    logger.info(f"Starting mock WebSocket server on ws://{host}:{port}")
    async with websockets.serve(handle_client, host, port, ping_interval=20):
        await asyncio.Future()  # Run forever


def main():
    parser = argparse.ArgumentParser(description="SecureChat Mock WebSocket Server")
    parser.add_argument("--host", default="localhost", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8766, help="Port to listen on")
    args = parser.parse_args()
    asyncio.run(run_server(args.host, args.port))


if __name__ == "__main__":
    main()
