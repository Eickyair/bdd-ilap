---
name: read-pdf
description: Extract text content from PDF files using pdftotext or pypdf when the read tool cannot parse PDFs directly
---

## What I do
When the `read` tool fails on a `.pdf` file with "Cannot read pdf", I extract the text content programmatically and return it so you can analyze the document.

## How to use me
Call me when you need to read a PDF but the `read` tool doesn't support PDF input. I will:
1. Detect which extraction tool is available (`pdftotext`, `mutool`, or Python `pypdf`)
2. Extract the text content
3. Return the extracted plain text for further analysis

## Extraction method (fallback priority)
Prefer `pdftotext` (fastest, best layout preservation). Use `pypdf` or `mutool` as fallback.

### With pdftotext (poppler-utils):
```bash
pdftotext -layout /path/to/file.pdf -
```
The `-layout` flag preserves indentation and table structure. The `-` sends output to stdout.

### With Python pypdf:
```bash
python3 -c "
from pypdf import PdfReader
r = PdfReader('/path/to/file.pdf')
for p in r.pages: print(p.extract_text())
"
```

### With mutool:
```bash
mutool draw -F text /path/to/file.pdf
```

## When to use me
- The `read` tool returns "Cannot read pdf (this model does not support pdf input)"
- You need to analyze the textual content of a PDF document
- You are searching for specific sections, keywords, or patterns in a PDF
