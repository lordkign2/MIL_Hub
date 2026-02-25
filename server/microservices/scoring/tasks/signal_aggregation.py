import numpy as np
from typing import Dict, List, Optional
import logging
from pydantic import BaseModel
from datetime import datetime

logger = logging.getLogger(__name__)

class SignalData(BaseModel):
    signal_type: str
    signal_value: float
    confidence: float
    source: str
    timestamp: str
    metadata: Optional[Dict] = None

class TrustScoreResult(BaseModel):
    trust_score: float
    verdict: str
    confidence_breakdown: Dict[str, float]
    recommendations: List[str]
    detailed_signals: List[SignalData]
    created_at: str

class SignalAggregator:
    def __init__(self):
        logger.info("Initializing Signal Aggregator")
        
        # Trust scoring weights
        self.weights = {
            'reverse_search': 0.25,
            'hash_confidence': 0.20,
            'ai_detection': 0.20,
            'context_score': 0.20,
            'metadata_score': 0.15
        }
    
    def aggregate_signals(self, media_signals: List[SignalData]) -> Dict[str, float]:
        """Aggregate signals by type and calculate weighted averages"""
        try:
            aggregated = {}
            
            # Group signals by type
            signal_groups = {}
            for signal in media_signals:
                if signal.signal_type not in signal_groups:
                    signal_groups[signal.signal_type] = []
                signal_groups[signal.signal_type].append(signal)
            
            # Calculate weighted averages for each signal type
            for signal_type, signals in signal_groups.items():
                if signals:
                    # Weighted average based on confidence
                    total_weight = sum(signal.confidence for signal in signals)
                    if total_weight > 0:
                        weighted_sum = sum(
                            signal.signal_value * signal.confidence 
                            for signal in signals
                        )
                        aggregated[signal_type] = weighted_sum / total_weight
                    else:
                        # Simple average if no confidence weights
                        aggregated[signal_type] = np.mean([
                            signal.signal_value for signal in signals
                        ])
                else:
                    aggregated[signal_type] = 0.5  # Neutral score
            
            return aggregated
            
        except Exception as e:
            logger.error(f"Signal aggregation failed: {e}")
            return {}
    
    def calculate_trust_score(self, aggregated_signals: Dict[str, float]) -> float:
        """Calculate overall trust score using weighted formula"""
        try:
            # Map signal types to scoring components
            score_components = {
                'reverse_confidence': aggregated_signals.get('reverse_search', 0.5),
                'hash_confidence': aggregated_signals.get('hash_confidence', 0.5),
                'ai_confidence': aggregated_signals.get('ai_detection', 0.5),
                'context_score': aggregated_signals.get('context_score', 0.5),
                'metadata_score': aggregated_signals.get('metadata_score', 0.5)
            }
            
            # Calculate weighted trust score
            trust_score = sum(
                score_components[component] * self.weights.get(component.replace('_confidence', '_search').replace('_score', '_search'), 0.2)
                for component in score_components
            )
            
            return min(max(trust_score, 0.0), 1.0)
            
        except Exception as e:
            logger.error(f"Trust score calculation failed: {e}")
            return 0.5
    
    def determine_verdict(self, trust_score: float, aggregated_signals: Dict[str, float]) -> str:
        """Determine final verdict based on trust score and signal analysis"""
        try:
            # Check for strong indicators
            ai_generated_prob = aggregated_signals.get('ai_detection', 0.5)
            context_credibility = aggregated_signals.get('context_score', 0.5)
            
            # High AI probability indicates likely manipulation
            if ai_generated_prob > 0.8:
                return "AI-Generated Content"
            
            # Low context credibility with high trust score might indicate out-of-context
            if context_credibility < 0.3 and trust_score > 0.7:
                return "Out of Context"
            
            # Standard verdict based on trust score
            if trust_score >= 0.8:
                return "Highly Authentic"
            elif trust_score >= 0.6:
                return "Likely Authentic"
            elif trust_score >= 0.4:
                return "Suspicious"
            elif trust_score >= 0.2:
                return "Likely Manipulated"
            else:
                return "Highly Suspicious"
                
        except Exception as e:
            logger.error(f"Verdict determination failed: {e}")
            return "Uncertain"
    
    def generate_recommendations(self, trust_score: float, verdict: str, 
                                aggregated_signals: Dict[str, float]) -> List[str]:
        """Generate recommendations based on analysis results"""
        try:
            recommendations = []
            
            # Add recommendations based on verdict
            if "AI-Generated" in verdict:
                recommendations.extend([
                    "Content appears to be AI-generated",
                    "Verify with original source if available",
                    "Consider context and intent of sharing"
                ])
            elif "Out of Context" in verdict:
                recommendations.extend([
                    "Content may be genuine but used out of context",
                    "Check original source and full context",
                    "Verify the intended meaning"
                ])
            elif "Highly Authentic" in verdict:
                recommendations.extend([
                    "Content appears authentic and trustworthy",
                    "No immediate concerns detected",
                    "Share responsibly with proper attribution"
                ])
            elif "Suspicious" in verdict:
                recommendations.extend([
                    "Exercise caution when sharing this content",
                    "Verify with additional sources",
                    "Consider fact-checking before distribution"
                ])
            elif "Manipulated" in verdict:
                recommendations.extend([
                    "Content shows signs of manipulation",
                    "Do not share without verification",
                    "Report to appropriate authorities if concerning"
                ])
            
            # Add signal-specific recommendations
            if aggregated_signals.get('context_score', 0.5) < 0.3:
                recommendations.append("Context appears questionable - verify source credibility")
            
            if aggregated_signals.get('reverse_search', 0.5) < 0.4:
                recommendations.append("Limited reverse search matches found - investigate further")
            
            return recommendations
            
        except Exception as e:
            logger.error(f"Recommendation generation failed: {e}")
            return ["Unable to generate specific recommendations due to analysis error"]
    
    def generate_confidence_breakdown(self, aggregated_signals: Dict[str, float], 
                                     media_signals: List[SignalData]) -> Dict[str, float]:
        """Generate detailed confidence breakdown"""
        try:
            breakdown = {}
            
            # Calculate confidence for each component
            for component, value in aggregated_signals.items():
                # Count signals for this component
                component_signals = [s for s in media_signals if s.signal_type == component]
                signal_count = len(component_signals)
                
                # Calculate component confidence
                if signal_count > 0:
                    avg_confidence = np.mean([s.confidence for s in component_signals])
                    # Combine signal value confidence with signal count confidence
                    count_confidence = min(signal_count / 5.0, 1.0)  # Normalize to 5 signals
                    breakdown[component] = (avg_confidence + count_confidence) / 2.0
                else:
                    breakdown[component] = 0.5  # Neutral confidence
            
            # Overall confidence
            if breakdown:
                breakdown['overall'] = float(np.mean(list(breakdown.values())))
            else:
                breakdown['overall'] = 0.5
            
            return breakdown
            
        except Exception as e:
            logger.error(f"Confidence breakdown failed: {e}")
            return {'overall': 0.5}
    
    def aggregate_verification_results(self, media_id: str, 
                                     all_signals: List[SignalData]) -> TrustScoreResult:
        """Main aggregation function that combines all verification results"""
        try:
            logger.info(f"Aggregating verification results for {media_id}")
            
            # Aggregate signals
            aggregated_signals = self.aggregate_signals(all_signals)
            
            # Calculate trust score
            trust_score = self.calculate_trust_score(aggregated_signals)
            
            # Determine verdict
            verdict = self.determine_verdict(trust_score, aggregated_signals)
            
            # Generate recommendations
            recommendations = self.generate_recommendations(trust_score, verdict, aggregated_signals)
            
            # Generate confidence breakdown
            confidence_breakdown = self.generate_confidence_breakdown(aggregated_signals, all_signals)
            
            # Create result
            result = TrustScoreResult(
                trust_score=trust_score,
                verdict=verdict,
                confidence_breakdown=confidence_breakdown,
                recommendations=recommendations,
                detailed_signals=all_signals,
                created_at=datetime.utcnow().isoformat()
            )
            
            logger.info(f"Verification aggregation completed for {media_id}: {verdict} ({trust_score:.2f})")
            return result
            
        except Exception as e:
            logger.error(f"Verification aggregation failed for {media_id}: {e}")
            # Return error result
            return TrustScoreResult(
                trust_score=0.0,
                verdict="Analysis Failed",
                confidence_breakdown={'overall': 0.0},
                recommendations=["Verification process encountered an error"],
                detailed_signals=[],
                created_at=datetime.utcnow().isoformat()
            )