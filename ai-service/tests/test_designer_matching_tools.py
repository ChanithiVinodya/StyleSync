import httpx
import pytest
from app.schemas import (
    DesignerAvailabilityResponseDto,
    DesignerSearchResultDto,
    MatchScoreBreakdownDto,
)
from app.tools import (
    DESIGNER_MATCHING_TOOLS,
    check_designer_availability,
    search_designers,
)


def test_designer_matching_tools_allow_list():
    tool_names = [t.name for t in DESIGNER_MATCHING_TOOLS]
    assert len(tool_names) == 2
    assert "search_designers" in tool_names
    assert "check_designer_availability" in tool_names
    assert "calculate_scope_estimate" not in tool_names
    assert "validate_budget_boundary" not in tool_names


def test_designer_search_result_dto_validation():
    raw_payload = {
        "designerId": 12,
        "matchScore": 0.88,
        "scoreBreakdown": {
            "styleTagOverlapPct": 1.0,
            "budgetRangeOverlapPct": 0.9,
            "pastRatingNormalized": 0.96,
            "availabilityBonus": 1.0,
            "matchScore": 0.88,
        },
        "displayName": "Amara Silva",
        "bio": "Expert in contemporary minimalism",
        "styleTags": ["Minimalist", "Scandinavian"],
        "serviceCategories": ["Residential", "Commercial"],
        "priceRangeMin": 100000.0,
        "priceRangeMax": 400000.0,
        "ratePerSqFt": 250.0,
        "isAvailable": True,
        "maxConcurrentProjects": 4,
        "activeProjectCount": 1,
        "remainingCapacity": 3,
        "isUnderCapacity": True,
        "averageRating": 4.8,
        "listingStatus": 1,
        "featuredPortfolioImageUrl": "https://example.com/img.jpg",
    }

    dto = DesignerSearchResultDto.model_validate(raw_payload)
    assert dto.designer_id == 12
    assert dto.match_score == 0.88
    assert dto.display_name == "Amara Silva"
    assert dto.is_under_capacity is True
    assert dto.score_breakdown.style_tag_overlap_pct == 1.0


def test_designer_availability_dto_validation():
    raw_payload = {
        "isAvailable": True,
        "isUnderCapacity": True,
        "activeProjectCount": 2,
        "maxConcurrentProjects": 5,
    }

    dto = DesignerAvailabilityResponseDto.model_validate(raw_payload)
    assert dto.is_available is True
    assert dto.is_under_capacity is True
    assert dto.active_project_count == 2
    assert dto.max_concurrent_projects == 5


def test_search_designers_success(monkeypatch):
    mock_response_data = [
        {
            "designerId": 101,
            "matchScore": 0.92,
            "scoreBreakdown": {
                "styleTagOverlapPct": 1.0,
                "budgetRangeOverlapPct": 0.85,
                "pastRatingNormalized": 0.98,
                "availabilityBonus": 1.0,
                "matchScore": 0.92,
            },
            "displayName": "Elena Rostova",
            "bio": "Minimalist designer",
            "styleTags": ["Scandinavian"],
            "serviceCategories": ["Full Design"],
            "priceRangeMin": 120000.0,
            "priceRangeMax": 300000.0,
            "ratePerSqFt": 300.0,
            "isAvailable": True,
            "maxConcurrentProjects": 3,
            "activeProjectCount": 1,
            "remainingCapacity": 2,
            "isUnderCapacity": True,
            "averageRating": 4.9,
            "listingStatus": 1,
            "featuredPortfolioImageUrl": None,
        }
    ]

    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        return httpx.Response(200, json=mock_response_data, request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    results = search_designers.invoke({
        "style_tags": ["Scandinavian"],
        "budget_min": 100000.0,
        "budget_max": 300000.0,
    })

    assert isinstance(results, list)
    assert len(results) == 1
    assert results[0]["designerId"] == 101
    assert results[0]["matchScore"] == 0.92


def test_search_designers_not_found(monkeypatch):
    def mock_get(self, url, params=None, **kwargs):
        req = httpx.Request("GET", url)
        return httpx.Response(404, request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    results = search_designers.invoke({
        "style_tags": ["NonExistentStyle"],
        "budget_min": 50000.0,
        "budget_max": 100000.0,
    })

    assert isinstance(results, list)
    assert len(results) == 1
    assert "error" in results[0]
    assert "no eligible designers found" in results[0]["error"]


def test_search_designers_connection_error(monkeypatch):
    def mock_get(self, url, params=None, **kwargs):
        raise httpx.ConnectError("Connection refused")

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    results = search_designers.invoke({
        "style_tags": ["Scandinavian"],
        "budget_min": 100000.0,
        "budget_max": 300000.0,
    })

    assert isinstance(results, list)
    assert len(results) == 1
    assert "error" in results[0]
    assert "Failed to connect" in results[0]["error"]


def test_check_designer_availability_success(monkeypatch):
    mock_payload = {
        "isAvailable": True,
        "isUnderCapacity": True,
        "activeProjectCount": 1,
        "maxConcurrentProjects": 3,
    }

    def mock_get(self, url, **kwargs):
        req = httpx.Request("GET", url)
        return httpx.Response(200, json=mock_payload, request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    result = check_designer_availability.invoke({"designer_id": "101"})

    assert result["isAvailable"] is True
    assert result["isUnderCapacity"] is True
    assert result["activeProjectCount"] == 1
    assert result["maxConcurrentProjects"] == 3


def test_check_designer_availability_not_found(monkeypatch):
    def mock_get(self, url, **kwargs):
        req = httpx.Request("GET", url)
        return httpx.Response(404, request=req)

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    result = check_designer_availability.invoke({"designer_id": "999"})

    assert "error" in result
    assert result["isAvailable"] is False
    assert result["isUnderCapacity"] is False


def test_check_designer_availability_http_error(monkeypatch):
    def mock_get(self, url, **kwargs):
        raise httpx.ConnectTimeout("Connection timed out")

    monkeypatch.setattr(httpx.Client, "get", mock_get)

    result = check_designer_availability.invoke({"designer_id": "101"})

    assert "error" in result
    assert result["isAvailable"] is False
    assert "Failed to check designer availability" in result["error"]
