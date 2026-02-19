---
name: velmios-projects
description: >
  Lists Velmios-related projects under /home/miragecentury/projects/github/laelidona,
  with absolute paths and short summaries to improve cross-project discovery when
  developing, debugging, or reasoning across the Velmios platform.
metadata:
  root_path: /home/miragecentury/projects/github/laelidona
  tags:
    - velmios
    - projects
    - discovery
    - microservices
    - frontend
    - infra
---

# Velmios projects catalog

This skill provides a catalog of Velmios-related projects living under
`/home/miragecentury/projects/github/laelidona`.

It helps an agent quickly find **which repository to open** when working on a
feature, debugging an issue, or exploring how a cross-cutting concern is
implemented across the Velmios platform.

All paths below are absolute, assuming the standard layout on the local
development machine.

## When to use this skill

- Use this catalog when you need to answer questions like:
  - "Where is customer registration implemented?"
  - "Which service sends email or push notifications?"
  - "Which repo contains the public marketing website vs the admin UI?"
- Use it before making cross-service changes (e.g. authentication, notifications,
  payments) to identify **all affected repos**.
- Use it to choose the **most domain-specific repo** when several could be
  related to a feature.

## How to use this catalog

- Map the **problem domain** (customers, auth, notifications, payments, content,
  integrations, infra, etc.) to the closest section below.
- Within a section, choose the project whose description best matches the task,
  then:
  - Open that repo in the IDE.
  - Follow its own documentation and architecture.
