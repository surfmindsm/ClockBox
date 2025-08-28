# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClockBox is a comprehensive workforce and attendance management system designed for the Korean market. The project focuses on compliance with Korean labor laws (52-hour workweek), MZ generation management, and hybrid work environments.

## Repository Structure

This is a **monorepo using git submodules** for separate concerns:
- `app/` - Mobile application (submodule: clockbox-app)
- `backend/` - Backend services (submodule: clockbox-backend)  
- `frontend/` - Web frontend (submodule: clockbox-frontend)
- `docs/` - Project documentation and PRDs in Korean
  - `prd/` - Detailed product requirement documents for each feature module
  - `PRD심층분석.md` - Korean market analysis and compliance requirements
  - `compass_artifact.md` - Market research and ROI analysis

## Current Development State

The project is in the **planning/documentation phase**. The submodules are initialized but contain no implementation yet. All PRDs and specifications are complete and should be referenced when implementing features.

## Key System Requirements

### Legal Compliance (Critical)
- **52-hour workweek enforcement**: Real-time monitoring and automatic blocking required
- **2025 Labor Law updates**: 100-day maternity leave, 20-day paternity leave, 18-month childcare leave
- **Wage calculation**: Complex Korean wage system including overtime (1.5x), night (0.5x), holiday (1.5x) rates
- **Data retention**: 3-year attendance records, 1-year access logs
- **Personal data protection**: End-to-end encryption, role-based access control, automatic deletion after retention period

### Core Features (13 modules)
1. Onboarding and getting started
2. Account management  
3. Organization/branch management
4. Role and permission management
5. Employee management
6. Work scheduling (shift patterns: 3-team 3-shift, 4-team 2-shift)
7. Attendance recording (GPS/WiFi-based, multi-location)
8. Leave management
9. Request and approval workflows
10. Reporting and analytics
11. Payroll processing
12. Messaging and notifications (KakaoTalk integration required)
13. Electronic contract management

### Integration Requirements
- **Messaging**: KakaoTalk Business Message API (primary), KakaoWork
- **Calendar**: Google Calendar, Outlook
- **ERP Systems**: 
  - Douzone (limited API, Excel-based transfer common)
  - YoungLimWon (MES integration for manufacturing)
  - SAP Korea HCM (requires specialized middleware)

### Target Market Specifications
- **SMEs**: ₩1.5-3M annual budget, 6-12 month ROI expectation, modular pricing
- **Enterprises**: ₩50M-500M budget, 18-36 month ROI, customization required
- **MZ Generation focus**: Mobile-first design, transparent processes, real-time feedback

## Development Guidelines

### When implementing features:
1. Always reference the corresponding PRD document in `docs/prd/`
2. Consider Korean labor law requirements for any time/attendance features
3. Ensure mobile-first design for all user interfaces
4. Implement proper audit logging for compliance
5. Support both Korean and English languages from the start

### Task Tracking Requirements:
**IMPORTANT**: Always update `docs/tasks/remaining_tasks.md` when working on tasks:
- Mark tasks as completed when finished
- Update progress percentages for each category
- Add any new tasks discovered during development
- Update the "다음 스프린트" section with current priorities
- Keep the total task count and completion rate accurate

This ensures transparency and helps track overall project progress.

### Technology Stack Decisions Pending
The specific frameworks and languages for each component have not been decided. When making technology choices, consider:
- **Mobile app**: Cross-platform support (iOS/Android)
- **Backend**: High-performance for real-time attendance tracking
- **Frontend**: Responsive design supporting desktop and tablet
- **Database**: Must handle 3+ years of attendance data efficiently

## Submodule Management

To work with the full codebase:
```bash
# Initial clone with submodules
git clone --recursive https://github.com/surfmindsm/ClockBox.git

# Update all submodules
git submodule update --init --recursive

# Pull latest changes in submodules
git submodule update --remote --merge
```

## Documentation Standards

- Main system documentation is in Korean to align with the target market
- Code comments and technical documentation should be in English
- User-facing strings must support Korean localization
- API documentation should be bilingual when possible