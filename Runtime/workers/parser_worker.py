import time
import uuid
try:
    from base_worker import BaseReasoningWorker, serve_worker
    from proto import reasoning_pb2 as reasoning
    from proto import hypothesis_pb2 as hypothesis
except ImportError:
    from .base_worker import BaseReasoningWorker, serve_worker
    from .proto import reasoning_pb2 as reasoning
    from .proto import hypothesis_pb2 as hypothesis

class ParserWorker(BaseReasoningWorker):
    def __init__(self, name):
        super().__init__(name)

    def Infer(self, request, context):
        print(f"[{self.name}] Received inference task: {request.task_id}")
        nodes = request.sub_graph.nodes
        
        hypos = []
        for node in nodes:
            if "server" in node.properties:
                hypos.append(hypothesis.AttackHypothesis(
                    id=f"hypo_{uuid.uuid4()}",
                    mechanism=hypothesis.PARSER_DIFFERENTIAL,
                    path_node_ids=[node.id],
                    risk_score=0.6,
                    confidence_score=0.4,
                    rationale=f"Potential differential detected on {node.id} based on Server header."
                ))
        
        return reasoning.InferenceResult(
            task_id=request.task_id,
            hypotheses=hypos,
            confidence_updates=[],
            reasoning_trace="Analyzed nodes for server header variations."
        )

if __name__ == "__main__":
    serve_worker(ParserWorker, "Parser Agent", port="50051")
