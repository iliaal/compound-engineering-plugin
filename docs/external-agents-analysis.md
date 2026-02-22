# External Agents Analysis: awesome-claude-code-subagents

**Date**: 2026-02-22
**Source**: `~/ai/awesome-claude-code-subagents/categories/`
**Compared against**: compound-engineering-plugin agents + ai-skills

## MAJOR (1)

| External Agent | Overlaps With | Issue |
|---|---|---|
| **typescript-pro** | kieran-typescript-reviewer + nodejs-backend | Advanced type patterns (conditional/mapped/template literal) directly conflict with "Duplication > Complexity" philosophy |

## MODERATE — Skip (9)

| External Agent | Overlaps With | Why Skip |
|---|---|---|
| **debugger** | debugging skill + bug-reproduction-validator | Existing system more structured (Iron Law, Three-Fix Threshold, Competing Hypotheses) |
| **devops-engineer** | terraform skill + deployment-verification-agent | Generalist creates source-of-truth ambiguity with specialized existing tools |
| **javascript-pro** | kieran-typescript-reviewer + nodejs-backend | Conflicts with TypeScript-first philosophy |
| **react-specialist** | react-frontend skill | Near-total overlap on state management, SSR, performance, concurrent features |
| **python-pro** | kieran-python-reviewer + python-services | Poetry vs uv, mypy vs ty tooling conflicts |
| **php-pro** | php-laravel skill | DDD vs "fat models/thin controllers" architecture conflict |
| **terraform-engineer** | terraform skill | Naming/convention conflicts likely (underscores, file naming, block ordering) |
| **backend-developer** | nodejs-backend + python-services + php-laravel | Generalist conflicts with per-language specific conventions |
| **typescript-pro** | kieran-typescript-reviewer + nodejs-backend | Advanced types conflict with Duplication > Complexity (MAJOR) |

## MODERATE — Merge Selectively (3)

### deployment-engineer
- **Adds**: CI/CD pipeline design, GitOps workflows, release orchestration, artifact management
- **Duplicates**: Rollback procedures, feature flags, post-deploy monitoring
- **Action**: Import CI/CD design capabilities only, defer Go/No-Go verification to existing `deployment-verification-agent`

### laravel-specialist
- **Adds**: Livewire, Inertia, Horizon, API resources depth, event broadcasting
- **Duplicates**: Eloquent, queues, Pest testing, Sanctum auth
- **Action**: Add Livewire/Inertia/Horizon coverage to existing `php-laravel` skill or as a separate reference, skip duplicated sections

### security-engineer
- **Adds**: Infrastructure/cloud security, container security, zero-trust architecture, secrets management (Vault), compliance automation, DevSecOps pipelines
- **Duplicates**: Vulnerability management, secrets management, compliance
- **Action**: Import as infra-security agent/skill scoped to infrastructure concerns, explicitly defer application security to existing `security-sentinel`

## CLEAN — No Overlap (2)

### accessibility-tester
- **Coverage**: WCAG 2.1/3.0, screen reader compatibility, keyboard navigation, ARIA, mobile a11y, cognitive a11y, form accessibility
- **Gap filled**: No accessibility agent or skill exists in either repo
- **Action**: Can import directly

### cloud-architect
- **Coverage**: AWS/Azure/GCP multi-cloud, Well-Architected Framework, cost optimization, disaster recovery, migration strategies, serverless, landing zones
- **Gap filled**: `terraform` skill covers IaC only, no cloud architecture coverage
- **Action**: Can import directly

## Conflict Details

### Poetry vs uv (python-pro)
- External: recommends Poetry for package management
- Existing `python-services` skill: prescribes **uv** as the standard
- Direct tooling conflict

### mypy vs ty (python-pro)
- External: recommends mypy strict mode
- Existing `python-services` skill: prescribes **ty** (Astral, faster) as replacement
- `kieran-python-reviewer` allows both ("use `ty` or `mypy`")

### DDD vs Fat Models (php-pro)
- External: mentions DDD/Repository/CQRS architecture
- Existing `php-laravel` skill: prescribes "Fat models, thin controllers" with service classes
- Genuine architectural philosophy conflict

### Advanced Types vs Simplicity (typescript-pro)
- External: pushes conditional types, mapped types, template literal types, type-level programming
- Existing `kieran-typescript-reviewer`: "Simple, duplicated code is BETTER than complex DRY abstractions"
- Philosophy conflict on type complexity ceiling
