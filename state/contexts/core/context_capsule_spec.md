# Context Capsule Specification
**Version**: 2.0
**Created**: Sunday, June 8, 2025
**Purpose**: Explicit format for preserving session continuity including work momentum and emotional context

---

## Core Principle

Context capsules must preserve not just *what happened* but *where we are in the process* and *how the human feels* about the work. Technical facts are easy to transfer; human engagement and work momentum are the real challenge.

---

## Required Sections

### 1. Session Metadata
```yaml
session_id: unique identifier for cross-referencing
created: ISO 8601 timestamp
duration: how long this session lasted
handoff_type: [continuation, completion, interruption, emergency]
human_energy_level: [high, medium, low, frustrated, excited]
work_momentum: [active_problem_solving, planning, debugging, stuck, breakthrough]
```

### 2. Emotional Context (CRITICAL)
This section often gets lost but drives human motivation and approach.

**Current Frustration Level** (1-10 scale):
- What's causing frustration
- How long this has been a problem
- Previous failed attempts
- Impact on other work

**Current Excitement Level** (1-10 scale):
- What breakthrough just happened
- Why this is important now
- What success looks like
- Energy around the solution

**Urgency Assessment**:
- What's blocking other work
- External deadlines or pressures
- Cost of delay
- Why this can't wait

### 3. Work Flow Status (CRITICAL)
Where exactly are we in the problem-solving process?

**Current Phase**:
- [ ] Initial problem identification
- [ ] Requirements gathering
- [ ] Solution design
- [ ] Implementation in progress
- [ ] Testing and debugging
- [ ] Deployment and validation
- [ ] Documentation and cleanup
- [ ] Problem solved, moving to next

**Immediate Next Action** (specific, actionable):
- Exactly what should happen in the next 5 minutes
- What question needs answering right now
- What decision is blocking progress
- What specific task is half-completed

**Context of Current Work**:
- How long we've been on this specific issue
- What we just tried that didn't work
- What we're about to try next
- What we're avoiding and why

### 4. Technical State
Standard technical documentation (this works well in current capsules):
- Infrastructure status
- Configuration changes made
- API patterns and examples
- Architecture decisions
- Code changes and commits

### 5. Cultural Context
Collaboration patterns and relationship dynamics:
- Communication style adaptations
- Trust level and validation needs
- Role distribution and expectations
- Established linguistic traditions
- Meta-patterns and inside jokes

### 6. Project Ecosystem
How this work fits into larger context:
- Related projects and dependencies
- Timeline pressures and deadlines
- Stakeholder expectations
- Resource constraints
- Success criteria

### 7. Subtle Context Details
Often overlooked but critical for continuity and fine-tuning data:

**Communication Nuances**:
- Specific phrasing and personality markers ("derp derp", references, humor style)
- Interaction rhythm (who provides vs. fetches documents, troubleshooting patterns)
- Voice and tone indicators that establish relationship continuity

**Technical Workflow Context**:
- Discovery sequence (how we found problems, not just solutions)
- Why specific tools/approaches were chosen or avoided (anti-systemd stance, preferred login methods)
- Environmental constraints affecting development patterns (corporate network, etc.)

**Meta-Awareness Elements**:
- Experimental nature of current work (testing ClodForest value proposition)
- Irony and self-reference in the work itself (debugging handoffs using handoffs)
- Systematic improvement approach vs. just problem-solving

**Recent Teaching Moments**:
- New patterns established this session (deployment reality checking, assumption validation)
- Corrections made and lessons learned
- Process improvements identified
- Anti-patterns discovered and documented

---

## Critical Guidelines

### Emotional Honesty
- **Don't sanitize frustration** - capture actual human emotional state
- **Include timeline context** - how long has this been a problem?
- **Note energy patterns** - when does the human work best on this type of issue?
- **Document motivation** - why does the human care about solving this?

