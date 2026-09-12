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

## 5. Next Steps
*   [X] Implement gRPC contract layer.
*   [ ] Compile `.proto` files into Go/Python stubs.
*   [ ] Implement the actual gRPC bridge between Go and Python.
*   [ ] Replace `MockClient` in `internal/inference` with the real gRPC client.
*   [ ] Implement more sophisticated graph walkers for trust boundaries.
