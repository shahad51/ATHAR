# Exception Handling Audit Report

## Requirements vs Current Implementation

### ✅ Requirement 1: Lost Phone Scenario

**Requirement:**
- User can report from another device
- Employee can create report on behalf of user
- Report linked to Reference ID
- User can track report using Reference ID

**Current Implementation:**
✅ **Employee can create reports on behalf of users**
- File: `lib/screens/employee/employee_add_report_screen.dart`
- Employees can submit both lost and found reports with `isCenterSubmitted: true` flag
- Reports are stored in Firestore with employee's userId as submitter

❌ **Missing: Reference ID System**
- Reports use `reportId` but no separate user-facing Reference ID
- No tracking mechanism for users without login
- No public search by Reference ID feature

---

### ⚠️ Requirement 2: Location Permission Denied

**Requirement:**
- Reporting remains available
- Clear warning message shown
- Message: "Matching accuracy and nearby center suggestions will be reduced until location access is enabled."

**Current Implementation:**
✅ **Manual entry fallback exists**
- File: `lib/screens/regular_user/gps_tracking_dialog.dart`
- Users can choose manual entry if GPS denied
- Manual entries stored with `isManualEntry: true` flag

❌ **Missing: Warning messages**
- No persistent warning about reduced accuracy
- No message shown when permission denied during report submission
- No indication of reduced functionality

---

### ⚠️ Requirement 3: Location Permission Changed Later

**Requirement:**
- Detect permission/service status changes automatically
- Preserve previously stored data
- Keep reporting available
- Show clear warning message

**Current Implementation:**
✅ **Reporting continues to work**
- File: `lib/services/gps_service.dart`
- Permission checked before each tracking operation
- Previous data preserved in Firestore

❌ **Missing: Automatic detection**
- No background monitoring of permission changes
- No automatic re-prompting when permission revoked
- No warning message when permission status changes

---

## Summary

### What Works:
1. ✅ Employees can create reports on behalf of users
2. ✅ Manual location entry fallback
3. ✅ GPS permission handling in tracking service
4. ✅ Data preservation in Firestore

### What's Missing:
1. ❌ Reference ID system for tracking without login
2. ❌ Warning messages about reduced accuracy
3. ❌ Automatic permission change detection
4. ❌ Public report tracking interface

---

## Recommended Fixes

### Priority 1: Reference ID System
- Add `referenceId` field to ReportModel (user-friendly format like "ATH-2024-001234")
- Create public tracking screen (no login required)
- Display Reference ID after employee creates report
- Allow search by Reference ID

### Priority 2: Warning Messages
- Add banner/snackbar when GPS permission denied
- Show persistent warning in report screens
- Update UI to indicate reduced functionality

### Priority 3: Permission Monitoring
- Add AppLifecycleState listener
- Check permission status on app resume
- Prompt user if permission was revoked
- Update UI based on current permission status
