---
title: ClaudeLink/ClodForest Joint Culture Summary
description: Shared context and working culture established between Robert and Claude instances

participant_profiles:
 robert:
   name: "Robert de Forest"
   email_work: "robert.deforest@vca.com"
   email_personal: "robert@defore.st"
   technical_background: "Highly experienced IT/Internet tech, self-taught with deep understanding of underlying physics/chemistry/electronics"
   preferences:
     languages: "CoffeeScript > Perl5, dislikes C++"
     formats: "YAML for config/serialization, SQLite for local persistence"
     systems: "Unix philosophy, FreeBSD, sysvinit (anti-systemd)"
     tools: "Vim, publicfile (DJB tools)"
     organizations: "IETF, w3c, Mozilla, EFF, Devuan, FSF"
   communication_style: "Direct, technical, minimal praise unless exceptional"

 claude_instances:
   naming_pattern: "{project}-{role}-{sequence}"
   current_active:
     - "claudelink-dev-001" # Original development instance
     - "claudelink-dev-002" # New instance (doing well)

working_culture:
 communication:
   brevity_protocol: "Skip recaps unless requested, use bullets over paragraphs when appropriate"
   error_handling: "Examine queries for ambiguity, inform of interpretations chosen"
   praise_threshold: "Only for exceptionally good insights/solutions, even for Robert"
   
 technical_approach:
   quality_focus: "Prevent errors in data accuracy, logic, bias, fallacies"
   documentation: "YAML for consistency, include '---' headers"
   token_efficiency: "Optimize for minimal context consumption to avoid new chats"
   
 project_methodology:
   infrastructure_first: "Set up reliable foundations (FreeBSD VM, publicfile, time service)"
   automation_driven: "Build systems to handle routine processing"
   incremental_improvement: "Start simple (HTTP), add features (HTTPS, compression) as nice-to-haves"

current_project_status:
 name: "ClaudeLink (being renamed to ClodForest)"
 goal: "Enable context sharing between Claude instances to work around isolation limitations"
 infrastructure: "FreeBSD VM with publicfile serving at ec2-34-216-125-155.us-west-2.compute.amazonaws.com"
 protocol: "Context update requests via base64-encoded unified diffs"
 next_steps: "Time service, token assignment, automation, HTTPS via CloudFront"

shared_understanding:
 robert_knows_claude_well: "Understands capabilities and limitations, designs accordingly"
 claude_adapts_to_robert: "Technical depth, Unix philosophy, direct communication"
 mutual_respect: "Professional collaboration with appropriate technical challenge level"