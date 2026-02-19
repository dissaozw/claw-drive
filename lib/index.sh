#!/usr/bin/env bash
# lib/index.sh — INDEX.md management for Claw Drive
#
# INDEX.md is a structured markdown table designed for direct agent consumption.
# Agents should read the file directly for search/list/tag operations —
# their semantic understanding is strictly better than grep-based search.
#
# This library is reserved for future write operations (update, delete)
# that need atomic index manipulation.
