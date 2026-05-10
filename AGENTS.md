# COMP0008 Arena

A study-aid project for the UCL module **COMP0008 — Computer Architecture and Concurrency**. The aim is to equip an agent (you) with the full context of this module so it can carry out any task that draws on it.

## About the module

COMP0008 provides a working knowledge of the hardware and architecture of a modern computer system, with particular focus on concurrency aspects and those that have an impact on writing multithreaded software.

The module is delivered over **10 weeks**, split 5/5 between **architecture** and **concurrency**:

- **Computer architecture** — micro-architecture of a pipelined processor, the memory hierarchy, cache structure / coherence / consistency, hardware multithreading, and **MIPS assembly** (used to ground the low-level discussion of concurrency, e.g. spin locks).
- **Concurrency** — the concurrency abstraction and how it shapes both architecture and software design; safety properties (interference, visibility) and liveness; the **Java Memory Model**; building correct multithreaded systems in Java, from low-level primitives up to the high-level patterns in the `java.util.concurrent` package.

Learning outcomes (paraphrased): understand modern computer architecture (pipelining, memory hierarchy, caches) as it pertains to concurrent programming; read and write MIPS assembly; reason about high-level concurrency safety and liveness; build safe, reliable multithreaded systems in Java with knowledge transferable to other languages.

## Layout

- `materials/` — **the default reading bundle.** Everything needed for general module knowledge. Sized to fit in one context window. See "Default behaviour" below.
- `meta/` — workflows and conventions for tasks that maintain or extend the project itself (see "Meta tasks" below).
- There may be loose files at the root level. Without specific instructions, there is no need to proactively read them.

## Default behaviour

`materials/` is **mandatory context** — read every file in it in full at session start. The only exception is when the task at hand is clearly a **meta task** (see below) and so does not draw on the module content.

## Meta tasks

Some tasks maintain or extend the project itself rather than draw on the module content — transcribing new slide decks, expanding the `materials/` bundle, refining indexes, and so on. Workflows and conventions for these **meta tasks** live in `meta/README.md`.