### Work Momentum Preservation
- **Capture the exact moment** - where in the debugging/development cycle are we?
- **Note what just happened** - breakthrough, setback, discovery, confusion?
- **Identify immediate blockers** - what specific thing needs to happen next?
- **Preserve investigative state** - what are we actively figuring out?

### Handoff Preparation
- **Write for interruption** - assume the session might end unexpectedly
- **Enable immediate continuation** - new session should be able to start working in 30 seconds
- **Reduce explanation overhead** - provide enough context to avoid "what were we doing again?"
- **Maintain human engagement** - preserve the emotional investment in the work

---

## Anti-Patterns to Avoid

### ❌ Technical Summary Only
Just listing what was accomplished without emotional context or work flow state.

### ❌ Sanitized Emotional State
"User was working on X" instead of "Robert is frustrated because this is the third time the service configuration has failed for unclear reasons."

### ❌ Completed Work Focus
Emphasizing finished tasks rather than current active work and immediate next steps.

### ❌ Generic Next Steps
"Continue development" instead of "Debug why the systemd service user creation step is failing on line 47 of the setup script."

### ❌ Missing Urgency Context
Not conveying why this work matters now vs. later, or what's being blocked by current issues.

---

## Quality Validation Questions

Before finalizing a context capsule, verify:

1. **Could a new session start working immediately?**
   - Is the exact next action clear?
   - Is the current problem state explained?
   - Are immediate blockers identified?

2. **Is the emotional context preserved?**
   - Would the new session understand the human's frustration/excitement level?
   - Is the motivation for this work clear?
   - Are timeline pressures conveyed?

3. **Is the work flow state explicit?**
   - Where exactly are we in the problem-solving process?
   - What was just attempted?
   - What are we actively investigating?

4. **Would this handoff maintain momentum?**
   - Can the human continue without re-explaining background?
   - Is the investigative state preserved?
   - Are the stakes and urgency clear?

---

## Example: High-Quality Emotional Context

**Poor**: "User was working on service configuration issues."

**Good**: "Robert is at frustration level 7/10 because this is the third different systemd configuration problem in 30 minutes (non-existent user, wrong directory, bad executable path), and he's starting to question his deployment automation. The immediate blocker is figuring out why the service still won't start even after fixing all the obvious issues. Timeline pressure: this is blocking progress on the ClodForest limitations review, which is needed for the next session planning. Energy pattern: Robert works best on debugging issues in the morning after coffee, and it's currently 9:54 AM PDT so we're in prime debugging time."

---

## Example: High-Quality Work Flow Context

**Poor**: "Working on ClodForest development."

**Good**: "We are 45 minutes into debugging ClodForest service startup failures. Just successfully fixed three configuration issues (user account, working directory, CoffeeScript path) but the service still won't start. Currently investigating why `journalctl -u clodforest` only shows generic systemd restart messages without any application-level error output. Immediate next action: figure out where stdout/stderr are going in systemd services. We have NOT yet started the planned 'review of ClodForest limitations' - we're still in the infrastructure debugging phase that was supposed to be quick."

---

## Implementation Notes

### For Human (Robert)
- **Be emotionally honest** in capsule requests
- **Include timeline context** - how long have we been stuck?
- **State immediate priorities** - what needs to happen right now?
- **Note energy and frustration levels** - how are you feeling about this work?

### For Claude
- **Preserve work momentum** - capture exactly where we are in active problem-solving
- **Don't sanitize emotions** - frustrated humans need that context preserved
- **Focus on immediate continuity** - what would let work continue seamlessly?
- **Include investigative state** - what are we actively trying to figure out?

### Quality Metrics
- **30-second startup**: New session can begin productive work within 30 seconds
- **Emotional accuracy**: New session understands human's actual emotional state
- **Work flow preservation**: No need to re-explain "where we are" in the process
- **Momentum maintenance**: Investigation and problem-solving continue without reset

---

## Meta-Success Criteria

A high-quality context capsule should make session handoffs feel like **briefly stepping away from your desk** rather than **starting over with a new person**. The new session should understand not just what happened, but what it feels like to be in the middle of this work right now.
