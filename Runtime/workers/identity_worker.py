import uuid
from base_worker import BaseReasoningWorker, serve_worker
try:
    from proto import reasoning_pb2 as reasoning
    from proto import hypothesis_pb2 as hypothesis
except ImportError:
    from .proto import reasoning_pb2 as reasoning
    from .proto import hypothesis_pb2 as hypothesis

class IdentityWorker(BaseReasoningWorker):
    """
    Analyzes graph nodes for identity context propagation, token leaks, and SSO boundaries.
    """
    def __init__(self, name="Identity Agent"):
        super().__init__(name)

    def Infer(self, request, context):
        print(f"[{self.name}] Processing inference task: {request.task_id}")
        nodes = request.sub_graph.nodes
        hypos = []

        for node in nodes:
            props = node.properties if hasattr(node, "properties") else {}
            node_id = node.id if hasattr(node, "id") else str(node)

            # Check for exposed tokens / credentials
            has_auth = "authorization" in props or "cookie" in props or "set-cookie" in props
            has_oidc = ".well-known/openid-configuration" in node_id or "oauth" in node_id.lower()

            if has_auth and ("http:" in node_id or "debug" in node_id or "metrics" in node_id):
                hypos.append(hypothesis.AttackHypothesis(
                    id=f"hypo_identity_leak_{uuid.uuid4().hex[:8]}",
                    mechanism=hypothesis.IDENTITY_LEAK,
                    path_node_ids=[node_id],
                    risk_score=0.85,
                    confidence_score=0.75,
                    rationale=f"Sensitive identity context detected on unprotected endpoint: {node_id}"
                ))

            if has_oidc:
                hypos.append(hypothesis.AttackHypothesis(
                    id=f"hypo_oidc_{uuid.uuid4().hex[:8]}",
                    mechanism=hypothesis.STALE_AUTH_PROPAGATION,
                    path_node_ids=[node_id],
                    risk_score=0.7,
                    confidence_score=0.8,
                    rationale=f"OIDC/OAuth trust bridge identified at {node_id} — test token audience confusion and redirect URI validation"
                ))

        return reasoning.InferenceResult(
            task_id=request.task_id,
            hypotheses=hypos,
            confidence_updates=[],
            reasoning_trace=f"Identity Worker analyzed {len(nodes)} nodes for auth boundaries and token leaks."
        )

if __name__ == "__main__":
    serve_worker(IdentityWorker, "Identity Agent", port="50052")
