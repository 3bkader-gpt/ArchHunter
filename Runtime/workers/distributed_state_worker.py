import uuid
from base_worker import BaseReasoningWorker, serve_worker
try:
    from proto import reasoning_pb2 as reasoning
    from proto import hypothesis_pb2 as hypothesis
except ImportError:
    from .proto import reasoning_pb2 as reasoning
    from .proto import hypothesis_pb2 as hypothesis

class DistributedStateWorker(BaseReasoningWorker):
    """
    Analyzes graph nodes for asynchronous workflows, WebSocket state, and distributed consistency failures.
    """
    def __init__(self, name="Distributed-State Agent"):
        super().__init__(name)

    def Infer(self, request, context):
        print(f"[{self.name}] Processing inference task: {request.task_id}")
        nodes = request.sub_graph.nodes
        hypos = []

        for node in nodes:
            props = node.properties if hasattr(node, "properties") else {}
            node_id = node.id if hasattr(node, "id") else str(node)

            # Check for WebSocket state desync
            is_ws = props.get("upgrade") == "websocket" or "sec-websocket-key" in props or "ws." in node_id
            if is_ws:
                hypos.append(hypothesis.AttackHypothesis(
                    id=f"hypo_ws_{uuid.uuid4().hex[:8]}",
                    mechanism=hypothesis.ASYNC_TRUST_DECAY,
                    path_node_ids=[node_id],
                    risk_score=0.75,
                    confidence_score=0.7,
                    rationale=f"Stateful WebSocket connection at {node_id} — test per-message auth bypass and state machine race conditions"
                ))

            # Check for 202 Async Workflows
            is_async = props.get("status_code") == "202" or "retry-after" in props
            if is_async:
                hypos.append(hypothesis.AttackHypothesis(
                    id=f"hypo_async_{uuid.uuid4().hex[:8]}",
                    mechanism=hypothesis.ASYNC_TRUST_DECAY,
                    path_node_ids=[node_id],
                    risk_score=0.8,
                    confidence_score=0.75,
                    rationale=f"Async job processor at {node_id} (202 Accepted) — test validation latency and idempotency key exhaustion"
                ))

        return reasoning.InferenceResult(
            task_id=request.task_id,
            hypotheses=hypos,
            confidence_updates=[],
            reasoning_trace=f"Distributed State Worker evaluated {len(nodes)} nodes for stateful and async mechanisms."
        )

if __name__ == "__main__":
    serve_worker(DistributedStateWorker, "Distributed-State Agent", port="50053")
