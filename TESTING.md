# Testing Documentation - SIH 2026 Telemetry App

This document outlines standard verification and testing scenarios designed to validate local operations, database correctness, sync status handling, and UI response under diverse states.

## 1. Normal Case Handling
- **Objective**: Ensure that a valid, standard reading saves locally, updates statistics instantly, and tries to sync in the background.
- **Steps**:
  1. Open **Capture Screen**.
  2. Input: Ward A, ValveState: "OPEN", Flow rate: "350.5 Litres", Device ID: "DEV-101".
  3. Save Reading.
- **Expected Results**:
  - Locally stored in the `sqflite` database.
  - Active status set to `pending` (if offline) or auto-synced to `synced` (if online).
  - Total Readings count incremented on dashboard stats.
  - Interactive distribution bar charts on the dashboard update immediately.

## 2. Offline Mode Queueing
- **Objective**: Verify offline-first resiliency when network connection is severed.
- **Steps**:
  1. Toggle Simulated network state to **OFFLINE** on the top banner.
  2. Capture a manual entry (e.g. Ward B, 210L).
  3. Return to the dashboard.
- **Expected Results**:
  - Banner color updates to red ("Offline Mode: Telemetry queued locally").
  - Reading is inserted successfully into local storage with state `pending`.
  - Pending count KPI increases.
  - No network exception crashes the UI.

## 3. Extreme High Value Handling
- **Objective**: Detect water pipe bursts or device sensor issues.
- **Steps**:
  1. Capture a reading with `flow_litres = 14500` Litres.
  2. Save and review dashboard statistics.
- **Expected Results**:
  - Reading is flagged as **Faulty / Anomaly** (indicated with red border highlight on tiles and warnings).
  - "Faulty / Anomaly" metric KPI increases.

## 4. Missing/Null Value Scenario
- **Objective**: Ensure sensor telemetry missing reports are handled properly without formatting exceptions.
- **Steps**:
  1. Open Capture Screen.
  2. Check the "Simulate Missing / Nil Reading" checkbox (flow text field disappears).
  3. Save Reading.
- **Expected Results**:
  - Record is safely stored with null in the database.
  - List views display "Missing" without crashing the render tree.
  - Handled as a faulty node reading in general statistics.

## 5. Network Recovery & Auto-Sync
- **Objective**: Automatically sync queued records when network connectivity resumes.
- **Steps**:
  1. Toggle simulated network state back to **ONLINE**.
- **Expected Results**:
  - Auto-sync triggers inside `SyncService`.
  - Background task pushes queued items to Mock API server DB.
  - Status transitions from `pending` -> `synced` on success.
  - Pending sync KPI returns to 0.

## 6. Retry Failed Uploads
- **Objective**: Ensure temporary connection drops during sync mark statuses as `failed` for automatic recovery retries on subsequent passes.
- **Steps**:
  1. Artificially fail requests (handled inside mock API simulation layer).
  2. Sync is attempted.
- **Expected Results**:
  - Unsuccessful records updated with `failed` sync status.
  - The next automatic sync pass or pull-to-refresh will re-attempt uploads without loss of data.

## 7. Duplicate Prevention
- **Objective**: Guarantee no records are double-posted.
- **Steps**:
  - SyncService compares `reading_id` keys in Server DB before pushing.
- **Expected Results**:
  - If a record was partially uploaded but local state update was interrupted, the server ignores duplicates on next transmission.
