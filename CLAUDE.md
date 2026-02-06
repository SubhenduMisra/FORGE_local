# FORGE v4 — Claude Code Instructions

## Routing
- Quick edits (<100 lines) → MacBook (Ollama)
- Heavy code gen → DGX Spark (Qwen3-Coder)
- Architecture/Review → Claude Cloud

## Skills
- `/review` - Run code review
- `/security` - Run security audit

## Nodes
- MacBook: localhost:11434 (Ollama)
- DGX Spark: 192.168.68.135:8000 (vLLM)
- Claude Cloud: Architecture, review
