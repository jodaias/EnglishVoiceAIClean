# Learning SQLite Schema

## Scope

This document describes the Sprint 0 local data layer for the Duolingo-style reading/listening module.

## Database

- Name: learning_path_v1.db
- Engine: SQLite via sqflite
- Current version: 1

## Tables

1. learning_units

- id (TEXT, PK)
- title_en (TEXT)
- title_pt (TEXT)
- icon_asset (TEXT)
- order_index (INTEGER)
- difficulty (TEXT)

2. lessons

- id (TEXT, PK)
- unit_id (TEXT, FK -> learning_units.id)
- order_index (INTEGER)

3. exercises

- id (TEXT, PK)
- lesson_id (TEXT, FK -> lessons.id)
- type (TEXT)
- difficulty (TEXT)
- content_json (TEXT)

4. unit_progress

- unit_id (TEXT, PK, FK -> learning_units.id)
- is_unlocked (INTEGER 0/1)
- crowns (INTEGER)

5. lesson_progress

- lesson_id (TEXT, PK, FK -> lessons.id)
- unit_id (TEXT, FK -> learning_units.id)
- is_completed (INTEGER 0/1)
- best_score (INTEGER)
- xp_earned (INTEGER)
- completed_at (TEXT, ISO-8601)
- attempts (INTEGER)

6. user_stats

- id (INTEGER, PK, singleton = 1)
- total_xp (INTEGER)
- available_hearts (INTEGER)
- hearts_refill_at (TEXT, ISO-8601 nullable)
- streak_days (INTEGER)
- last_completed_date_key (TEXT nullable)

7. review_queue

- exercise_id (TEXT, PK, FK -> exercises.id)
- due_at (TEXT, ISO-8601)
- interval_days (INTEGER)
- last_reviewed_at (TEXT, ISO-8601 nullable)
- fail_count (INTEGER)

## Indexes

- idx_learning_units_order
- idx_lessons_unit_order
- idx_exercises_lesson
- idx_lesson_progress_unit
- idx_review_queue_due_at

## Migrations

- Version 1: creates full schema and runs initial seed.
- Upgrade policy: incremental migration blocks by version in AppDatabase.\_runMigrations.

## Seed

- Source: LessonContentCatalog
- Initial data:
  - 2 units
  - 6 lessons
  - 36 exercises
- Also initializes:
  - unit_progress rows
  - lesson_progress rows
  - user_stats singleton row

## Notes

- content_json stores polymorphic exercise payloads as JSON for type flexibility.
- DAOs are pure wrappers around Database and support in-memory tests.
- LocalLearningApiService depends on DAOs only, allowing future swap to remote API implementation.
