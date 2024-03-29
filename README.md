# Quick Reference Handbook (QRH)

## Screenshots

### iPhone
<img src="./qrh/screenshots/Simulator Screen Shot - iPhone 11 - 2020-10-25 at 00.05.59.png" width="200px"> | <img src="./qrh/screenshots/Simulator Screen Shot - iPhone 11 - 2020-10-24 at 23.58.44.png" width="200px"> | <img src="./qrh/screenshots/Simulator Screen Shot - iPhone 11 - 2020-10-25 at 00.00.45.png" width="200px"> | <img src="./qrh/screenshots/Simulator Screen Shot - iPhone 11 - 2020-10-24 at 23.58.17.png" width="200px">

### iPad

<img src="./qrh/screenshots/Simulator Screen Shot - iPad Pro (11-inch) (2nd generation) - 2020-10-24 at 23.58.01.png" width="400px"> | <img src="./qrh/screenshots/Simulator Screen Shot - iPad Pro (11-inch) (2nd generation) - 2020-10-24 at 23.57.40.png" width="400px">

## Features
- Unofficial derivative of the Association of Anaesthetists Quick Reference Handbook (QRH): www.anaesthetists.org/Quick-Reference-Handbook (CC BY-NC-SA 4.0)
- iOS port of <a href="http://github.com/anaes-dev/qrh-android">github.com/anaes-dev/qrh-android</a>
- ***Not endorsed by the Association of Anaesthetists***
- Rapidly searchable guideline list
- Simple guideline layout echoing original handbook
- Clickable links between guidelines
- Compatible with iOS dark mode
- Large format two-column layout for iPad
- Easily updatable through modification of JSON assets
- [![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa] Released under same Creative Commons license as original work  

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

<a href='https://apps.apple.com/gb/app/quick-reference-handbook-qrh/id1537247898'><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1605744000&h=39b9465c7f7117e54e77a92b3fc75817" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;"></a>


## Technical
*(For any updates, modifications or derivatives)*

The guideline list is generated from '/guidelines.json'. 

Guidelines are stored as JSON objects with guideline code as their filename, e.g. '3-5.json'.

Each array contains 'type', 'head', 'body' and 'step' keys.

These populate different styled cards for each guideline page.

### Card views

Type integer value determines the appearance of the generated card:
1. Introductory text (body only)
2. START text (body only)
3. Guideline step with bold heading and separate content (head, body and step)
4. Guideline step with single text field (body and step)
5. Orange expanding box (head and body)
6. Blue expanding box (head and body)
7. Green expanding box (head and body)
8. Black expanding box (head and body)
9. Purple expanding box (head and body)
10. Image (caption in head, path/URL in body)
11. Version text (body only)
12. Red disclaimer card (head only)  

### Card contents

Basic HTML tags (B, U, I, LI) can be used within for formatting where required. All tags should be closed, otherwise may lead to parsing errors. 

Unicode subscript and superscript characters are used rather than SUB and SUP spans due to line-height issues on earlier Android versions.


#### Guideline links
Generated when the following regex is matched:  
`[(]?[→][\s]?[1-4][-][0-9]{1,2}[)]?`  
Therefore can have with or without parentheses, and is insensitive to space between → and guideline code.

#### Phone links
Automatic link detection using dataDetectorTypes.

#### Web links
Automatic link detection using dataDetectorTypes.

*iOS, iPhone, iPad and App Store are trademarks of Apple Inc.*
