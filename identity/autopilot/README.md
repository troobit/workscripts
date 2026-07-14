# Windows Autopilot: the moving parts

Windows Autopilot turns an OEM-imaged Windows device into a business-ready,
Intune-managed machine with no imaging infrastructure. This document
structures the moving parts so a reader knows **what to build and where the
official instructions live**; the `graph/` subdirectory holds a
config-as-code skeleton (scaffolding only — see below).

Start here: [Overview of Windows Autopilot](https://learn.microsoft.com/en-us/autopilot/overview).

## 1. Device registration (hardware hash)

Every device must be known to the Autopilot service before OOBE. A device is
identified by its **hardware hash**, captured on the device and uploaded to
the tenant (directly, via CSV import into Intune, or by the OEM/reseller at
purchase time — the preferred route at scale).

- [Windows Autopilot registration overview](https://learn.microsoft.com/en-us/autopilot/registration-overview)
- [Manual registration of devices](https://learn.microsoft.com/en-us/autopilot/manual-registration)
- [Manually register devices (hardware hash capture, `Get-WindowsAutopilotInfo`, CSV import)](https://learn.microsoft.com/en-us/autopilot/add-devices)

Graph surface: [`importedWindowsAutopilotDeviceIdentity`](https://learn.microsoft.com/en-us/graph/api/resources/intune-enrollment-importedwindowsautopilotdeviceidentity?view=graph-rest-1.0)
and its [`import` action](https://learn.microsoft.com/en-us/graph/api/intune-enrollment-importedwindowsautopilotdeviceidentity-import?view=graph-rest-1.0);
registered devices are listed via
[`windowsAutopilotDeviceIdentity`](https://learn.microsoft.com/en-us/graph/api/intune-enrollment-windowsautopilotdeviceidentity-list?view=graph-rest-1.0).

Skeleton: [`graph/Import-AutopilotDevices.ps1`](graph/Import-AutopilotDevices.ps1).

## 2. Deployment profiles

A deployment profile is the set of OOBE behaviours applied to a registered
device: join type (Entra join / hybrid), user-driven vs self-deploying mode,
skipping privacy/EULA pages, naming template, user account type. Profiles
are created in Intune and assigned to device groups (commonly a dynamic
group over the Autopilot `ZTDID`/group tag).

- [Configure Windows Autopilot deployment profiles](https://learn.microsoft.com/en-us/autopilot/profiles)

Graph surface (beta): [`azureADWindowsAutopilotDeploymentProfile`](https://learn.microsoft.com/en-us/graph/api/resources/intune-enrollment-azureadwindowsautopilotdeploymentprofile?view=graph-rest-beta)
and [`windowsAutopilotDeploymentProfileAssignment`](https://learn.microsoft.com/en-us/graph/api/resources/intune-enrollment-windowsautopilotdeploymentprofileassignment?view=graph-rest-beta).

Skeleton: [`graph/New-AutopilotDeploymentProfile.ps1`](graph/New-AutopilotDeploymentProfile.ps1)
with the profile body in [`graph/profiles/standard-user.example.json`](graph/profiles/standard-user.example.json),
assignment in [`graph/Set-AutopilotProfileAssignment.ps1`](graph/Set-AutopilotProfileAssignment.ps1).

## 3. Intune / MDM enrollment

Autopilot hands the device to MDM at the end of OOBE, which only works if
**automatic MDM enrollment** is configured in the tenant: an Intune MDM
authority, Entra ID P1/P2 for auto-enrollment, and the MDM user scope set to
the users who will enrol. This is tenant plumbing that must exist before the
first Autopilot run.

- [Windows device enrollment guide for Microsoft Intune](https://learn.microsoft.com/en-us/intune/device-enrollment/windows/guide)
- [Enable MDM automatic enrollment for Windows](https://learn.microsoft.com/en-us/intune/device-enrollment/windows/enable-automatic-mdm)

## 4. Enrollment Status Page (ESP)

The ESP holds the user at a progress screen until required apps, policies,
and certificates have landed, so nobody gets a half-configured desktop. It
is configured and assigned in Intune, with per-priority profiles and a list
of blocking apps.

- [Windows Autopilot Enrollment Status Page](https://learn.microsoft.com/en-us/autopilot/enrollment-status)
- [Set up the Enrollment Status Page](https://learn.microsoft.com/en-us/intune/device-enrollment/windows/setup-status-page)

## Order of operations

1. Tenant prerequisites: licences, MDM authority, automatic enrollment
   (section 3) — and the Entra groundwork in [`../entra/`](../entra/README.md).
2. Create device groups, deployment profile(s) (section 2) and ESP
   (section 4) and assign both to the groups.
3. Register devices (section 1) — hashes land in the tenant, profiles get
   assigned automatically via group membership.
4. Ship the device: the user unboxes, connects to a network, signs in, and
   Autopilot + ESP do the rest.

## `graph/` — config-as-code skeleton (scaffolding)

Everything under [`graph/`](graph/) is **scaffolding, not working
configuration**: PowerShell scripts against Microsoft Graph with
`<PLACEHOLDER>` values, showing where deployment profiles, device imports,
and assignments live in the Graph API. The scripts are not runnable as-is —
enrolling real devices requires a real tenant with Intune licences (a
human, billing-gated step).

| File | What it scaffolds |
| --- | --- |
| `graph/Import-AutopilotDevices.ps1` | hardware-hash CSV upload (device registration) |
| `graph/New-AutopilotDeploymentProfile.ps1` | deployment profile creation |
| `graph/Set-AutopilotProfileAssignment.ps1` | profile-to-group assignment |
| `graph/profiles/standard-user.example.json` | example user-driven profile body |
