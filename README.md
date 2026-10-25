# Quick Reference Handbook (QRH)

<img src="./docs/screenshots/iphone-list.png" width="200px">   <img src="./docs/screenshots/iphone-guideline.png" width="200px">   <img src="./docs/screenshots/iphone-callout.png" width="200px">   <img src="./docs/screenshots/iphone-dark-breadcrumb.png" width="200px">

<img src="./docs/screenshots/ipad-guideline.png" width="400px">   <img src="./docs/screenshots/ipad-landscape.png" width="400px">

## Features
- Unofficial derivative of the Association of Anaesthetists Quick Reference Handbook (QRH): [www.anaesthetists.org/Quick-Reference-Handbook](https://www.anaesthetists.org/Quick-Reference-Handbook) (CC BY-NC-SA 4.0)
- ***Not endorsed by the Association of Anaesthetists***
- Rapidly searchable by guideline code, title or full text, with matches highlighted
- Simple guideline layout echoing original handbook
- Clickable links between guidelines with breadcrumbs
- Large-format card view - swipe horizontally through the steps
- iPad layout with guideline list alongside, and boxes in a second column
- Guidelines in Spotlight search and Home Screen quick actions
- Supports dark mode and larger text sizes (follows system settings)
- Option to disable expanding boxes
- Guidelines built in and work offline. No accounts, analytics or adverts (see [privacy policy](PRIVACY.md))
- Easily updatable through modification of JSON asset
- [![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa] Released under same Creative Commons license as original work  
- Android version available at <a href="http://github.com/anaes-dev/qrh-android">github.com/anaes-dev/qrh-android</a>

This application has been neither professionally developed nor tested. It carries no certification markings, regulatory approvals or technical assessment appraisals. Please read full guidance and disclaimers on first launch.


## License
This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0
International License][cc-by-nc-sa].

[![CC BY-NC-SA 4.0][cc-by-nc-sa-image]][cc-by-nc-sa]

[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-image]: https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png
[cc-by-nc-sa-shield]: https://img.shields.io/badge/License-CC%20BY--NC%20SA%204.0-lightgrey.svg
You may distribute original version or adapt for yourself and distribute with acknowledgement of source. 
You may not use for commercial purposes.  

## Download

Available on the App Store:   
<a href='https://apps.apple.com/gb/app/quick-reference-handbook-qrh/id1537247898'><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1605744000&h=39b9465c7f7117e54e77a92b3fc75817" alt="Download on the App Store" width="240px"></a>

Otherwise please build from source (Xcode 26, runs on iOS 17 or later).

## Technical
*(For any updates, modifications or derivatives)*

All guidelines are stored in /qrh/data.json, shared with the Android app.

The file contains 'version', 'copyrightHolders' and 'data' keys:

```json
{
  "version": "3.00",
  "copyrightHolders": {
    "aoa": { "name": "Association of Anaesthetists", "website": "www.anaesthetists.org/qrh" }
  },
  "data": [
    {
      "code": "3-1",
      "title": "Anaphylaxis",
      "version": 5,
      "url": "https://anaesthetists.org/Portals/0/PDFs/QRH/QRH_3-1_Anaphylaxis_v5.pdf",
      "copyright": { "holder": "aoa", "year": 2022 },
      "content": [
        { "type": 3, "head": "...", "body": "...", "step": "1" }
      ]
    }
  ]
}
```

The guideline list is generated from 'data'. 'url' links to the original PDF and 'copyright' refers to a key in 'copyrightHolders'.

Each item in 'content' contains 'type', 'head', 'body' and 'step' keys, plus optional 'branch' and 'table' keys.

These populate different styled cards for each guideline page.

### Card views

Type integer value determines the appearance of the generated card:
1. Introductory text (body only)
2. START text or section banner (body only)
3. Guideline step with bold heading and separate content (head, body and step)
4. Guideline step with single text field (body and step)
5. Orange expanding box (head and body)
6. Blue expanding box (head and body)
7. Green expanding box (head and body)
8. Black expanding box (head and body)
9. Purple expanding box (head and body)
10. Image (caption in head, image name in body)
11. ~~Version text (body only)~~ *(no longer used)*
12. ~~Red disclaimer card (head only)~~ *(no longer used)*
13. Branch heading (body and branch)

Version text, disclaimer and license attribution are added at the end of each guideline automatically.

### Branches

Where a guideline splits (e.g. airway vs non-airway fire), each branch starts with a type 13 card containing the condition in body and an id in 'branch'. Items following it with the same 'branch' id belong to that branch. Consecutive branches are shown side by side where there's room, otherwise one above the other.

On iPad, a box repeated in every branch (identical apart from 'branch') appears once in the side column.

### Tables

Expanding boxes can have an optional 'table' with 'columns' (headings) and 'rows' (first cell names the row), which is shown in place of body. Body should still contain the same content as text, as this is used for search.

### Card contents

Basic HTML tags (B, U, I, P, UL, LI, BR, SMALL) can be used within for formatting where required. All tags should be closed, otherwise may lead to parsing errors. 

Unicode subscript and superscript characters are used rather than SUB and SUP spans, with SMALL where no unicode character exists.

Links are parsed as following:

#### Guideline links
Generated when the following regex is matched:  
`/[(]?[→][\s]?[1-4][-][0-9]{1,2}[)]?/`  
Therefore can have with or without parentheses, and is insensitive to space between → and guideline code.

#### Phone links
Automatic detection using NSDataDetector

#### Web links
Automatic detection using NSDataDetector

*iOS, iPhone, iPad, Spotlight and App Store are trademarks of Apple Inc.*
