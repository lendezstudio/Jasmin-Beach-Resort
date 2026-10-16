/* Jasmin Beach Resort — site interactions (no dependencies). */
(function () {
  "use strict";

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var $ = function (sel, ctx) { return (ctx || document).querySelector(sel); };
  var $$ = function (sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); };

  /* ---------- Header: solid on scroll, hide on scroll down ---------- */
  var header = $(".site-header");
  var actionBar = $(".action-bar");
  var lastY = window.scrollY;
  var ticking = false;

  function onScroll() {
    var y = window.scrollY;
    if (header) {
      header.classList.toggle("is-solid", y > 40);
      var goingDown = y > lastY && y > 400;
      header.classList.toggle("is-hidden", goingDown && !document.body.classList.contains("menu-open"));
    }
    if (actionBar) actionBar.classList.toggle("is-visible", y > window.innerHeight * 0.6);
    lastY = y;
    ticking = false;
  }
  window.addEventListener("scroll", function () {
    if (!ticking) { window.requestAnimationFrame(onScroll); ticking = true; }
  }, { passive: true });
  onScroll();

  /* ---------- Mobile menu ---------- */
  var menu = $("#mobile-menu");
  var toggle = $(".menu-toggle");
  var closeBtn = menu && $(".menu-close", menu);

  function focusables(root) {
    return $$('a[href], button:not([disabled]), input, select, textarea, [tabindex]:not([tabindex="-1"])', root)
      .filter(function (el) { return el.offsetParent !== null; });
  }
  function openMenu() {
    menu.classList.add("is-open");
    menu.removeAttribute("aria-hidden");
    menu.removeAttribute("inert");
    toggle.setAttribute("aria-expanded", "true");
    document.body.classList.add("menu-open");
    window.setTimeout(function () { closeBtn.focus(); }, 50);
  }
  function closeMenu(returnFocus) {
    menu.classList.remove("is-open");
    menu.setAttribute("aria-hidden", "true");
    menu.setAttribute("inert", "");
    toggle.setAttribute("aria-expanded", "false");
    document.body.classList.remove("menu-open");
    if (returnFocus) toggle.focus();
  }
  if (menu && toggle) {
    menu.setAttribute("inert", "");
    toggle.addEventListener("click", openMenu);
    closeBtn.addEventListener("click", function () { closeMenu(true); });
    $$("a", menu).forEach(function (a) { a.addEventListener("click", function () { closeMenu(false); }); });
    menu.addEventListener("keydown", function (e) {
      if (e.key === "Escape") { closeMenu(true); return; }
      if (e.key !== "Tab") return;
      var f = focusables(menu);
      if (!f.length) return;
      if (e.shiftKey && document.activeElement === f[0]) { e.preventDefault(); f[f.length - 1].focus(); }
      else if (!e.shiftKey && document.activeElement === f[f.length - 1]) { e.preventDefault(); f[0].focus(); }
    });
    window.addEventListener("resize", function () {
      if (window.innerWidth > 1100 && menu.classList.contains("is-open")) closeMenu(false);
    });
  }

  /* ---------- Reveal on scroll ---------- */
  var revealEls = $$("[data-reveal]");
  if ("IntersectionObserver" in window && !reduceMotion) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          io.unobserve(entry.target);
        }
      });
    }, { rootMargin: "0px 0px -6% 0px", threshold: 0 });
    revealEls.forEach(function (el) { io.observe(el); });
  } else {
    revealEls.forEach(function (el) { el.classList.add("is-visible"); });
  }

  /* ---------- Horizontal photo strip: buttons + drag ---------- */
  $$("[data-strip]").forEach(function (wrap) {
    var strip = $(".strip", wrap);
    if (!strip) return;
    var step = function () { return Math.max(strip.clientWidth * 0.7, 280); };
    var prev = $("[data-strip-prev]", wrap);
    var next = $("[data-strip-next]", wrap);
    if (prev) prev.addEventListener("click", function () { strip.scrollBy({ left: -step(), behavior: reduceMotion ? "auto" : "smooth" }); });
    if (next) next.addEventListener("click", function () { strip.scrollBy({ left: step(), behavior: reduceMotion ? "auto" : "smooth" }); });

    var down = false, startX = 0, startLeft = 0, moved = false;
    strip.addEventListener("pointerdown", function (e) {
      if (e.pointerType !== "mouse") return;
      down = true; moved = false; startX = e.clientX; startLeft = strip.scrollLeft;
    });
    window.addEventListener("pointermove", function (e) {
      if (!down) return;
      var dx = e.clientX - startX;
      if (Math.abs(dx) > 5) { moved = true; strip.classList.add("is-dragging"); }
      strip.scrollLeft = startLeft - dx;
    });
    window.addEventListener("pointerup", function () {
      if (!down) return;
      down = false;
      window.setTimeout(function () { strip.classList.remove("is-dragging"); }, 0);
    });
    strip.addEventListener("click", function (e) { if (moved) { e.preventDefault(); moved = false; } }, true);
  });

  /* ---------- Gallery: filters + lightbox ---------- */
  var gallery = $("[data-gallery]");
  if (gallery) {
    var items = $$(".g-item", gallery);
    var filters = $$(".filter");
    var visible = items.slice();

    filters.forEach(function (btn) {
      var cat = btn.getAttribute("data-filter");
      var n = cat === "all" ? items.length : items.filter(function (i) { return i.getAttribute("data-cat") === cat; }).length;
      var c = $(".count", btn);
      if (c) c.textContent = n;
      btn.addEventListener("click", function () {
        filters.forEach(function (b) { b.setAttribute("aria-pressed", String(b === btn)); });
        visible = [];
        items.forEach(function (item) {
          var show = cat === "all" || item.getAttribute("data-cat") === cat;
          item.hidden = !show;
          if (show) visible.push(item);
        });
        var status = $("#gallery-status");
        if (status) status.textContent = "Showing " + visible.length + " photos" + (cat === "all" ? "" : " in " + btn.firstChild.textContent.trim());
      });
    });

    var lb = $("#lightbox");
    var lbImg = lb && $("img", lb);
    var lbCap = lb && $(".lightbox__caption", lb);
    var lbCount = lb && $(".lightbox__count", lb);
    var current = 0;
    var opener = null;

    function show(index) {
      if (!visible.length) return;
      current = (index + visible.length) % visible.length;
      var item = visible[current];
      var img = $("img", item);
      lbImg.classList.add("is-loading");
      lbImg.onload = function () { lbImg.classList.remove("is-loading"); };
      lbImg.src = item.getAttribute("data-full");
      lbImg.alt = img.alt;
      lbCap.textContent = item.getAttribute("data-caption") || img.alt;
      lbCount.textContent = (current + 1) + " / " + visible.length;
      // Warm the cache for neighbours.
      [current + 1, current - 1].forEach(function (i) {
        var n = visible[(i + visible.length) % visible.length];
        if (n) { var pre = new Image(); pre.src = n.getAttribute("data-full"); }
      });
    }
    function openLb(item) {
      opener = item;
      show(visible.indexOf(item));
      if (typeof lb.showModal === "function") lb.showModal(); else lb.setAttribute("open", "");
      document.body.style.overflow = "hidden";
    }
    function closeLb() {
      if (typeof lb.close === "function") lb.close(); else lb.removeAttribute("open");
    }
    if (lb) {
      items.forEach(function (item) { item.addEventListener("click", function () { openLb(item); }); });
      $(".lightbox__close", lb).addEventListener("click", closeLb);
      $(".lightbox__nav--prev", lb).addEventListener("click", function () { show(current - 1); });
      $(".lightbox__nav--next", lb).addEventListener("click", function () { show(current + 1); });
      lb.addEventListener("close", function () {
        document.body.style.overflow = "";
        if (opener) opener.focus();
      });
      lb.addEventListener("keydown", function (e) {
        if (e.key === "ArrowRight") { e.preventDefault(); show(current + 1); }
        if (e.key === "ArrowLeft") { e.preventDefault(); show(current - 1); }
      });
      lb.addEventListener("click", function (e) {
        if (e.target === lb || e.target.classList.contains("lightbox__stage")) closeLb();
      });
      var tx = null;
      lb.addEventListener("touchstart", function (e) { tx = e.touches[0].clientX; }, { passive: true });
      lb.addEventListener("touchend", function (e) {
        if (tx === null) return;
        var dx = e.changedTouches[0].clientX - tx;
        if (Math.abs(dx) > 50) show(current + (dx < 0 ? 1 : -1));
        tx = null;
      });
    }
  }

  /* ---------- Inquiry form ---------- */
  var form = $("#inquiry-form");
  if (form) {
    var params = new URLSearchParams(window.location.search);
    var interest = params.get("interest");
    var typeSelect = $("#inq-type", form);
    if (interest && typeSelect) {
      var match = $$("option", typeSelect).filter(function (o) { return o.value === interest; })[0];
      if (match) typeSelect.value = interest;
    }
    var dateInput = $("#inq-date", form);
    if (dateInput) dateInput.min = new Date().toISOString().slice(0, 10);

    var statusBox = $("#form-status");
    var submitBtn = $('button[type="submit"]', form);
    // Set data-endpoint on the form to a confirmed form-delivery URL (for example a
    // Formspree or Web3Forms endpoint tested by the resort). Until then, the form never
    // claims to have sent anything.
    var endpoint = (form.getAttribute("data-endpoint") || "").trim();
    var phone = form.getAttribute("data-phone") || "";

    var messages = {
      valueMissing: "Please fill in this field.",
      typeMismatch: "Please check the format.",
      rangeUnderflow: "Please enter a number of at least 1.",
      rangeOverflow: "Please enter a smaller number.",
      tooShort: "Please add a little more detail."
    };
    function errorFor(field) {
      var v = field.validity;
      if (v.valid) return "";
      if (field.type === "checkbox") return "Please confirm you understand an inquiry is not a booking.";
      if (field.id === "inq-contact" && (v.patternMismatch || v.typeMismatch)) return "Enter an email address or a mobile number.";
      if (field.id === "inq-date" && v.rangeUnderflow) return "Please choose today or a future date.";
      for (var k in messages) { if (v[k]) return messages[k]; }
      return "Please check this field.";
    }
    function validateField(field) {
      var msg = errorFor(field);
      var err = document.getElementById(field.id + "-error");
      field.setAttribute("aria-invalid", msg ? "true" : "false");
      if (err) err.textContent = msg;
      return !msg;
    }
    var fields = $$("input, select, textarea", form).filter(function (f) { return f.id && f.type !== "hidden"; });
    fields.forEach(function (f) {
      f.addEventListener("blur", function () { if (f.value || f.getAttribute("aria-invalid")) validateField(f); });
      f.addEventListener("input", function () { if (f.getAttribute("aria-invalid") === "true") validateField(f); });
    });

    function summary() {
      var d = new FormData(form);
      var lines = [
        "Inquiry for Jasmin Beach Resort",
        "Name: " + (d.get("name") || ""),
        "Contact: " + (d.get("contact") || ""),
        "Inquiry: " + (typeSelect ? typeSelect.options[typeSelect.selectedIndex].text : ""),
      ];
      if (d.get("date")) lines.push("Preferred date: " + d.get("date"));
      if (d.get("guests")) lines.push("Guests: " + d.get("guests"));
      lines.push("Message: " + (d.get("message") || ""));
      return lines.join("\n");
    }

    function renderStatus(kind, html) {
      statusBox.className = "form-status form-status--" + kind;
      statusBox.innerHTML = html;
      statusBox.hidden = false;
      statusBox.focus();
    }

    function showManual() {
      var text = summary();
      var smsHref = "sms:" + phone + "?&body=" + encodeURIComponent(text);
      renderStatus("info",
        '<h3>Your inquiry is ready to send</h3>' +
        '<p>Online sending is not switched on yet, so nothing has been sent. Text your inquiry to the resort or call them directly. Your details are below, ready to copy.</p>' +
        '<div class="btn-row">' +
          '<a class="btn btn--solid" href="' + smsHref + '">Text this inquiry</a>' +
          '<a class="btn btn--dark" href="tel:' + phone + '">Call the resort</a>' +
          '<button type="button" class="btn btn--dark" data-copy>Copy details</button>' +
        '</div>' +
        '<label class="visually-hidden" for="inq-summary">Inquiry details</label>' +
        '<textarea id="inq-summary" readonly></textarea>' +
        '<p class="small-print">Sending an inquiry does not confirm availability or a booking.</p>');
      var ta = $("#inq-summary", statusBox);
      ta.value = text;
      $("[data-copy]", statusBox).addEventListener("click", function (e) {
        var btn = e.currentTarget;
        var done = function () { btn.textContent = "Copied"; };
        if (navigator.clipboard && window.isSecureContext) {
          navigator.clipboard.writeText(text).then(done, function () { ta.select(); });
        } else { ta.select(); try { document.execCommand("copy"); done(); } catch (err) { /* user can copy manually */ } }
      });
    }

    form.addEventListener("submit", function (e) {
      e.preventDefault();
      // Honeypot: bots fill hidden fields.
      if ($('[name="company"]', form) && $('[name="company"]', form).value) return;
      var firstBad = null;
      fields.forEach(function (f) { if (!validateField(f) && !firstBad) firstBad = f; });
      if (firstBad) { firstBad.focus(); return; }

      if (!endpoint) { showManual(); return; }

      submitBtn.disabled = true;
      var label = submitBtn.querySelector(".label");
      var original = label.textContent;
      label.textContent = "Sending…";
      fetch(endpoint, { method: "POST", body: new FormData(form), headers: { Accept: "application/json" } })
        .then(function (res) {
          if (!res.ok) throw new Error("HTTP " + res.status);
          form.reset();
          fields.forEach(function (f) { f.removeAttribute("aria-invalid"); });
          renderStatus("success",
            "<h3>Thanks for reaching out</h3><p>Your inquiry has been sent. Our staff will respond after reviewing the details.</p>" +
            '<p class="small-print">Sending an inquiry does not confirm availability or a booking.</p>');
        })
        .catch(function () {
          renderStatus("error", "<h3>We couldn’t send your inquiry</h3><p>Please try again in a moment, or contact the resort directly using the options below.</p>");
          var extra = document.createElement("div");
          extra.className = "btn-row";
          extra.innerHTML = '<a class="btn btn--solid" href="tel:' + phone + '">Call the resort</a>';
          statusBox.appendChild(extra);
        })
        .then(function () { submitBtn.disabled = false; label.textContent = original; });
    });
  }

  /* ---------- Map: show fallback text if the embed can't load ---------- */
  $$(".map-frame iframe").forEach(function (frame) {
    frame.addEventListener("load", function () {
      var fb = frame.parentNode.querySelector(".map-frame__fallback");
      if (fb) fb.setAttribute("aria-hidden", "true");
    });
  });

  /* ---------- Footer year ---------- */
  $$("[data-year]").forEach(function (el) { el.textContent = new Date().getFullYear(); });
})();
