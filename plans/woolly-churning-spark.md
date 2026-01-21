# Google Drive Upload Plan

## Summary
Upload the organized Scarlet Splendour files (784 files, ~12GB) to Google Drive using browser automation.

**Source:** `/Users/raghavbajoria/Desktop/Companies/Scarlet Splendour/File Organisation/Mohit_Organized/`

**Skip:** `_Flagged_For_Review/` folder (empty folders not needed in cloud)

---

## What Will Be Uploaded

| Folder | Files | Size (approx) |
|--------|-------|---------------|
| 01_Projects | 246 | BOQ, Techpacks, Master files |
| 02_Operations | 449 | Despatch, Inventory, Logistics |
| 03_Finance | 28 | Invoices, PI |
| 04_Marketing | 19 | Catalogues, Press, Price Lists (~11GB of ZIPs) |
| 05_Sales | 13 | Leads, Addresses, Exhibitions |
| 06_Reference | 29 | Product catalog, Images |
| **TOTAL** | **784** | **~12GB** |

---

## Upload Approach

### Method: Browser Automation (Chrome)

1. **Open Google Drive** in Chrome browser
2. **Navigate/Create** destination folder for Scarlet Splendour
3. **Upload folders** one category at a time:
   - Start with smaller folders (Finance, Sales, Reference)
   - Then larger folders (Projects, Operations)
   - Finally Marketing (has the large ZIP files)
4. **Verify** uploads completed successfully

### Why Category-by-Category?
- More reliable for large uploads
- Can resume if any issues occur
- Easier to track progress
- Avoids browser timeouts on 12GB single upload

---

## Steps

1. **Get browser context** - Connect to Chrome
2. **User creates Shared Drive** - You'll set up the Shared Drive yourself
3. **User navigates to destination** - Tell me when you're ready
4. **Upload each category** - I'll upload folders one at a time via browser
5. **Verify completion** - Check file counts match (784 files total)

---

## Important Notes

- **I cannot enter passwords** - You'll need to sign in manually if prompted
- **Large files (ZIPs)** - Marketing folder has ~11GB of catalogue ZIPs, may take time
- **Internet speed matters** - Upload time depends on your connection
- **Don't close browser** - Keep Chrome open during upload

---

## Verification
- Compare file counts in Google Drive vs local (784 files)
- Spot check critical folders have correct contents
- Verify folder structure matches local organization
