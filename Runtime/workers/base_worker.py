import grpc
from concurrent import futures
import time

# Compiled proto imports
try:
    from proto import graph_pb2 as graph
    from proto import reasoning_pb2 as reasoning
    from proto import reasoning_pb2_grpc as reasoning_grpc
    from proto import hypothesis_pb2 as hypothesis
except ImportError:
    from .proto import graph_pb2 as graph
    from .proto import reasoning_pb2 as reasoning
    from .proto import reasoning_pb2_grpc as reasoning_grpc
    from .proto import hypothesis_pb2 as hypothesis

class BaseReasoningWorker(reasoning_grpc.ReasoningWorkerServicer):
    def __init__(self, name):
        self.name = name

    def Infer(self, request, context):
        print(f"[{self.name}] Received inference task: {request.task_id}")
        
        # 1. Access request.sub_graph
        # 2. Run heuristic/ML models
        # 3. Build reasoning.InferenceResult
        
        return None # reasoning.InferenceResult(...)

    def AnalyzeTopology(self, request, context):
        return None

def serve_worker(worker_class, name, port="50051"):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    reasoning_grpc.add_ReasoningWorkerServicer_to_server(worker_class(name), server)
    server.add_insecure_port(f'[::]:{port}')
    print(f"[{name}] Starting gRPC server on port {port}...")
    server.start()
    try:
        while True:
            time.sleep(86400)
    except KeyboardInterrupt:
        server.stop(0)

if __name__ == "__main__":
    print("Base Worker Template")
