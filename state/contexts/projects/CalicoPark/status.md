# 🎡 Agent Calico Amusement Park - Project Status

**Version:** 1.0.0  
**Created:** July 17, 2025  
**Context Type:** Project  
**Repository:** Private GitHub repo (Robert-s-work/CalicoPark)  
**Status:** Active Development

## Project Clarification

**AgentCalico vs CalicoPark:**
- **AgentCalico:** VCA enterprise project developed by Arsen Zakarian. Recent status: "thinks he has it working again" - QA testing may start next week, or this may be another delay.
- **CalicoPark:** Robert's experimental architecture project testing ideas about effective LLM usage. Potential AgentCalico substitute if completed before Arsen's production system.

## Repository Locations

**Primary Access Paths:**
- **Laptop:** `/Users/robert/git/github/Robert-s-work/CalicoPark`
- **Desktop:** `/home/robert/git/github/Robert-s-work/CalicoPark`
- **GitHub:** `https://github.com/Robert-s-work/CalicoPark` (private)

**Key Documentation:**
- Main README: `docs/README.md`
- Architecture docs: `docs/` directory
- Configuration: `config/attractions/`

## Project Overview

Agent Calico Amusement Park is a Go-based multi-agent system implementing the "amusement park" architecture pattern where:

- **Visitors** = Individual requests that choose their own Tour through the park
- **Attractions** = Specialized agents focused on domain expertise
- **Transit System** = NATS messaging infrastructure
- **Tour Bus** = User session context managing multiple Visitors

### Key Features
- ✅ Visitor-centric journey control (AI-driven path selection)
- ✅ Universal composability (all Attractions use same interface)
- ✅ Conversational intelligence (centralized through visitor AI)
- ✅ Streaming support (real-time NATS communication)
- ✅ Context awareness ("that ticket" memory works)
- ✅ Graceful failure handling (Information Booth fallback)

## Current Attractions

1. **ServiceNow Attraction** - Ticket operations with intelligent parameter extraction
2. **Agent Calico Personality** - Cat-themed personality layer for responses
3. **Information Booth** - Fallback for unhandled requests

## Tech Stack

- **Language:** Go 1.24+
- **Messaging:** NATS JetStream
- **LLM Integration:** Ollama
- **Protocol:** Protocol Buffers
- **Web Interface:** Built-in Blimp (port 8080)
- **Monitoring:** NATS dashboard (port 8222)

## Development Commands

```bash
# Run demo (auto-starts NATS)
./scripts/demo.sh

# Manual build
go build -o bin/gatekeeper ./cmd/gatekeeper

# Start NATS server
nats-server --port 4222 --http_port 8222 --jetstream

# Health check
curl http://localhost:8080/api/health
```

## Architecture Goals Status

- [x] **Visitor-centric journey control** - Achieved
- [x] **Universal composability** - Achieved  
- [x] **Conversational intelligence** - Achieved
- [x] **Streaming support** - Achieved
- [x] **Async user input** - Achieved
- [x] **Self-describing** - Achieved
- [x] **Context awareness** - Achieved
- [x] **Graceful failure** - Achieved
- [x] **Separation of concerns** - Achieved

## Current Session Focus

*[To be updated when working on specific features or issues]*

## Related Projects

- **Agent Calico** (VCA ServiceNow chatbot) - Uses ServiceNow Attraction
- **ClodForest** - AI coordination infrastructure for development

## Notes

This project represents a novel approach to multi-agent systems where agents (Attractions) focus purely on their domain expertise while AI-powered Visitors handle their own routing and decision-making. The architecture eliminates central routers in favor of intelligent, self-directed request handling.

## Future Enhancements

**Planned Features:**
- **MCP Support:** Both as client and service, converting Attractions into MCP services (microservice model)
- **Additional Attractions:** SharePoint, database query, file operations, email
- **Multi-Park Support:** Different parks for different domains
- **Advanced Analytics:** Tour success rates and optimization
- **Performance Monitoring:** Prometheus/Grafana integration

**Access Pattern:** Use filesystem tools to read/modify code, with primary development occurring in the repository location matching the current system (laptop vs desktop paths above).
