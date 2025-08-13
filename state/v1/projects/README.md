# Robert's Projects - Quick Reference

**Updated:**                      July 17, 2025
**Purpose:**                      Quick lookup for projects when Claude hasn't heard of them yet

## 🚀 Active Development Projects

### CalicoPark - Multi-Agent System Architecture
**Location:**                     `/Users/robert/git/github/Robert-s-work/CalicoPark` (laptop) | `/home/robert/git/github/Robert-s-work/CalicoPark` (desktop)
**Type:**                         Go-based multi-agent system using "amusement park" architecture
**Status:**                       Core implementation complete (July 2025), stabilizing before feature expansion
**Key Innovation:**               Visitors (requests) choose their own Tours through specialized Attractions (agents)
**Tech Stack:**                   Go 1.24+, NATS JetStream, Ollama, Protocol Buffers
**Relation to AgentCalico:**      CalicoPark is Robert's experimental architecture; AgentCalico is VCA's production system

### ClodForest - AI Coordination Infrastructure  
**Location:**                     `/Users/robert/git/github/ClodForest/ClodForest`
**Type:**                         Context management and AI collaboration system
**Status:**                       Production OAuth2 DCR implementation complete (July 2025)
**Key Achievement:**              Full RFC 7591 + OAuth 2.1 implementation for Claude.ai integration
**Architecture:**                 OAuth proxy → MCP server → ClodForest contexts
**Current Focus:**                Production deployment, Claude.ai remote access validation

### AgentCalico (VCA Work Project)
**Type:**                         Enterprise ServiceNow/SharePoint chatbot for VCA Animal Hospitals
**Developer:**                    Arsen Zakarian (Tiger Team)
**Status:**                       "Thinks he has it working again" - QA testing may start next week
**Timeline:**                     Soft launch was June 30, 2025 (may be delayed again)
**Robert's Role:**                Product Manager, customer advocacy, testing strategy
**Business Case:**                $12 → $0.10 per ticket cost reduction

## 🔬 Research & Vision Projects

### ClodHearth - Local LLM Fine-Tuning
**Type:**                         Hardware analysis and local AI migration strategy
**Goal:**                         Escape API costs ($1,800-2,400 annually) and throttling limits
**Hardware Target:**              RTX 4090 (24GB VRAM) for DeepSeek-R1:7b fine-tuning
**Philosophy:**                   "Claude's home to grow in" - AI agency development
**Status:**                       Conceptual, hardware analysis complete, awaiting budget approval

### BEM - Bio-Economic Computing Model
**Type:**                         Interdisciplinary research project
**Focus:**                        Intersection of biological computation and economic theory
**Applications:**                 Market simulation, resource allocation, algorithm development
**Approach:**                     Agent-based modeling, swarm intelligence, network dynamics
**Status:**                       Conceptual development and background research phase

### Devtwo - Unix Philosophy OS
**Type:**                         Operating system redesign project
**Trigger:**                      NetworkManager frustration → complete OS rethink
**Philosophy:**                   "The One True Way" - pure Unix principles implementation
**Strategy:**                     Ubuntu base with systematic replacement of non-compliant components
**Status:**                       Architecture defined, networking subsystem replacement planned

## 🎲 Personal Projects

### Ozryn's Keep D&D Campaign
**Type:**                         Ongoing tabletop RPG campaign
**Scope:**                        70,000+ words of comprehensive session documentation
**Party:**                        "The Animals" - Leon, Honey, Oralie, Sveldolos, Baeleth
**Current Arc:**                  Tasha alliance building, breaking Braynor's resurrection cycle
**Unique Features:**              Ship-based adventures, kobold rehabilitation theme
**Session Frequency:**            Bi-weekly

### Thunder Mountain D&D Campaign  
**Type:**                         Beginner-focused tabletop RPG campaign
**Repository:**                   `https://github.com/rdeforest/ThunderMountain`
**Focus:**                        New player introduction, safety-first approach
**Context Location:**             Campaign content lives in separate ThunderMountain repo
**Development:**                  GM confidence building through equipment and technique refinement

## 📋 Project Categories

### **Immediate/Active**
- CalicoPark (architecture experimentation)
- ClodForest (production AI infrastructure)  
- AgentCalico (VCA work commitment)

### **Future/Research**
- ClodHearth (local AI migration)
- BEM (academic research)
- Devtwo (OS development)

### **Personal/Creative**
- Ozryn's Keep (established campaign)
- Thunder Mountain (beginner campaign)

## 🔄 Project Relationships

**ClodForest ↔ CalicoPark:**      Context management supports multi-agent development
**CalicoPark ↔ AgentCalico:**     Experimental architecture vs. production implementation
**ClodForest ↔ ClodHearth:**      Infrastructure enables local AI migration
**Unix Philosophy:**              Consistent approach across Devtwo, ClodForest, CalicoPark
**D&D Campaigns:**                GM experience transfer from Ozryn's Keep to Thunder Mountain

## 🎯 Quick Decision Guide

**"Let's work on Calico Park"**   → Load `contexts/projects/CalicoPark/status.md`
**"AgentCalico update?"**         → Load `contexts/projects/AgentCalico/overview.yaml`
**"ClodForest deployment"**       → Load `contexts/projects/ClodForest/status.md`
**"D&D session planning"**        → Load appropriate campaign contexts
**"Hardware discussion"**         → Load `contexts/projects/clodhearth_hardware_analysis.yaml`

## 💡 Future Enhancements

**For CalicoPark:**
- MCP support (both client and service)
- Attraction → MCP service conversion
- Additional Attractions (SharePoint, database, file ops, email)
- Multi-park support for different domains

**For ClodForest:**
- AWS production deployment
- Persistent database storage
- Rate limiting and HTTPS enforcement

**Cross-Project:**
- Context inheritance system implementation
- Teaching moments integration
- Pattern recognition for repeated lessons
