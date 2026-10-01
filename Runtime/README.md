# Offensive Architectural Reasoning Runtime — MVP

This is the Minimum Viable Product (MVP) for the architectural reasoning engine. It implements a vertical slice from raw recon ingestion to hypothesis generation.

## 1. Structure
*   `cmd/runtime/main.go`: The primary CLI entrypoint.
*   `internal/`: Core Go packages (Ingestion, Graph, Orchestration).
*   `proto/`: gRPC service definitions.
*   `workers/`: Python-based inference agents.
*   `schemas/`: Machine-readable JSON schemas for validation.
*   `testdata/`: Sample recon signals for testing.

## 2. MVP Execution Flow
1.  **Ingestion:** Reads JSONL files from `testdata/`.
2.  **Normalization:** Flattens disparate tool outputs into standardized signals.
3.  **Graph Construction:** Creates an in-memory graph where nodes are physical assets.
4.  **Inference:** Runs specialized agents (currently mocked in the Go core) to identify mechanisms.
5.  **Export:** Outputs a `MachineReadableDFD.json` and a `HypothesisReport.json` in `outputs/`.

## 3. Machine Cognition Protocol (gRPC)
The runtime utilizes gRPC for communication between the Go Core and Python Workers. The contracts are defined in `proto/`:
*   `signal.proto`: Normalized architectural signals with provenance.
*   `graph.proto`: Multi-layer DFG with snapshot/delta support.
*   `hypothesis.proto`: Machine-readable attack hypotheses.
*   `reasoning.proto`: Inference task and result semantics.
*   `orchestration.proto`: Runtime lifecycle and session management.

### Compiling Protos
To compile the protos (requires `protoc` and plugins):
```bash
# Go
protoc --go_out=. --go-grpc_out=. proto/*.proto

# Python
python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. proto/*.proto
```

## 4. Running the MVP (Go)
To run the Go runtime (assuming Go is installed):
```bash
cd runtime
go run cmd/runtime/main.go -input testdata/sample_signals.jsonl
```

## 5. Live gRPC Bridge (Go ↔ Python)
The runtime can dispatch inference to the live Python reasoning worker instead
of the built-in mock client. Start the worker, then point the runtime at it:

```bash
# Terminal 1 — Python reasoning worker (gRPC server)
cd Runtime/workers
python reasoning_worker.py --port 50051

# Terminal 2 — Go runtime dispatching inference over gRPC
cd Runtime
go run cmd/runtime/main.go -input testdata/sample_signals.jsonl -workers-addr localhost:50051 -legacy
```

Behavior:
*   `-workers-addr` (or `ARCHHUNTER_WORKERS_ADDR` env var) activates the
    `inference.GrpcClient`; node types, labels, and properties are forwarded to
    the worker and its hypotheses are merged into the report (IDs prefixed `py_`).
*   If the worker is offline, the runtime logs
    `[gRPC] Worker ... offline (skipping remote call)` and completes with the
    remaining pipeline — no hard dependency.
*   Omitting the flag keeps the fully self-contained mock-client behavior.

## 6. Next Steps
*   [X] Implement gRPC contract layer.
*   [X] Compile `.proto` files into Go/Python stubs.
*   [X] Implement the actual gRPC bridge between Go and Python.
*   [X] Replace `MockClient` in `internal/inference` with the real gRPC client (opt-in via `-workers-addr`).
*   [ ] Implement more sophisticated graph walkers for trust boundaries.
*   [ ] Expand the Python worker's hypothesis repertoire (race, desync, smuggling heuristics).
