import spacy
import requests
import numpy as np
from typing import Dict, List, Optional
import logging
from pydantic import BaseModel
from datetime import datetime

logger = logging.getLogger(__name__)

class ContextAnalysisResult(BaseModel):
    extracted_claims: List[Dict]
    fact_check_results: List[Dict]
    news_api_matches: List[Dict]
    credibility_score: float
    sentiment_analysis: Dict
    entity_recognition: List[Dict]
    technical_metadata: Dict
    confidence: float

class ContextVerificationEngine:
    def __init__(self):
        logger.info("Initializing Context Verification Engine")
        
        # Load spaCy model
        try:
            self.nlp = spacy.load("en_core_web_sm")
            logger.info("spaCy model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load spaCy model: {e}")
            raise
        
        # News API configuration
        self.news_api_key = "YOUR_NEWSAPI_KEY"  # Should be in environment variables
        self.news_api_url = "https://newsapi.org/v2/everything"
    
    def extract_claims(self, text: str) -> List[Dict]:
        """Extract factual claims from text using NLP"""
        try:
            doc = self.nlp(text)
            
            claims = []
            # Extract sentences that contain potential claims
            for sent in doc.sents:
                # Look for claim indicators
                claim_indicators = ['claims', 'states', 'says', 'reported', 'according to']
                if any(indicator in sent.text.lower() for indicator in claim_indicators):
                    # Extract named entities
                    entities = [(ent.text, ent.label_) for ent in sent.ents]
                    
                    claims.append({
                        'text': sent.text.strip(),
                        'entities': entities,
                        'claim_type': self._classify_claim_type(sent.text),
                        'confidence': self._calculate_claim_confidence(sent.text, entities)
                    })
            
            return claims
            
        except Exception as e:
            logger.error(f"Claim extraction failed: {e}")
            return []
    
    def check_factuality(self, claims: List[Dict]) -> List[Dict]:
        """Check claims against fact-checking databases"""
        try:
            fact_checks = []
            
            for claim in claims:
                # Simple fact-checking simulation
                # In production, integrate with real fact-checking APIs
                fact_check = {
                    'claim': claim['text'],
                    'verification_status': self._verify_claim(claim['text']),
                    'confidence': claim['confidence'],
                    'sources_checked': ['simulated_fact_check_db'],
                    'timestamp': datetime.utcnow().isoformat()
                }
                fact_checks.append(fact_check)
            
            return fact_checks
            
        except Exception as e:
            logger.error(f"Fact checking failed: {e}")
            return []
    
    def search_news_context(self, text: str) -> List[Dict]:
        """Search for related news articles"""
        try:
            # Extract keywords for search
            doc = self.nlp(text)
            keywords = [token.lemma_ for token in doc if not token.is_stop and token.is_alpha]
            search_query = " ".join(keywords[:5])  # Limit to 5 keywords
            
            # Simulate news API call
            news_matches = self._simulate_news_search(search_query)
            
            return news_matches
            
        except Exception as e:
            logger.error(f"News search failed: {e}")
            return []
    
    def analyze_sentiment(self, text: str) -> Dict:
        """Analyze sentiment of the text"""
        try:
            doc = self.nlp(text)
            
            # Simple sentiment analysis based on adjectives and adverbs
            positive_words = ['good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic']
            negative_words = ['bad', 'terrible', 'awful', 'horrible', 'disgusting', 'worst']
            
            text_lower = text.lower()
            positive_count = sum(1 for word in positive_words if word in text_lower)
            negative_count = sum(1 for word in negative_words if word in text_lower)
            
            total_sentiment_words = positive_count + negative_count
            if total_sentiment_words > 0:
                sentiment_score = (positive_count - negative_count) / total_sentiment_words
            else:
                sentiment_score = 0.0
            
            return {
                'sentiment_score': sentiment_score,
                'positive_indicators': positive_count,
                'negative_indicators': negative_count,
                'magnitude': abs(sentiment_score),
                'label': self._sentiment_label(sentiment_score)
            }
            
        except Exception as e:
            logger.error(f"Sentiment analysis failed: {e}")
            return {'sentiment_score': 0.0, 'label': 'neutral'}
    
    def recognize_entities(self, text: str) -> List[Dict]:
        """Extract and categorize named entities"""
        try:
            doc = self.nlp(text)
            
            entities = []
            for ent in doc.ents:
                entities.append({
                    'text': ent.text,
                    'label': ent.label_,
                    'start_char': ent.start_char,
                    'end_char': ent.end_char,
                    'confidence': 0.9  # spaCy confidence is high for recognized entities
                })
            
            return entities
            
        except Exception as e:
            logger.error(f"Entity recognition failed: {e}")
            return []
    
    def verify_context(self, content: str, media_id: str) -> ContextAnalysisResult:
        """Perform complete context verification analysis"""
        try:
            logger.info(f"Starting context verification for {media_id}")
            
            # Extract claims
            claims = self.extract_claims(content)
            
            # Check factuality
            fact_checks = self.check_factuality(claims)
            
            # Search news context
            news_matches = self.search_news_context(content)
            
            # Analyze sentiment
            sentiment = self.analyze_sentiment(content)
            
            # Recognize entities
            entities = self.recognize_entities(content)
            
            # Calculate credibility score
            credibility_score = self._calculate_credibility_score(
                len(claims),
                len(fact_checks),
                len(news_matches),
                sentiment['sentiment_score']
            )
            
            # Calculate confidence
            confidence = self._calculate_context_confidence(
                len(claims),
                len(fact_checks),
                len(entities)
            )
            
            result = ContextAnalysisResult(
                extracted_claims=claims,
                fact_check_results=fact_checks,
                news_api_matches=news_matches,
                credibility_score=credibility_score,
                sentiment_analysis=sentiment,
                entity_recognition=entities,
                technical_metadata={
                    'text_length': len(content),
                    'total_entities': len(entities),
                    'total_claims': len(claims),
                    'analysis_timestamp': datetime.utcnow().isoformat()
                },
                confidence=confidence
            )
            
            logger.info(f"Context verification completed for {media_id}")
            return result
            
        except Exception as e:
            logger.error(f"Context verification failed for {media_id}: {e}")
            raise
    
    def _classify_claim_type(self, claim_text: str) -> str:
        """Classify the type of claim"""
        claim_text_lower = claim_text.lower()
        
        if any(word in claim_text_lower for word in ['said', 'claimed', 'stated']):
            return 'reported_statement'
        elif any(word in claim_text_lower for word in ['found', 'discovered', 'revealed']):
            return 'factual_claim'
        elif any(word in claim_text_lower for word in ['opinion', 'believe', 'think']):
            return 'opinion_claim'
        else:
            return 'general_claim'
    
    def _calculate_claim_confidence(self, claim_text: str, entities: List) -> float:
        """Calculate confidence level for a claim"""
        # Simple confidence based on length and entity count
        text_length_factor = min(len(claim_text) / 100.0, 1.0)
        entity_factor = min(len(entities) / 5.0, 1.0)
        
        return (text_length_factor + entity_factor) / 2.0
    
    def _verify_claim(self, claim_text: str) -> str:
        """Simple claim verification (placeholder for real implementation)"""
        # In production, this would call actual fact-checking APIs
        suspicious_keywords = ['fake', 'hoax', 'conspiracy', 'unverified']
        if any(keyword in claim_text.lower() for keyword in suspicious_keywords):
            return 'disputed'
        else:
            return 'verified'
    
    def _simulate_news_search(self, query: str) -> List[Dict]:
        """Simulate news API search results"""
        # This is a placeholder - in production, call real news APIs
        return [
            {
                'title': f'Article about {query}',
                'source': 'Simulated News Source',
                'url': 'https://example.com/article',
                'published_at': datetime.utcnow().isoformat(),
                'relevance_score': 0.8
            }
        ]
    
    def _sentiment_label(self, score: float) -> str:
        """Convert sentiment score to label"""
        if score > 0.1:
            return 'positive'
        elif score < -0.1:
            return 'negative'
        else:
            return 'neutral'
    
    def _calculate_credibility_score(self, claims_count: int, fact_checks_count: int, 
                                    news_count: int, sentiment_score: float) -> float:
        """Calculate overall credibility score"""
        # Weighted factors
        claims_factor = min(claims_count / 10.0, 1.0)  # More claims = potentially less credible
        fact_check_factor = min(fact_checks_count / 5.0, 1.0)  # More fact checks = more credible
        news_factor = min(news_count / 3.0, 1.0)  # More news sources = more credible
        sentiment_factor = 1.0 - abs(sentiment_score)  # Neutral sentiment = more credible
        
        weights = [0.25, 0.35, 0.25, 0.15]
        score = (
            claims_factor * weights[0] +
            fact_check_factor * weights[1] +
            news_factor * weights[2] +
            sentiment_factor * weights[3]
        )
        
        return min(max(score, 0.0), 1.0)
    
    def _calculate_context_confidence(self, claims_count: int, fact_checks_count: int, 
                                    entities_count: int) -> float:
        """Calculate overall confidence in context analysis"""
        # More data points = higher confidence
        claims_confidence = min(claims_count / 5.0, 1.0)
        fact_check_confidence = min(fact_checks_count / 3.0, 1.0)
        entity_confidence = min(entities_count / 10.0, 1.0)
        
        confidence = (claims_confidence + fact_check_confidence + entity_confidence) / 3.0
        return min(max(confidence, 0.0), 1.0)