- When the task spans multiple concerns (for example, "send notifications on
  customer registration"):
  - Start from the primary domain service (here: `customer_backend`).
  - Then consult the secondary services (here: `notification_backend`,
    integration backends, and relevant frontends).

---

## Core backend services

- **customer_backend** (`/home/miragecentury/projects/github/laelidona/customer_backend`):
  Backend microservice for the **customer domain**, built with Python 3.12,
  FastAPI Factory Utilities, `velmios_core`, and `taskiq-dependencies`. Manages
  customer registration, profiles, and customer-centric business logic. Use this
  repo when working on how customers are onboarded, stored, or manipulated in
  the Velmios ecosystem.

- **notification_backend** (`/home/miragecentury/projects/github/laelidona/notification_backend`):
  Notification microservice built on FastAPI Factory Utilities and Velmios Core.
  Responsible for composing and sending outbound notifications (for example
  email, and possibly other channels) using providers like Mailchimp
  Transactional. Use this service when adapting notification templates, delivery
  logic, or notification workflows triggered by other backends.

- **booking_backend** (`/home/miragecentury/projects/github/laelidona/booking_backend`):
  Backend microservice dedicated to **booking-related** functionality (for
  example reservations or appointments). Built on the same Python/FastAPI
  stack, it encapsulates booking rules, states, and workflows. Choose this
  repository for any feature involving bookings or scheduling.

- **payment_backend** (`/home/miragecentury/projects/github/laelidona/payment_backend`):
  Payment-focused backend responsible for handling charges, payment methods, and
  integration with external payment providers. Use this service when working on
  billing flows, payment capture, or reconciliation logic.

- **content_backend** (`/home/miragecentury/projects/github/laelidona/content_backend`):
  Backend for managing platform **content** (for example articles, posts, or
  structured content used by clients). This service is the right place for
  content storage, retrieval APIs, and associated business rules.

- **content_sync_backend** (`/home/miragecentury/projects/github/laelidona/content_sync_backend`):
  Lightweight backend focused on **synchronizing content** between Velmios and
  external systems. Use this repo when working on background content-sync tasks
  or pipelines rather than the core content CRUD APIs.

---

## Integration backends and tools

- **instagram_integration_backend** (`/home/miragecentury/projects/github/laelidona/instagram_integration_backend`):
  Python backend integrating Velmios with **Instagram** APIs. Responsible for
  ingesting or publishing content, handling webhooks, and managing OAuth tokens
  for Instagram. Use this repo when debugging or extending any Instagram-related
  functionality.

- **tiktok_integration_backend** (`/home/miragecentury/projects/github/laelidona/tiktok_integration_backend`):
  Backend dedicated to **TikTok** integrations. Implements the logic for
  communicating with TikTok APIs, managing authentication, and synchronizing
  TikTok-related data with Velmios. Choose this project for TikTok-centric
  features.

- **youtube_integration_backend** (`/home/miragecentury/projects/github/laelidona/youtube_integration_backend`):
  Microservice for **YouTube** integration. Manages access to YouTube APIs,
  including uploading or retrieving video data and handling channel-related
  operations. Use this backend for any YouTube-specific workflows.

- **instagram_helper_cli** (`/home/miragecentury/projects/github/laelidona/instagram_helper_cli`):
  Helper CLI tooling around Instagram operations, implemented in Python. Useful
  for ad-hoc tasks, maintenance, or experiments around Instagram-related data.

- **velmios_terminal_client** (`/home/miragecentury/projects/github/laelidona/velmios_terminal_client`):
  The **Velmios CLI**, built with Python, Typer, and structured logging. Provides
  command-line access to platform operations (for example interacting with
  Kubernetes via the Python Kubernetes client) and automating operational
  workflows. Use this project when adding or changing CLI commands for working
  with Velmios infrastructure or services.

---

## Frontend applications and clients

- **auth_velmios_io** (`/home/miragecentury/projects/github/laelidona/auth_velmios_io`):
  React 19 frontend using React Router, TanStack Query/Form, Zod, i18next,
  Tailwind CSS, and DaisyUI. Acts as the **authentication-facing UI** (for
  example login/registration flows) for Velmios users. Use this repo when
  modifying auth-related UI, form flows, or internationalization of auth pages.

- **web_administration_application** (`/home/miragecentury/projects/github/laelidona/web_administration_application`):
  React-based **administration interface** for managing Velmios resources and
  configuration. Uses React Router, Ant Design, Tailwind, and Ory client
  libraries to integrate with the auth stack. This is the primary place for
  admin console features, dashboards, and back-office workflows.

- **public_phone_application** (`/home/miragecentury/projects/github/laelidona/public_phone_application`):
  Public-facing React application focused on **phone-oriented** experiences (for
  example mobile-friendly flows or phone number–centric interactions). Built
  with React and the modern React Router stack. Use this repo for changes to
  public phone-related UX.

- **public_site_template_frontend** (`/home/miragecentury/projects/github/laelidona/public_site_template_frontend`):
  Template React frontend for **public sites**, using React Router, Tailwind,
  DaisyUI, and i18next. Serves as a reusable starting point for public-facing
  Velmios sites. Modify this when adjusting shared patterns for public site
  layouts, styling, or localization.

- **public_website** (`/home/miragecentury/projects/github/laelidona/public_website`):
  The main **public marketing website** for Velmios, implemented in React with
  Tailwind and i18next, and deployed via Cloudflare Workers tooling. Use this
  repository when changing marketing pages, SEO, performance tests, or public
  site content.

- **public_fallback** (`/home/miragecentury/projects/github/laelidona/public_fallback`):
  Small fallback configuration/code used for public deployments (for example
  default routes or fallback assets). Typically touched when adjusting
  deployment-level defaults for public web properties.

---

## Shared libraries, knowledge, and dependencies

- **velmios_lib** (`/home/miragecentury/projects/github/laelidona/velmios_lib`):
  The core **Velmios library** (`velmios_core`), implemented in Python 3.12 and
  published as a reusable package. Provides shared entities, types, validation
  logic, authentication/authorization helpers, and integration utilities used
  across Velmios microservices. Start here when defining or updating cross-cutting
  domain concepts or shared abstractions.

- **velmios_knowledge** (`/home/miragecentury/projects/github/laelidona/velmios_knowledge`):
  Knowledge base and documentation repository for the Velmios platform. Contains
  design notes, architecture docs, and other reference material. Use this repo
  when you need conceptual or process documentation rather than executable code.

- **taskiq-dependencies** (`/home/miragecentury/projects/github/laelidona/taskiq-dependencies`):
  Shared Python dependencies and helpers for Taskiq-based async task processing
  used by multiple backends. This project centralizes Taskiq configuration and
  common patterns. Modify it when changing how background jobs or task queues
  are configured across services.

- **e2e-tests** (`/home/miragecentury/projects/github/laelidona/e2e-tests`):
  Repository containing **end-to-end tests** for the Velmios platform, typically
  implemented in Python. Use this repo when adding or updating cross-service
  test scenarios that exercise multiple backends and frontends together.

- **video_cut_analyzer_experimental** (`/home/miragecentury/projects/github/laelidona/video_cut_analyzer_experimental`):
  Experimental Python project for analyzing or processing video cuts. Useful for
  prototyping video-related capabilities that may later be integrated into the
  main platform. Treat this as an experimental playground rather than a core
  service.

---

## GitOps and infrastructure

- **argocd** (`/home/miragecentury/projects/github/laelidona/argocd`):
  Argo CD-related configuration for managing Velmios deployments via GitOps.
  Contains application manifests and configuration tuned for Argo CD. Use this
  repo when adjusting how services are represented and synchronized in Argo CD.

- **velmios-services-gitops** (`/home/miragecentury/projects/github/laelidona/velmios-services-gitops`):
  Central GitOps repository for Velmios services. Holds Kubernetes/Argo
  manifests and service configuration used to deploy and manage the fleet of
  Velmios microservices. This is the main place to change service-level manifests
  that apply across environments.

- **velmios-services-deployer-prd-gitops** (`/home/miragecentury/projects/github/laelidona/velmios-services-deployer-prd-gitops`):
  GitOps configuration focused on **production** deployment of Velmios services.
  Use this repo when altering how services are deployed or managed in the
  production environment.

- **velmios-services-deployer-stg-gitops** (`/home/miragecentury/projects/github/laelidona/velmios-services-deployer-stg-gitops`):
  GitOps configuration for **staging** deployments. Mirrors the production
  deployer but for non-production environments, making it a safe place to refine
  new deployment patterns before promoting them to production.

- **pulimi** (`/home/miragecentury/projects/github/laelidona/pulimi`):
  Infrastructure-as-code repository using **Pulumi** and Python. Manages cloud
  resources and environments programmatically. Choose this repo when adding or
  modifying Pulumi-based definitions for Velmios infrastructure.

---

## Maintenance notes

- When new Velmios projects are added under
  `/home/miragecentury/projects/github/laelidona`, update this catalog by:
  - Adding the project under the most appropriate section (or creating a new
    section if needed).
  - Including its absolute path and a concise summary (purpose, role in the
    platform, tech stack, and notable integrations).
- When a project's role changes significantly (for example a backend is split or
  repurposed), adjust its description here to match the new reality.
- Periodically scan the `laelidona` directory to ensure this list stays in sync
  with the actual set of active Velmios projects.

