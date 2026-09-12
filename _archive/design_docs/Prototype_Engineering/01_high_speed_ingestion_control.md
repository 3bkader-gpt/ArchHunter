# 01 — High-Speed Ingestion Control

The Physical Runtime Engine must process bursty, high-volume reconnaissance signals without saturating the Graph Execution Engine. This document outlines the ingestion stabilization strategy.

## 1. Ingestion Burst Handling
Recon tools (like `httpx` or `katana`) often dump thousands of findings simultaneously.
*   **Decoupled Ingestion:** Use an asynchronous message broker (e.g., NATS JetStream or Kafka) between the log-tailing sensors and the normalization workers.
*   **Parallel Normalization:** Auto-scale worker goroutines based on queue depth to flatten JSON lines into `ArchitecturalSignal` objects.

## 2. Queue Backpressure & Buffering Strategy
*   **L0 Ring Buffer:** High-speed, fixed-size ring buffers in memory to absorb micro-bursts before hitting the message queue.
*   **Dynamic Backpressure:** If the Graph Execution Engine's processing time exceeds ingestion rate, the Orchestration Core sends a backpressure signal to the workers to throttle processing, ensuring the in-memory graph is not overwhelmed.

## 3. Signal Deduplication (Pre-Graph)
Redundant signals waste graph traversal cycles.
*   **Hash-Based Dedup:** Generate an MD5/SHA-256 hash for every `ArchitecturalSignal` payload.
*   **Bloom Filters:** Use a distributed Bloom Filter at the edge of the ingestion pipeline to drop exact duplicate signals in O(1) time before they reach the orchestration layer.

## 4. Async Ingestion Stabilization
*   **Batching:** Group multiple related signals (e.g., all headers from a single HTTP response) into a single `NodeUpdate` transaction to minimize locking overhead on the graph database.
*   **Jitter:** Introduce small, randomized delays during peak ingestion to smooth out lock contention in the graph core.
