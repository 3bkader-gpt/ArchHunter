class ConfidenceScoringWorker:
    """
    Implements Bayesian updating for graph node and edge confidence scores.
    Formula: P(H|E) = P(E|H) * P(H) / (P(E|H) * P(H) + P(E|~H) * P(~H))
    """
    def __init__(self, name="Confidence Scoring Agent"):
        self.name = name

    def bayesian_update(self, prior: float, evidence_weight: float, is_positive: bool = True) -> float:
        """
        Updates confidence score based on new evidence weight.
        """
        prior = max(0.01, min(0.99, prior))
        likelihood = evidence_weight if is_positive else (1.0 - evidence_weight)
        false_positive_rate = 1.0 - likelihood

        numerator = likelihood * prior
        denominator = numerator + (false_positive_rate * (1.0 - prior))
        
        if denominator == 0:
            return prior
            
        posterior = numerator / denominator
        return round(min(1.0, max(0.0, posterior)), 4)

    def adjust_node_confidence(self, node: dict, signal_count: int, sources: list) -> float:
        """
        Multi-factor score calibration for architectural entities.
        """
        current_score = node.get("confidence_score", 0.5)
        
        # Boost for independent tool corroboration
        unique_sources = len(set(sources))
        if unique_sources > 1:
            weight = min(0.95, 0.7 + (0.1 * unique_sources))
            current_score = self.bayesian_update(current_score, weight, is_positive=True)
            
        return current_score
