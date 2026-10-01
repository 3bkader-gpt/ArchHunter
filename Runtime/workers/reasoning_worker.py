#!/usr/bin/env python3
"""ArchHunter live reasoning worker (gRPC ReasoningWorker implementation).

Replaces the BaseReasoningWorker stub: Infer() actually analyzes the sub-graph
snapshot sent by the Go runtime and returns hypothesis records derived from
node architecture (identity-bearing nodes, internal service exposure).

Serve:
    python workers/reasoning_worker.py --port 50051
Point the Go runtime at it:
    go run ./cmd/runtime -input testdata/sample_signals.jsonl -workers-addr localhost:50051 -legacy
"""
import argparse
import time

from google.protobuf.timestamp_pb2 import Timestamp

try:
    from proto import graph_pb2 as graph
    from proto import hypothesis_pb2 as hypothesis
    from proto import reasoning_pb2 as reasoning
except ImportError:
    from .proto import graph_pb2 as graph
    from .proto import hypothesis_pb2 as hypothesis
    from .proto import reasoning_pb2 as reasoning

from base_worker import BaseReasoningWorker, serve_worker


def _identity_bearing(node):
    return bool(node.properties.get("authorization") or node.properties.get("cookie"))


class ArchHunterReasoningWorker(BaseReasoningWorker):
    """Derives architectural attack hypotheses from sub-graph snapshots."""

    def Infer(self, request, context):
        nodes = list(request.sub_graph.nodes)
        hypotheses = []
        trace_parts = [f"nodes={len(nodes)}"]

        identity_nodes = [n for n in nodes if _identity_bearing(n)]
        internal_nodes = [n for n in nodes if n.type == graph.INTERNAL_SERVICE]
        trace_parts.append(f"identity_bearing={len(identity_nodes)}")
        trace_parts.append(f"internal_services={len(internal_nodes)}")

        now = Timestamp()
        now.GetCurrentTime()

        if identity_nodes:
            hypotheses.append(hypothesis.AttackHypothesis(
                id=f"py_identity_leak_{int(time.time() * 1e6)}",
                mechanism=hypothesis.IDENTITY_LEAK,
                path_node_ids=[n.id for n in identity_nodes],
                risk_score=0.7,
                confidence_score=min(0.9, 0.5 + 0.05 * len(identity_nodes)),
                rationale=(
                    f"Python worker: {len(identity_nodes)} node(s) propagate "
                    "authorization/cookie material — identity re-validation "
                    "at downstream trust boundaries cannot be confirmed."
                ),
                generated_at=now,
            ))

        if internal_nodes:
            hypotheses.append(hypothesis.AttackHypothesis(
                id=f"py_internal_surface_{int(time.time() * 1e6)}",
                mechanism=hypothesis.UNKNOWN_MECHANISM,
                path_node_ids=[n.id for n in internal_nodes],
                risk_score=0.65,
                confidence_score=min(0.85, 0.5 + 0.05 * len(internal_nodes)),
                rationale=(
                    f"Python worker: {len(internal_nodes)} internal service "
                    "node(s) exposed — candidate SSRF pivot / metadata "
                    "escalation surface."
                ),
                generated_at=now,
            ))

        if not hypotheses and nodes:
            hypotheses.append(hypothesis.AttackHypothesis(
                id=f"py_generic_surface_{int(time.time() * 1e6)}",
                mechanism=hypothesis.UNKNOWN_MECHANISM,
                path_node_ids=[nodes[0].id],
                risk_score=0.7,
                confidence_score=0.5,
                rationale="Python worker: multiple physical signals detected for this node.",
                generated_at=now,
            ))

        return reasoning.InferenceResult(
            task_id=request.task_id,
            hypotheses=hypotheses,
            reasoning_trace=" | ".join(trace_parts),
        )

    def AnalyzeTopology(self, request, context):
        # Topology-only pass: same analysis, no task id context.
        return self.Infer(request, context)


def main():
    ap = argparse.ArgumentParser(description="ArchHunter Python reasoning worker")
    ap.add_argument("--port", default="50051", help="gRPC listen port (default: 50051)")
    args = ap.parse_args()
    serve_worker(ArchHunterReasoningWorker, "python-reasoning", args.port)


if __name__ == "__main__":
    main()
