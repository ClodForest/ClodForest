# Agent Calico Project Context

## Project Overview
**Agent Calico** is a feline-themed AI chatbot for VCA/Mars employees to interact with ServiceNow through natural language. Launch target: June 2025.

### Core Problem
VCA employees waste time on non-core tasks like ServiceNow ticket management, password resets, and system navigation. These tasks frustrate staff who want to focus on veterinary medicine, not wrestle with "obtuse interfaces."

### Solution Architecture
- **Primary Interface**: Microsoft Teams integration (Windows app, web, mobile)
- **Initial Scope**: ServiceNow operations only (create, view, update, close tickets)
- **Personality**: Friendly, conversational cat who remembers prior interactions
- **Security Model**: User-scoped access (Calico can only do what the user can do)

## Target Customers
- **Primary**: All VCA/Mars employees using ServiceNow
- **MVP Focus**: Basic ServiceNow interactions (most common use cases)
- **Future Vision**: Cross-platform data integration combining PubMed, hospital records, internal systems

## Business Value Proposition
- **Employee Satisfaction**: Replace frustrating ServiceNow interface with friendly chat
- **Cost Reduction**: Replace $12/incident offshore support with <$0.01 automated resolution
- **Productivity**: Let veterinary professionals focus on animal health, not IT systems

## Product Capabilities

### MVP Features (June Launch)
- View user's tickets with intelligent filtering
- Create new tickets with guided categorization  
- Update existing tickets with comments/status changes
- Security validation (polite refusal for unauthorized access)

### Example Interaction Flow
```
[Agent Calico]: Hello again, Robert! What brings you into my secret hideout under the stairs?

[Robert]: Hi AC. I think I have a service request that has been stuck waiting for something. Can you check please?

[AC]: You got it. I see you have five requests open. Three are awaiting approvals from three different managers. Two of those managers are out of the office...
```

### Future Roadmap
- Integration with HR systems (vacation balances)
- WOOFconnect analytics and content management
- Cross-hospital performance analytics
- Standard operating procedure workflows

## Technical Implementation

### Current Architecture
- Teams bot framework
- ServiceNow API integration
- Context preservation between conversations
- User authentication and authorization

### Documentation Status
- **Complete**: Product vision, user stories, business case
- **In Progress**: Engineering diagrams, implementation guides
- **Needed**: Test plans, service inventory, bottleneck analysis

## Testing Strategy

### Test Matrix Categories
1. **Core ServiceNow Operations** (HIGH priority)
   - Ticket lookup with security validation
   - Ticket updates and commenting
   - New ticket creation with guided workflows

2. **Personality & Communication** (HIGH priority)
   - Brief but friendly responses (2-3 sentences max)
   - Appropriate cat references and warm tone
   - Graceful error handling without technical jargon

3. **Teams Integration** (HIGH/MEDIUM priority)
   - Cross-platform functionality (Windows, web, mobile)
   - Native Teams experience preservation

4. **Error Handling & Resilience** (HIGH/MEDIUM priority)
   - API failure graceful degradation
   - Service interruption communication

## Key Stakeholders
- **Robert de Forest**: Product Manager
- **Kristyn**: Support load analysis and metrics
- **Mark & Brian**: Testing strategy and implementation
- **Catalina**: Project Management (MS Teams coordination)
- **Jamin**: Original visionary and scope expansion planning

## Current Status (June 2025)
- MVP scope defined and documented
- Initial testing framework established
- Stakeholder alignment in progress
- Engineering implementation details pending

## Success Metrics
- Reduction in ServiceNow support calls
- Employee satisfaction improvements
- Cost per incident resolution
- User adoption and engagement rates