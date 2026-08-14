# z/OSMF Workflows

A collection of z/OSMF workflow definitions developed and tested on z/OS 3.1 (z/OSMF V29). Each XML file is a self-contained workflow that can be created in the z/OSMF Workflows task, or via Zowe CLI:

```
zowe zos-workflows create workflow-from-uss-file "my-workflow" \
  --uss-file-path /path/to/workflow.xml --system-name SYSNAME --owner MYUSER
```

(Upload the XML to USS first, e.g. `zowe zos-files upload file-to-uss-file local.xml /u/myuser/local.xml`.)

## Workflows

### security/

| Workflow | ID | Steps | Purpose |
|---|---|---|---|
| [keyring_audit.xml](security/keyring_audit.xml) | `keyring-audit` | listKeyring, auditExpiry, captureToDataset (optional) | Audits every certificate in a RACF keyring and flags certificates expiring within N days. |
| [racdcert_list.xml](security/racdcert_list.xml) | `racdcert-list` | racdcertList | Lists RACF certificates, keyrings, and certificate chains for the IZUSVR server ID. |
| [password_interval_report.xml](security/password_interval_report.xml) | `password-interval-report` | listGroupMembers, generateReport, captureToDataset | Reports password expiry for all service IDs in a RACF group using IRRXUTIL. |
| [dormant_id_cleanup.xml](security/dormant_id_cleanup.xml) | `dormant-id-cleanup` | confirmGroup, dormantReport, approvalGate, revokeDormantIDs, captureAudit (optional) | Finds IDs in a RACF group inactive for more than N days, reports them, and — after a mandatory manual approval step — revokes them. Requires the [DORMANT](rexx/DORMANT.rexx) exec (see below). |

**Dependency:** `dormant-id-cleanup` calls the [`rexx/DORMANT.rexx`](rexx/DORMANT.rexx) exec, which must be installed in the PDS named by the workflow's `REXX_DATASET` variable (default `ANDRE.REXX.EXEC`), member `DORMANT`. It reads group membership and each member's `LAST-ACCESS` date via `LISTGRP`/`LISTUSER`, classifies IDs as ACTIVE / DORMANT / NEVER-USED / ALREADY-REVOKED, and in `REVOKE` mode issues `ALTUSER ... REVOKE`. Report mode is read-only. Upload with `zowe zos-files upload file-to-data-set rexx/DORMANT.rexx "ANDRE.REXX.EXEC(DORMANT)"`.

### jes/

| Workflow | ID | Steps | Purpose |
|---|---|---|---|
| [purge_spool_jobs.xml](jes/purge_spool_jobs.xml) | `purge-spool-jobs` | listJobs, purgeJobs | Purges all jobs from the JES2 spool that match a given owner and are in the print queue. |

### datasets/

| Workflow | ID | Steps | Purpose |
|---|---|---|---|
| [pdsmanagement.xml](datasets/pdsmanagement.xml) | `pds-management` | createPDS | Create and manage PDS datasets. |
| [vsam-create.xml](datasets/vsam-create.xml) | `vsam-create` | define-ksds, verify-ksds, delete-ksds (optional) | Creates a VSAM KSDS cluster with IDCAMS and verifies it with LISTCAT. Uses [vsam-define.template](datasets/vsam-define.template) as the IDCAMS job template. |

### utilities/

| Workflow | ID | Steps | Purpose |
|---|---|---|---|
| [amblist-listload.xml](utilities/amblist-listload.xml) | `amblist-listload` | runAmblist | Runs AMBLIST LISTLOAD of load module AXRINPVT from SYS1.LINKLIB. |

### zosmf-diagnostics/

| Workflow | ID | Steps | Purpose |
|---|---|---|---|
| [liberty_dump.xml](zosmf-diagnostics/liberty_dump.xml) | `liberty-server-dump` | verifyLiberty, generateDump, verifyDump | Generates a Liberty server dump for z/OSMF diagnostics. |
| [rest-inventory.xml](zosmf-diagnostics/rest-inventory.xml) | `rest-inventory` | getInfo, deriveNames, submitProbe, writeReport | Self-inventory of the z/OSMF instance using `rest` and `setVariable` step types. |

### examples/

| Workflow | ID | Steps | Purpose |
|---|---|---|---|
| [workflow-script-examples.xml](examples/workflow-script-examples.xml) | `script-examples` | six steps: inline REXX, REXX from dataset, inline shell, shell from file, advanced REXX, advanced shell | Tutorial workflow demonstrating REXX and shell script steps with variable passing between steps. |

### zowe/

| Workflow | ID | Steps | Purpose |
|---|---|---|---|
| [api-mediation-probe.xml](zowe/api-mediation-probe.xml) | `api-mediation-probe` | probeGateway, probeDiscovery, probeCatalog, deriveStatus, writeHealthReport | Probes the Zowe API Gateway, Discovery Service, and API Catalog via REST calls; captures HTTP status codes and service/tile counts; writes a consolidated health report and fails the workflow if any service is not HTTP 200. |
| [git-to-pds-sync.xml](zowe/git-to-pds-sync.xml) | `git-to-pds-sync` | gitPull, zoweUpload, iebUpdteFallback (optional), reportSync | Pulls a USS git repository to a chosen branch then uploads all files in a source subdirectory to a PDS as members via Zowe CLI, with an IEBUPDTE-based fallback if Zowe CLI is unavailable. Sync report is written to a USS log file and surfaced on the JES spool. |

## Notes on provenance and encoding

- Source: `/z/andre` on the ZOS31 test system. All files are stored here as UTF-8 with the XML declarations matching.
- The source system held three copies of `racdcert-list` differing only in file encoding/tagging (one of them mis-tagged as ISO8859-1 over EBCDIC bytes); their content is identical and a single clean copy is kept here.
- Two copies of `password-interval-report` existed on the source system; the copy referencing `workflow_v1.xsd` is kept, as the content is otherwise identical.
- `pdsmanagement.xml` originally declared `encoding="IBM-1047"`; the declaration was corrected to UTF-8 to match this repository's encoding.
- When uploading these back to USS, tag the files (`chtag -tc ISO8859-1` or upload as binary and leave untagged consistently) — mixed/incorrect tagging is the most common reason a workflow XML fails to parse in z/OSMF.
