# Jasmin Beach Resort — Website

Static, dependency-free website for Jasmin Beach Resort, Barangay Amambucale, Marabut, Samar.
Designed and built by Lendez Studio. Concept status: **awaiting client approval** (see checklist below).

## Structure

```
Website (repository root, served by GitHub Pages):
  index.html              Home
  stay.html               Stay / accommodations
  dine.html               Dining
  gallery.html            Filterable gallery + lightbox
  contact.html            Contact details, inquiry form, map
  404.html                Not-found page
  assets/css/styles.css   Design system and layout
  assets/js/main.js       Navigation, reveals, gallery, inquiry form
  assets/fonts/           Self-hosted Space Grotesk + DM Sans (OFL)
  assets/img/photos/      Optimised resort photos (480 / 960 / 1600 px)
  assets/img/brand/       Logo derivatives and app icons
  assets/img/jasmin-beach-resort-og.jpg   1200×630 social sharing image
  favicon.ico, favicon-16x16.png, favicon-32x32.png, apple-touch-icon.png
  site.webmanifest, robots.txt, sitemap.xml, .nojekyll
brand-kit/                Transparent logo PNGs, OG image and icons for other uses
tools/                    PowerShell scripts that rebuild images and brand assets
Initial Image/, *.pdf     Original source material (kept out of git, see .gitignore)
```

No build step is needed: open `index.html` in a browser.

## Deploy to GitHub Pages

1. Push this project to a GitHub repository.
2. **Settings → Pages → Build and deployment**: Source *Deploy from a branch*, branch `main`, folder `/ (root)`.
3. The live address used for canonical URLs, Open Graph, the sitemap and the 404 page is currently
   `https://lendezstudio.github.io/Jasmin-Beach-Resort/`. To change it (for example to a custom domain):

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\set-site-url.ps1 -Url https://example.com/
   ```
4. After publishing, test the share preview with the Facebook Sharing Debugger and by pasting the link into WhatsApp/Messenger.

All page links and asset paths are relative, so the site works from a project sub-path (`/repo/`) or a custom domain.

## Inquiry form

The form validates input and never claims to have sent anything unless a real endpoint confirms delivery.

- **Now (no endpoint):** after validation, visitors get a "ready to send" panel with *Text this inquiry*
  (pre-filled SMS), *Call the resort* and *Copy details*.
- **To enable online sending:** set `data-endpoint` on `<form id="inquiry-form">` in `contact.html` to a
  tested form-delivery URL (for example a free Formspree or Web3Forms endpoint that delivers to the resort's
  confirmed inbox). The success message appears only when that endpoint returns a success response.
- `data-phone` on the same form sets the number used for the SMS/call fallback.

## Rebuilding images

Requires Windows PowerShell (uses System.Drawing; no installs).

```powershell
powershell -ExecutionPolicy Bypass -File tools\optimize-images.ps1      # photos → assets/img/photos
powershell -ExecutionPolicy Bypass -File tools\build-brand-assets.ps1   # logo, favicons, OG image
```

`optimize-images.ps1` crops out the camera timestamps and watermarks burned into some originals.

## Awaiting business confirmation before launch

Content follows the approved website copy. Only corroborated facts are presented as facts: a beachfront resort
with air-conditioned overnight rooms and a restaurant. Everything else uses inquiry CTAs.

- **Contact:** both mobile numbers are published but unconfirmed. No email is shown, because two candidate
  addresses exist. The official Facebook URL is not linked yet.
- **Map pin:** the map and directions use a name search for "Jasmin Beach Resort, Amambucale, Marabut, Samar".
  Replace it with the verified pin.
- **Rooms:** room categories, guest limits, amenities and rates are not published. A commented room-card
  template is in `stay.html`.
- **Dining:** the menu, prices and service hours are not published. Which building houses the restaurant is also
  unconfirmed; captions describe what the photos show.
- **Gather page:** group and event services are hidden, as the strategy requires. "A group or occasion" exists
  only as an inquiry type.
- **Photos:** rights and approval for every image, including two photos with identifiable guests
  (`kayak-calm-water`, `kayak-shore`). Floating cottages and kayaks appear in photos but are not advertised as
  services.
- **Excluded photos:** two photos look heavily edited or AI-enhanced (`813583094…`, `814768778…`) or are low
  resolution (`825267301…`, `825279944…`, `829196558…`). They are not used.
- **Domain:** live on GitHub Pages; if a custom domain is added, run `set-site-url.ps1` again.
- **Favicon:** the "J" monogram comes from the logo wordmark and is a concept that needs approval.
- **Pool, Wi-Fi, standby power, events, policies:** not mentioned anywhere on the site.
