/**
 * ML Model 4 — Minimal Futuristic Client Controller
 * Clean, lightweight, real-model integration with zero fake data.
 */

document.addEventListener('DOMContentLoaded', () => {

  // ---------------------------------------------------------------------------
  // 1. GLOBAL BACKGROUND PARTICLE CANVAS
  // ---------------------------------------------------------------------------
  const bgCanvas = document.getElementById('bgCanvas');
  const bgCtx = bgCanvas.getContext('2d');
  let bgParticles = [];
  const BG_COUNT = 45;

  function resizeBg() {
    bgCanvas.width = window.innerWidth;
    bgCanvas.height = window.innerHeight;
  }
  window.addEventListener('resize', resizeBg);
  resizeBg();

  for (let i = 0; i < BG_COUNT; i++) {
    bgParticles.push({
      x: Math.random() * bgCanvas.width,
      y: Math.random() * bgCanvas.height,
      vx: (Math.random() - 0.5) * 0.4,
      vy: (Math.random() - 0.5) * 0.4,
      radius: Math.random() * 1.6 + 0.6,
      alpha: Math.random() * 0.5 + 0.2
    });
  }

  function renderBg() {
    bgCtx.clearRect(0, 0, bgCanvas.width, bgCanvas.height);

    // Draw connection lines
    for (let i = 0; i < bgParticles.length; i++) {
      for (let j = i + 1; j < bgParticles.length; j++) {
        const dx = bgParticles[i].x - bgParticles[j].x;
        const dy = bgParticles[i].y - bgParticles[j].y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 130) {
          bgCtx.strokeStyle = `rgba(0, 240, 255, ${0.12 * (1 - dist / 130)})`;
          bgCtx.lineWidth = 0.8;
          bgCtx.beginPath();
          bgCtx.moveTo(bgParticles[i].x, bgParticles[i].y);
          bgCtx.lineTo(bgParticles[j].x, bgParticles[j].y);
          bgCtx.stroke();
        }
      }
    }

    // Draw and update particles
    for (let p of bgParticles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0) p.x = bgCanvas.width;
      if (p.x > bgCanvas.width) p.x = 0;
      if (p.y < 0) p.y = bgCanvas.height;
      if (p.y > bgCanvas.height) p.y = 0;

      bgCtx.fillStyle = `rgba(255, 255, 255, ${p.alpha})`;
      bgCtx.beginPath();
      bgCtx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      bgCtx.fill();
    }
    requestAnimationFrame(renderBg);
  }
  renderBg();


  // ---------------------------------------------------------------------------
  // 2. MINI CARD CANVASES (INTERACTIVE CARD PREVIEWS)
  // ---------------------------------------------------------------------------
  const miniCanvases = {
    brain: document.getElementById('miniCanvas-brain'),
    country: document.getElementById('miniCanvas-country'),
    f1: document.getElementById('miniCanvas-f1'),
    placement: document.getElementById('miniCanvas-placement')
  };

  let miniAngle = 0;
  function renderMiniCanvases() {
    miniAngle += 0.02;

    // 01: Brain (Pulsing Synapse Orbit)
    if (miniCanvases.brain) {
      const ctx = miniCanvases.brain.getContext('2d');
      ctx.clearRect(0, 0, 120, 120);
      const pulse = Math.sin(miniAngle * 2) * 4;
      ctx.strokeStyle = 'rgba(168, 85, 247, 0.4)';
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      ctx.arc(60, 60, 36 + pulse, 0, Math.PI * 2);
      ctx.stroke();

      for (let i = 0; i < 3; i++) {
        const theta = miniAngle + (i * Math.PI * 2) / 3;
        const x = 60 + Math.cos(theta) * 36;
        const y = 60 + Math.sin(theta) * 36;
        ctx.fillStyle = '#a855f7';
        ctx.beginPath();
        ctx.arc(x, y, 2.5, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    // 02: Country (Orbital Wireframe)
    if (miniCanvases.country) {
      const ctx = miniCanvases.country.getContext('2d');
      ctx.clearRect(0, 0, 120, 120);
      ctx.strokeStyle = 'rgba(0, 240, 255, 0.35)';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.ellipse(60, 60, 38, 16, miniAngle * 0.5, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.ellipse(60, 60, 38, 16, -miniAngle * 0.5, 0, Math.PI * 2);
      ctx.stroke();
    }

    // 03: F1 (Circuit Apex Tracer)
    if (miniCanvases.f1) {
      const ctx = miniCanvases.f1.getContext('2d');
      ctx.clearRect(0, 0, 120, 120);
      ctx.strokeStyle = 'rgba(255, 51, 102, 0.35)';
      ctx.lineWidth = 1.4;
      ctx.strokeRect(26, 26, 68, 68);

      const t = (miniAngle * 1.5) % (Math.PI * 2);
      const px = 60 + Math.cos(t) * 32;
      const py = 60 + Math.sin(t) * 32;
      ctx.fillStyle = '#ff3366';
      ctx.shadowColor = '#ff3366';
      ctx.shadowBlur = 8;
      ctx.beginPath();
      ctx.arc(px, py, 3.5, 0, Math.PI * 2);
      ctx.fill();
      ctx.shadowBlur = 0;
    }

    // 04: Placement (Radial Progress Arc)
    if (miniCanvases.placement) {
      const ctx = miniCanvases.placement.getContext('2d');
      ctx.clearRect(0, 0, 120, 120);
      ctx.strokeStyle = 'rgba(16, 185, 129, 0.4)';
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.arc(60, 60, 34, -Math.PI / 2, -Math.PI / 2 + (miniAngle % (Math.PI * 2)));
      ctx.stroke();
    }

    requestAnimationFrame(renderMiniCanvases);
  }
  renderMiniCanvases();


  // ---------------------------------------------------------------------------
  // 3. SEAMLESS VIEW NAVIGATION (HOME ⇄ INDIVIDUAL MODELS)
  // ---------------------------------------------------------------------------
  const views = {
    homeView: document.getElementById('homeView'),
    brain: document.getElementById('modelView-brain'),
    country: document.getElementById('modelView-country'),
    f1: document.getElementById('modelView-f1'),
    placement: document.getElementById('modelView-placement')
  };

  function switchView(targetViewId) {
    const currentActive = document.querySelector('.view.active-view');
    const targetElement = document.getElementById(targetViewId);
    if (!targetElement || currentActive === targetElement) return;

    if (window.gsap) {
      gsap.to(currentActive, {
        opacity: 0,
        y: -10,
        duration: 0.25,
        ease: 'power2.in',
        onComplete: () => {
          currentActive.classList.remove('active-view');
          targetElement.classList.add('active-view');
          window.scrollTo(0, 0);
          gsap.fromTo(targetElement,
            { opacity: 0, y: 15 },
            { opacity: 1, y: 0, duration: 0.35, ease: 'power2.out' }
          );

          // Trigger view-specific canvas resize & setup
          if (targetViewId === 'modelView-brain') {
            resizeTopicCanvas('canvas-brain-vis');
          }
          if (targetViewId === 'modelView-country') {
            resizeTopicCanvas('canvas-country-vis');
            loadCountriesDropdown();
          }
          if (targetViewId === 'modelView-f1') resizeTopicCanvas('canvas-f1-vis');
          if (targetViewId === 'modelView-placement') resizeTopicCanvas('canvas-placement-vis');
        }
      });
    } else {
      currentActive.classList.remove('active-view');
      targetElement.classList.add('active-view');
    }
  }

  // Home Card Click Handlers
  document.querySelectorAll('.model-card').forEach(card => {
    card.addEventListener('click', () => {
      const model = card.getAttribute('data-model');
      switchView(`modelView-${model}`);
    });
    card.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        const model = card.getAttribute('data-model');
        switchView(`modelView-${model}`);
      }
    });
  });

  // Back Button Handlers
  document.querySelectorAll('.btn-back').forEach(btn => {
    btn.addEventListener('click', () => {
      switchView('homeView');
    });
  });


  // ---------------------------------------------------------------------------
  // 4. TOPIC-SPECIFIC VISUALIZATION CANVASES
  // ---------------------------------------------------------------------------
  function resizeTopicCanvas(id) {
    const canvas = document.getElementById(id);
    if (!canvas) return;
    const rect = canvas.parentElement.getBoundingClientRect();
    canvas.width = rect.width;
    canvas.height = rect.height;
  }
  window.addEventListener('resize', () => {
    resizeTopicCanvas('canvas-brain-vis');
    resizeTopicCanvas('canvas-country-vis');
    resizeTopicCanvas('canvas-f1-vis');
    resizeTopicCanvas('canvas-placement-vis');
  });

  // --- Topic Visualizer 1: Brain Activity Network (10-20 Scalp Montage) ---
  let brainActiveCluster = null;
  let brainPcaCoords = null;
  const eegChannels = [
    { id: 'AF3', nx: -0.28, ny: -0.65, region: 'frontal' },
    { id: 'AF4', nx: 0.28, ny: -0.65, region: 'frontal' },
    { id: 'F7',  nx: -0.68, ny: -0.42, region: 'frontal' },
    { id: 'F3',  nx: -0.32, ny: -0.32, region: 'frontal' },
    { id: 'F4',  nx: 0.32, ny: -0.32, region: 'frontal' },
    { id: 'F8',  nx: 0.68, ny: -0.42, region: 'frontal' },
    { id: 'FC5', nx: -0.56, ny: -0.10, region: 'central' },
    { id: 'FC6', nx: 0.56, ny: -0.10, region: 'central' },
    { id: 'T7',  nx: -0.80, ny: 0.12, region: 'temporal' },
    { id: 'T8',  nx: 0.80, ny: 0.12, region: 'temporal' },
    { id: 'P7',  nx: -0.64, ny: 0.48, region: 'parietal' },
    { id: 'P8',  nx: 0.64, ny: 0.48, region: 'parietal' },
    { id: 'O1',  nx: -0.24, ny: 0.72, region: 'occipital' },
    { id: 'O2',  nx: 0.24, ny: 0.72, region: 'occipital' }
  ];

  function renderBrainVis() {
    const canvas = document.getElementById('canvas-brain-vis');
    if (canvas && canvas.offsetParent !== null) {
      const ctx = canvas.getContext('2d');
      const w = canvas.width;
      const h = canvas.height;
      if (w <= 0 || h <= 0) return requestAnimationFrame(renderBrainVis);

      ctx.clearRect(0, 0, w, h);
      const time = Date.now() * 0.002;
      const cx = w / 2;
      const cy = h / 2;
      const R = Math.min(w, h) * 0.40;

      // 1. Draw Scalp / Head Contour (10-20 Standard Montage Outline)
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.12)';
      ctx.lineWidth = 1.6;
      ctx.beginPath();
      ctx.ellipse(cx, cy, R * 0.92, R * 1.05, 0, 0, Math.PI * 2);
      ctx.stroke();

      // Nose triangle at top
      ctx.beginPath();
      ctx.moveTo(cx - 12, cy - R * 1.05);
      ctx.lineTo(cx, cy - R * 1.05 - 12);
      ctx.lineTo(cx + 12, cy - R * 1.05);
      ctx.stroke();

      // Ear curves left and right
      ctx.beginPath();
      ctx.arc(cx - R * 0.94, cy, 10, -Math.PI / 2, Math.PI / 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(cx + R * 0.94, cy, 10, Math.PI / 2, -Math.PI / 2);
      ctx.stroke();

      // 2. Active Cluster Concentric Brain Waves
      if (brainActiveCluster) {
        let waveOriginX = cx;
        let waveOriginY = cy;
        let waveColor = '#a855f7';

        if (brainActiveCluster === 1) {
          // Posterior Alpha: Radiates from Occipital lobes
          waveOriginY = cy + R * 0.72;
          waveColor = 'rgba(168, 85, 247, 0.35)';
        } else if (brainActiveCluster === 2) {
          // Slow-Wave Delta: High-voltage Central burst
          waveOriginY = cy;
          waveColor = 'rgba(245, 158, 11, 0.4)';
        } else {
          // Alert Beta: Rapid Frontal Desynchronization
          waveOriginY = cy - R * 0.5;
          waveColor = 'rgba(0, 240, 255, 0.35)';
        }

        for (let ring = 1; ring <= 3; ring++) {
          const ringR = ((time * 25 + ring * 25) % (R * 0.8)) + 15;
          const alphaFade = Math.max(0, 1 - ringR / (R * 0.8));
          ctx.strokeStyle = waveColor.replace(/[\d\.]+\)$/, `${alphaFade * 0.5})`);
          ctx.lineWidth = 1.5;
          ctx.beginPath();
          ctx.arc(waveOriginX, waveOriginY, ringR, 0, Math.PI * 2);
          ctx.stroke();
        }
      }

      // 3. Synaptic Neural Interconnect Fibers
      for (let i = 0; i < eegChannels.length; i++) {
        for (let j = i + 1; j < eegChannels.length; j++) {
          const c1 = eegChannels[i];
          const c2 = eegChannels[j];
          const x1 = cx + c1.nx * R;
          const y1 = cy + c1.ny * R;
          const x2 = cx + c2.nx * R;
          const y2 = cy + c2.ny * R;
          const dist = Math.hypot(x2 - x1, y2 - y1);

          if (dist < R * 0.7) {
            let synColor = 'rgba(255, 255, 255, 0.05)';
            if (brainActiveCluster === 1 && (c1.region === 'occipital' || c2.region === 'occipital')) {
              synColor = 'rgba(168, 85, 247, 0.3)';
            } else if (brainActiveCluster === 2) {
              synColor = 'rgba(245, 158, 11, 0.25)';
            } else if (brainActiveCluster === 3 && (c1.region === 'frontal' || c2.region === 'frontal')) {
              synColor = 'rgba(0, 240, 255, 0.3)';
            }

            ctx.strokeStyle = synColor;
            ctx.lineWidth = 0.8;
            ctx.beginPath();
            ctx.moveTo(x1, y1);
            ctx.lineTo(x2, y2);
            ctx.stroke();
          }
        }
      }

      // 4. Render 14 Scalp Electrodes
      for (let ch of eegChannels) {
        const ex = cx + ch.nx * R;
        const ey = cy + ch.ny * R;
        let isExcited = false;
        let nodeColor = '#475569';
        let glowColor = 'transparent';

        if (brainActiveCluster === 1 && ch.region === 'occipital') {
          isExcited = true;
          nodeColor = '#a855f7';
          glowColor = '#a855f7';
        } else if (brainActiveCluster === 2) {
          isExcited = true;
          nodeColor = '#f59e0b';
          glowColor = '#f59e0b';
        } else if (brainActiveCluster === 3 && ch.region === 'frontal') {
          isExcited = true;
          nodeColor = '#00f0ff';
          glowColor = '#00f0ff';
        }

        const pulse = isExcited ? Math.sin(time * 6) * 2 : 0;
        ctx.fillStyle = nodeColor;
        ctx.shadowColor = glowColor;
        ctx.shadowBlur = isExcited ? 14 : 0;
        ctx.beginPath();
        ctx.arc(ex, ey, 5 + pulse, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowBlur = 0;

        // Label
        ctx.fillStyle = isExcited ? '#ffffff' : 'rgba(255, 255, 255, 0.4)';
        ctx.font = '600 0.58rem "JetBrains Mono", monospace';
        ctx.textAlign = 'center';
        ctx.fillText(ch.id, ex, ey - 9);
      }

      // 5. Mini PCA Projection Radar (Top-Right)
      if (brainPcaCoords) {
        const rx = w - 55;
        const ry = 55;
        const rr = 32;

        ctx.strokeStyle = 'rgba(255, 255, 255, 0.15)';
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.arc(rx, ry, rr, 0, Math.PI * 2);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(rx - rr, ry); ctx.lineTo(rx + rr, ry);
        ctx.moveTo(rx, ry - rr); ctx.lineTo(rx, ry + rr);
        ctx.stroke();

        const px = Math.max(-rr, Math.min(rr, (brainPcaCoords.x / 6) * rr));
        const py = Math.max(-rr, Math.min(rr, (-brainPcaCoords.y / 6) * rr));

        ctx.fillStyle = brainActiveCluster === 1 ? '#a855f7' : (brainActiveCluster === 2 ? '#f59e0b' : '#00f0ff');
        ctx.shadowColor = ctx.fillStyle;
        ctx.shadowBlur = 8;
        ctx.beginPath();
        ctx.arc(rx + px, ry + py, 4, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowBlur = 0;

        ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
        ctx.font = '0.52rem "JetBrains Mono", monospace';
        ctx.fillText('PCA 2D', rx, ry + rr + 10);
      }
    }
    requestAnimationFrame(renderBrainVis);
  }
  renderBrainVis();

  // --- Topic Visualizer 2: Global Development Matrix ---
  let countryTier = null;
  let globeAngle = 0;
  function renderCountryVis() {
    const canvas = document.getElementById('canvas-country-vis');
    if (canvas && canvas.offsetParent !== null) {
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      globeAngle += 0.008;

      const cx = canvas.width / 2;
      const cy = canvas.height / 2;
      const r = Math.min(canvas.width, canvas.height) * 0.36;

      // Outer globe boundary
      ctx.strokeStyle = 'rgba(0, 240, 255, 0.25)';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.stroke();

      // Rotating latitude lines
      for (let i = -2; i <= 2; i++) {
        const yOffset = (i / 3) * r * 0.8;
        const rad = Math.sqrt(Math.max(0, r * r - yOffset * yOffset));
        ctx.strokeStyle = 'rgba(0, 240, 255, 0.12)';
        ctx.beginPath();
        ctx.ellipse(cx, cy + yOffset, rad, rad * 0.3, globeAngle, 0, Math.PI * 2);
        ctx.stroke();
      }

      // Rotating longitude meridians
      for (let j = 0; j < 4; j++) {
        const offset = globeAngle + (j * Math.PI) / 4;
        const widthFactor = Math.cos(offset);
        ctx.strokeStyle = countryTier ? 'rgba(0, 240, 255, 0.25)' : 'rgba(255, 255, 255, 0.08)';
        ctx.beginPath();
        ctx.ellipse(cx, cy, Math.abs(r * widthFactor), r, 0, 0, Math.PI * 2);
        ctx.stroke();
      }

      // Central classification glow
      if (countryTier) {
        ctx.fillStyle = countryTier === 3 ? '#00f0ff' : (countryTier === 2 ? '#38bdf8' : '#f59e0b');
        ctx.shadowColor = ctx.fillStyle;
        ctx.shadowBlur = 24;
        ctx.beginPath();
        ctx.arc(cx, cy, 14, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowBlur = 0;
      }
    }
    requestAnimationFrame(renderCountryVis);
  }
  renderCountryVis();

  // --- Topic Visualizer 3: F1 Telemetry Circuit Trace ---
  let f1AnimOffset = 0;
  let f1PredictedPts = null;
  function renderF1Vis() {
    // 1. Aerodynamic Wind Tunnel Overlay Canvas
    const aeroCanvas = document.getElementById('canvas-f1-aero');
    if (aeroCanvas && aeroCanvas.offsetParent !== null) {
      if (aeroCanvas.width !== aeroCanvas.parentElement.clientWidth || aeroCanvas.height !== aeroCanvas.parentElement.clientHeight) {
        aeroCanvas.width = aeroCanvas.parentElement.clientWidth;
        aeroCanvas.height = aeroCanvas.parentElement.clientHeight;
        initF1AeroParticles(aeroCanvas.width, aeroCanvas.height);
      }
      const actx = aeroCanvas.getContext('2d');
      actx.clearRect(0, 0, aeroCanvas.width, aeroCanvas.height);

      const aw = aeroCanvas.width;
      const ah = aeroCanvas.height;

      // Draw aerodynamic streamlines that deflect around car nose and halo
      f1AeroParticles.forEach(p => {
        p.x += p.vx;
        if (p.x > aw) {
          p.x = 0;
          p.y = Math.random() * ah;
        }

        // Deflection around center nosecone / halo
        const cx = aw / 2;
        const cy = ah * 0.55;
        const dx = p.x - cx;
        const dy = p.y - cy;
        const dist = Math.sqrt(dx * dx + dy * dy);
        let curY = p.y;
        if (dist < aw * 0.28) {
          const push = (1 - dist / (aw * 0.28)) * 18 * (dy < 0 ? -1 : 1);
          curY += push;
        }

        actx.strokeStyle = p.color;
        actx.globalAlpha = p.alpha;
        actx.lineWidth = 1.2;
        actx.beginPath();
        actx.moveTo(p.x, curY);
        actx.lineTo(Math.max(0, p.x - p.len), curY);
        actx.stroke();
      });
      actx.globalAlpha = 1.0;

      // Subtle vortices off front wing tips
      const vortexTime = Date.now() * 0.003;
      const tipL = aw * 0.16;
      const tipR = aw * 0.84;
      const tipY = ah * 0.72;

      actx.strokeStyle = 'rgba(255, 24, 1, 0.45)';
      actx.lineWidth = 1.5;
      for (let v = 0; v < 3; v++) {
        const r = 6 + v * 7 + Math.sin(vortexTime + v) * 3;
        actx.beginPath();
        actx.arc(tipL, tipY, r, 0, Math.PI * 1.6);
        actx.stroke();

        actx.beginPath();
        actx.arc(tipR, tipY, r, Math.PI * 0.4, Math.PI * 2);
        actx.stroke();
      }
    }

    // 2. Blueprint CAD Measurement Overlay Canvas
    const bpCanvas = document.getElementById('canvas-f1-blueprint');
    if (bpCanvas && bpCanvas.offsetParent !== null) {
      if (bpCanvas.width !== bpCanvas.parentElement.clientWidth || bpCanvas.height !== bpCanvas.parentElement.clientHeight) {
        bpCanvas.width = bpCanvas.parentElement.clientWidth;
        bpCanvas.height = bpCanvas.parentElement.clientHeight;
      }
      const bctx = bpCanvas.getContext('2d');
      bctx.clearRect(0, 0, bpCanvas.width, bpCanvas.height);

      const bw = bpCanvas.width;
      const bh = bpCanvas.height;

      // Scanning telemetry laser line
      bpScanLine = (bpScanLine + 1.2) % bw;
      bctx.strokeStyle = 'rgba(0, 240, 255, 0.45)';
      bctx.lineWidth = 1.2;
      bctx.beginPath();
      bctx.moveTo(bpScanLine, 0);
      bctx.lineTo(bpScanLine, bh);
      bctx.stroke();

      // Laser highlight glow
      bctx.fillStyle = 'rgba(0, 240, 255, 0.04)';
      bctx.fillRect(Math.max(0, bpScanLine - 30), 0, 30, bh);

      // Coordinate readout at scan line
      bctx.fillStyle = '#00f0ff';
      bctx.font = '9px "JetBrains Mono", monospace';
      bctx.fillText(`X:${Math.round(bpScanLine * 6.5)}mm`, Math.min(bw - 70, bpScanLine + 6), 24);
      bctx.fillText(`CAD_FLOW: OK`, Math.min(bw - 70, bpScanLine + 6), 36);
    }

    // 3. Fallback compatibility canvas (canvas-f1-vis)
    const canvas = document.getElementById('canvas-f1-vis');
    if (canvas && canvas.offsetParent !== null) {
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      f1AnimOffset += 0.015;
    }
    requestAnimationFrame(renderF1Vis);
  }
  let f1AeroParticles = [];
  let bpScanLine = 0;
  function initF1AeroParticles(w, h) {
    f1AeroParticles = [];
    for (let i = 0; i < 48; i++) {
      f1AeroParticles.push({
        x: Math.random() * w,
        y: Math.random() * h,
        vx: 1.5 + Math.random() * 3.5,
        len: 18 + Math.random() * 36,
        alpha: 0.15 + Math.random() * 0.6,
        color: Math.random() > 0.4 ? '#00f0ff' : (Math.random() > 0.5 ? '#ff3366' : '#ffffff')
      });
    }
  }
  renderF1Vis();

  // --- Topic Visualizer 4: Placement Probability Radial Ring ---
  let placementTargetProb = null;
  let placementCurrentProb = 0;
  function renderPlacementVis() {
    const canvas = document.getElementById('canvas-placement-vis');
    if (canvas && canvas.offsetParent !== null) {
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      const cx = canvas.width / 2;
      const cy = canvas.height / 2;
      const r = Math.min(canvas.width, canvas.height) * 0.35;

      // Smooth probability interpolation
      if (placementTargetProb !== null) {
        placementCurrentProb += (placementTargetProb - placementCurrentProb) * 0.08;
      }

      // Background Track
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.06)';
      ctx.lineWidth = 12;
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.stroke();

      // 50% Threshold Marker
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.2)';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(cx, cy + r - 10);
      ctx.lineTo(cx, cy + r + 10);
      ctx.stroke();

      // Dynamic Animated Arc
      if (placementCurrentProb > 0.001) {
        const isPlaced = placementCurrentProb >= 0.5;
        const color = isPlaced ? '#10b981' : '#f43f5e';
        const endAngle = -Math.PI / 2 + placementCurrentProb * Math.PI * 2;

        ctx.strokeStyle = color;
        ctx.shadowColor = color;
        ctx.shadowBlur = 16;
        ctx.lineWidth = 12;
        ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.arc(cx, cy, r, -Math.PI / 2, endAngle);
        ctx.stroke();
        ctx.shadowBlur = 0;
        ctx.lineCap = 'butt';
      }

      // Center Percentage Text
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 2rem Orbitron, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const pctText = (placementCurrentProb * 100).toFixed(1) + '%';
      ctx.fillText(placementTargetProb !== null ? pctText : '---', cx, cy - 8);

      ctx.fillStyle = '#94a3b8';
      ctx.font = '500 0.72rem "JetBrains Mono", monospace';
      ctx.fillText('PROBABILITY', cx, cy + 24);
    }
    requestAnimationFrame(renderPlacementVis);
  }
  renderPlacementVis();


  // ---------------------------------------------------------------------------
  // 5. MODEL 1: BRAIN ACTIVITY PREDICTION (POST /api/brain/predict)
  // ---------------------------------------------------------------------------
  const formBrain = document.getElementById('form-brain');
  const btnBrain = document.getElementById('btn-submit-brain');
  const resBrain = document.getElementById('result-brain');
  const brainEpochSelect = document.getElementById('brain-epoch-select');

  // Toggle modes: Presets vs Custom Features
  const toggleBrainPreset = document.getElementById('toggleBrainPreset');
  const toggleBrainCustom = document.getElementById('toggleBrainCustom');
  const brainPresetWrap = document.getElementById('brain-preset-fields');
  const brainCustomGrid = document.getElementById('brain-custom-fields');
  let isBrainPresetMode = true;

  const brainPresets = {
    '3': { // Cluster 1: Relaxed Wakefulness / Occipital Alpha
      delta_power: 236.30, theta_power: 5.59, alpha_power: 3.85, beta_power: 4.95,
      gamma_power: 1.30, alpha_relative: 0.015, beta_relative: 0.020, theta_beta_ratio: 1.13,
      occipital_alpha: 4.10, frontal_asymmetry: -0.421, mean_amplitude: 4326.3,
      signal_variance: 504.0, spectral_entropy: 1.26
    },
    '2': { // Cluster 2: High-Amplitude Slow-Wave Burst
      delta_power: 248.48, theta_power: 2.76, alpha_power: 3.88, beta_power: 5.17,
      gamma_power: 1.48, alpha_relative: 0.015, beta_relative: 0.020, theta_beta_ratio: 0.53,
      occipital_alpha: 5.77, frontal_asymmetry: -0.063, mean_amplitude: 4310.2,
      signal_variance: 531.0, spectral_entropy: 1.41
    },
    '1': { // Cluster 3: Alert Cognitive Engagement
      delta_power: 3.01, theta_power: 1.48, alpha_power: 2.14, beta_power: 4.29,
      gamma_power: 1.35, alpha_relative: 0.174, beta_relative: 0.350, theta_beta_ratio: 0.35,
      occipital_alpha: 7.44, frontal_asymmetry: -0.017, mean_amplitude: 4290.4,
      signal_variance: 22.8, spectral_entropy: 3.84
    },
    'median': { // Dataset Median Profile
      delta_power: 10.39, theta_power: 3.15, alpha_power: 2.82, beta_power: 3.33,
      gamma_power: 0.94, alpha_relative: 0.118, beta_relative: 0.144, theta_beta_ratio: 0.956,
      occipital_alpha: 3.34, frontal_asymmetry: -0.004, mean_amplitude: 4299.1,
      signal_variance: 42.0, spectral_entropy: 3.58
    }
  };

  function syncBrainInputs(key) {
    const vals = brainPresets[key] || brainPresets['median'];
    if (!vals) return;
    document.getElementById('brain-delta').value = vals.delta_power;
    document.getElementById('brain-theta').value = vals.theta_power;
    document.getElementById('brain-alpha').value = vals.alpha_power;
    document.getElementById('brain-beta').value = vals.beta_power;
    document.getElementById('brain-gamma').value = vals.gamma_power;
    document.getElementById('brain-alpha-rel').value = vals.alpha_relative;
    document.getElementById('brain-beta-rel').value = vals.beta_relative;
    document.getElementById('brain-tbr').value = vals.theta_beta_ratio;
    document.getElementById('brain-occipital').value = vals.occipital_alpha;
    document.getElementById('brain-frontal-asym').value = vals.frontal_asymmetry;
    document.getElementById('brain-amplitude').value = vals.mean_amplitude;
    document.getElementById('brain-variance').value = vals.signal_variance;
    document.getElementById('brain-entropy').value = vals.spectral_entropy;
  }

  if (brainEpochSelect) {
    brainEpochSelect.addEventListener('change', () => {
      syncBrainInputs(brainEpochSelect.value);
    });
  }

  if (toggleBrainPreset && toggleBrainCustom) {
    toggleBrainPreset.addEventListener('click', () => {
      isBrainPresetMode = true;
      toggleBrainPreset.classList.add('active');
      toggleBrainCustom.classList.remove('active');
      brainPresetWrap.classList.remove('hidden');
      brainCustomGrid.classList.add('hidden');
    });
    toggleBrainCustom.addEventListener('click', () => {
      isBrainPresetMode = false;
      toggleBrainCustom.classList.add('active');
      toggleBrainPreset.classList.remove('active');
      brainPresetWrap.classList.add('hidden');
      brainCustomGrid.classList.remove('hidden');
    });
  }

  if (formBrain) {
    formBrain.addEventListener('submit', async (e) => {
      e.preventDefault();
      btnBrain.classList.add('loading');
      resBrain.innerHTML = '<div class="result-placeholder">PROCESSING REAL EEG MODEL...</div>';

      let payload = {};
      if (isBrainPresetMode && brainEpochSelect.value !== 'median') {
        payload = { epoch_id: parseInt(brainEpochSelect.value, 10) };
      } else {
        payload = {
          delta_power: parseFloat(document.getElementById('brain-delta').value),
          theta_power: parseFloat(document.getElementById('brain-theta').value),
          alpha_power: parseFloat(document.getElementById('brain-alpha').value),
          beta_power: parseFloat(document.getElementById('brain-beta').value),
          gamma_power: parseFloat(document.getElementById('brain-gamma').value),
          alpha_relative: parseFloat(document.getElementById('brain-alpha-rel').value),
          beta_relative: parseFloat(document.getElementById('brain-beta-rel').value),
          theta_beta_ratio: parseFloat(document.getElementById('brain-tbr').value),
          occipital_alpha: parseFloat(document.getElementById('brain-occipital').value),
          frontal_asymmetry: parseFloat(document.getElementById('brain-frontal-asym').value),
          mean_amplitude: parseFloat(document.getElementById('brain-amplitude').value),
          signal_variance: parseFloat(document.getElementById('brain-variance').value),
          spectral_entropy: parseFloat(document.getElementById('brain-entropy').value)
        };
      }

      try {
        const resp = await fetch('/api/brain/predict', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        const data = await resp.json();

        if (!resp.ok || data.error) {
          throw new Error(data.message || 'MODEL SERVICE UNAVAILABLE');
        }

        brainActiveCluster = data.cluster;
        brainPcaCoords = data.pca;
        document.getElementById('brain-hud').textContent = `ACTIVE PATTERN: CLUSTER ${data.cluster}`;

        const clusterColors = { 1: 'var(--c-brain)', 2: '#f59e0b', 3: 'var(--c-country)' };
        const accentClass = data.cluster === 1 ? 'accent-brain' : (data.cluster === 2 ? 'accent-f1' : 'accent-country');

        resBrain.innerHTML = `
          <div class="res-card">
            <div class="res-header">
              <span class="res-label">DISCOVERED PATTERN</span>
              <span class="view-badge">CLUSTER ${data.cluster} OF 3</span>
            </div>
            <div class="res-main-val ${accentClass}">CLUSTER ${data.cluster}</div>
            <div class="res-sub-text"><strong>${data.cluster_name || ''}</strong></div>
            <div class="res-sub-text" style="font-size: 0.8rem; color: #94a3b8; margin-top: 2px;">${data.interpretation || ''}</div>
            <div class="res-metrics-grid">
              <div class="res-metric-item">
                <div class="res-metric-k">PCA COORD X</div>
                <div class="res-metric-v">${data.pca?.x?.toFixed(4) ?? '---'}</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">PCA COORD Y</div>
                <div class="res-metric-v">${data.pca?.y?.toFixed(4) ?? '---'}</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">DIST TO C1</div>
                <div class="res-metric-v">${data.distances?.cluster_1?.toFixed(2) ?? '---'}</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">DIST TO C3</div>
                <div class="res-metric-v">${data.distances?.cluster_3?.toFixed(2) ?? '---'}</div>
              </div>
            </div>
            <div style="font-size: 0.65rem; color: #64748b; margin-top: 6px; font-family: var(--font-mono);">
              Note: Unsupervised clustering discovers latent electrophysiological states; does not constitute medical diagnosis.
            </div>
          </div>
        `;
      } catch (err) {
        resBrain.innerHTML = `<div class="error-msg">${err.message || 'Prediction unavailable.'}</div>`;
      } finally {
        btnBrain.classList.remove('loading');
      }
    });
  }


  // ---------------------------------------------------------------------------
  // 6. MODEL 2: COUNTRY DEVELOPMENT PREDICTION (POST /api/country/predict)
  // ---------------------------------------------------------------------------
  const formCountry = document.getElementById('form-country');
  const btnCountry = document.getElementById('btn-submit-country');
  const resCountry = document.getElementById('result-country');
  const countrySelect = document.getElementById('country-select');

  // Toggle modes: Lookup vs Custom Indicators
  const toggleLookup = document.getElementById('toggleCountryLookup');
  const toggleCustom = document.getElementById('toggleCountryCustom');
  const lookupWrap = document.getElementById('country-lookup-fields');
  const customGrid = document.getElementById('country-custom-fields');
  let isLookupMode = true;

  if (toggleLookup && toggleCustom) {
    toggleLookup.addEventListener('click', () => {
      isLookupMode = true;
      toggleLookup.classList.add('active');
      toggleCustom.classList.remove('active');
      lookupWrap.classList.remove('hidden');
      customGrid.classList.add('hidden');
    });
    toggleCustom.addEventListener('click', () => {
      isLookupMode = false;
      toggleCustom.classList.add('active');
      toggleLookup.classList.remove('active');
      lookupWrap.classList.add('hidden');
      customGrid.classList.remove('hidden');
    });
  }

  // Load real countries from World Bank processed dataset
  let countriesLoaded = false;
  async function loadCountriesDropdown() {
    if (countriesLoaded || !countrySelect) return;
    try {
      const resp = await fetch('/api/country/data');
      const json = await resp.json();
      if (json.data && Array.isArray(json.data)) {
        countrySelect.innerHTML = '<option value="">-- Choose a Sovereign Nation --</option>';
        json.data.sort((a, b) => a.country.localeCompare(b.country)).forEach(c => {
          const opt = document.createElement('option');
          opt.value = c.country_code;
          opt.textContent = `${c.country} (${c.country_code})`;
          countrySelect.appendChild(opt);
        });
        countriesLoaded = true;
      }
    } catch {
      countrySelect.innerHTML = '<option value="USA">United States (USA)</option><option value="DEU">Germany (DEU)</option><option value="IND">India (IND)</option>';
    }
  }

  if (formCountry) {
    formCountry.addEventListener('submit', async (e) => {
      e.preventDefault();
      btnCountry.classList.add('loading');
      resCountry.innerHTML = '<div class="result-placeholder">CALCULATING DEVELOPMENT TIER...</div>';

      let payload = {};
      if (isLookupMode) {
        const code = countrySelect.value;
        if (!code) {
          resCountry.innerHTML = '<div class="error-msg">Please select a country from the dropdown.</div>';
          btnCountry.classList.remove('loading');
          return;
        }
        payload = { country_code: code };
      } else {
        payload = {
          gdp_per_capita: parseFloat(document.getElementById('country-gdp').value),
          life_expectancy: parseFloat(document.getElementById('country-life').value),
          total_population: parseFloat(document.getElementById('country-pop').value),
          unemployment_rate: parseFloat(document.getElementById('country-unemp').value),
          infant_mortality: parseFloat(document.getElementById('country-infant').value),
          health_expenditure_pct_gdp: parseFloat(document.getElementById('country-health').value),
          education_expenditure_pct_gdp: parseFloat(document.getElementById('country-edu').value),
          internet_usage_pct: parseFloat(document.getElementById('country-internet').value)
        };
      }

      try {
        const resp = await fetch('/api/country/predict', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        const data = await resp.json();

        if (!resp.ok || data.error) {
          throw new Error(data.message || 'MODEL SERVICE UNAVAILABLE');
        }

        countryTier = data.cluster;
        document.getElementById('country-hud').textContent = `ASSIGNED DEVELOPMENT: TIER ${data.cluster}`;

        resCountry.innerHTML = `
          <div class="res-card">
            <div class="res-header">
              <span class="res-label">${data.matched_country ? data.matched_country.toUpperCase() : 'DEVELOPMENT CLUSTER'}</span>
              <span class="view-badge">TIER ${data.cluster} OF 3</span>
            </div>
            <div class="res-main-val accent-country">${data.tier_name || `TIER ${data.cluster}`}</div>
            <div class="res-metrics-grid">
              <div class="res-metric-item">
                <div class="res-metric-k">PCA COORDINATE X</div>
                <div class="res-metric-v">${data.pca?.x?.toFixed(4) ?? '---'}</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">PCA COORDINATE Y</div>
                <div class="res-metric-v">${data.pca?.y?.toFixed(4) ?? '---'}</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">TIER AVG GDP</div>
                <div class="res-metric-v">$${Math.round(data.cluster_profile?.mean_gdp || 0).toLocaleString()}</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">TIER LIFE EXP</div>
                <div class="res-metric-v">${(data.cluster_profile?.mean_life_expectancy || 0).toFixed(1)} yrs</div>
              </div>
            </div>
          </div>
        `;
      } catch (err) {
        resCountry.innerHTML = `<div class="error-msg">${err.message || 'Prediction unavailable.'}</div>`;
      } finally {
        btnCountry.classList.remove('loading');
      }
    });
  }


  // ---------------------------------------------------------------------------
  // 7. MODEL 3: FORMULA 1 PREDICTION (POST /api/f1/predict)
  // ---------------------------------------------------------------------------
  const formF1 = document.getElementById('form-f1');
  const btnF1 = document.getElementById('btn-submit-f1');
  const resF1 = document.getElementById('result-f1');

  // Mode Toggle: Presets vs Custom
  const toggleF1Preset = document.getElementById('toggleF1Preset');
  const toggleF1Custom = document.getElementById('toggleF1Custom');
  const f1PresetWrap = document.getElementById('f1-preset-wrap');
  const f1PresetSelect = document.getElementById('f1-preset-select');
  const f1GridInput = document.getElementById('f1-grid');
  const f1GridIndicator = document.getElementById('f1-grid-indicator');

  const f1Presets = {
    verstappen_aut: { grid: 1, quali: 1, delta: 0.000, driver_pts: 195.0, cons_pts: 321.0, round: 9 },
    hamilton_bra: { grid: 10, quali: 1, delta: 0.438, driver_pts: 293.5, cons_pts: 521.5, round: 19 },
    leclerc_bhr: { grid: 1, quali: 1, delta: 0.000, driver_pts: 0.0, cons_pts: 0.0, round: 1 },
    alonso_bhr: { grid: 5, quali: 5, delta: 0.628, driver_pts: 0.0, cons_pts: 0.0, round: 1 },
    norris_gbr: { grid: 2, quali: 2, delta: 0.241, driver_pts: 12.0, cons_pts: 29.0, round: 10 },
    midfield_alpine: { grid: 11, quali: 11, delta: 1.150, driver_pts: 14.0, cons_pts: 28.0, round: 8 },
    backmarker: { grid: 19, quali: 19, delta: 2.150, driver_pts: 0.0, cons_pts: 0.0, round: 14 },
    median: { grid: 10, quali: 10, delta: 0.850, driver_pts: 25.0, cons_pts: 60.0, round: 8 }
  };

  function updateF1GridPill(val) {
    if (!f1GridIndicator) return;
    const g = parseInt(val, 10);
    const row = Math.ceil(g / 2);
    if (g === 1) f1GridIndicator.textContent = 'ROW 1 • POLE POSITION';
    else if (g === 2) f1GridIndicator.textContent = 'ROW 1 • FRONT ROW';
    else if (g <= 4) f1GridIndicator.textContent = `ROW ${row} • SECOND ROW`;
    else if (g <= 10) f1GridIndicator.textContent = `ROW ${row} • TOP 10`;
    else if (g <= 16) f1GridIndicator.textContent = `ROW ${row} • MIDFIELD`;
    else f1GridIndicator.textContent = `ROW ${row} • BACKMARKER`;
  }

  if (f1GridInput) {
    f1GridInput.addEventListener('input', (e) => updateF1GridPill(e.target.value));
  }

  if (toggleF1Preset && toggleF1Custom && f1PresetWrap) {
    toggleF1Preset.addEventListener('click', () => {
      toggleF1Preset.classList.add('active');
      toggleF1Custom.classList.remove('active');
      f1PresetWrap.classList.remove('hidden');
    });
    toggleF1Custom.addEventListener('click', () => {
      toggleF1Custom.classList.add('active');
      toggleF1Preset.classList.remove('active');
      f1PresetWrap.classList.add('hidden');
    });
  }

  if (f1PresetSelect) {
    f1PresetSelect.addEventListener('change', (e) => {
      const p = f1Presets[e.target.value];
      if (p) {
        document.getElementById('f1-grid').value = p.grid;
        document.getElementById('f1-quali').value = p.quali;
        document.getElementById('f1-delta').value = p.delta.toFixed(3);
        document.getElementById('f1-driver-pts').value = p.driver_pts.toFixed(1);
        document.getElementById('f1-cons-pts').value = p.cons_pts.toFixed(1);
        document.getElementById('f1-round').value = p.round;
        updateF1GridPill(p.grid);
      }
    });
  }

  // F1 Tabs: Silhouette vs Blueprint
  const tabSil = document.getElementById('tabF1Silhouette');
  const tabBp = document.getElementById('tabF1Blueprint');
  const sceneSil = document.getElementById('f1SceneSilhouette');
  const sceneBp = document.getElementById('f1SceneBlueprint');
  const stageStatus = document.getElementById('f1StageStatus');

  if (tabSil && tabBp) {
    tabSil.addEventListener('click', () => {
      tabSil.classList.add('active');
      tabBp.classList.remove('active');
      if (sceneSil) sceneSil.classList.add('active');
      if (sceneBp) sceneBp.classList.remove('active');
      if (stageStatus) stageStatus.textContent = 'AERODYNAMIC STREAMLINES ACTIVE';
    });

    tabBp.addEventListener('click', () => {
      tabBp.classList.add('active');
      tabSil.classList.remove('active');
      if (sceneBp) sceneBp.classList.add('active');
      if (sceneSil) sceneSil.classList.remove('active');
      if (stageStatus) stageStatus.textContent = 'CAD DRAFT SPECIFICATION (1:20)';
    });
  }

  // Hotspot Inspection Tooltip
  const hotspotCard = document.getElementById('f1HotspotCard');
  document.querySelectorAll('.f1-hotspot').forEach(spot => {
    spot.addEventListener('mouseenter', () => {
      const title = spot.dataset.title || 'TELEMETRY';
      const desc = spot.dataset.desc || '';
      if (hotspotCard) {
        hotspotCard.innerHTML = `
          <span class="hotspot-card-title">${title}</span>
          <span class="hotspot-card-desc">${desc}</span>
        `;
      }
    });
  });

  // FIA 5-Light Gantry Animation
  async function triggerFiaStartGantry() {
    const lights = [
      document.getElementById('gLight1'),
      document.getElementById('gLight2'),
      document.getElementById('gLight3'),
      document.getElementById('gLight4'),
      document.getElementById('gLight5')
    ];
    const status = document.getElementById('gantryStatus');

    lights.forEach(l => l && l.classList.remove('lit'));
    if (status) status.textContent = 'GRID FORMATION COMPLETE • ILLUMINATING GANTRY...';

    for (let i = 0; i < lights.length; i++) {
      await new Promise(r => setTimeout(r, 100));
      if (lights[i]) lights[i].classList.add('lit');
    }

    if (status) status.textContent = 'ALL 5 RED LIGHTS ILLUMINATED...';
    await new Promise(r => setTimeout(r, 220));

    // Lights out!
    lights.forEach(l => l && l.classList.remove('lit'));
    if (status) status.textContent = 'LIGHTS OUT AND AWAY WE GO!';
  }

  if (formF1) {
    formF1.addEventListener('submit', async (e) => {
      e.preventDefault();
      const f1View = document.getElementById('modelView-f1');
      if (f1View) f1View.classList.add('f1-simulating');
      btnF1.classList.add('loading');
      resF1.innerHTML = '<div class="result-placeholder">INITIALIZING TELEMETRY SIMULATION...</div>';

      const gantryPromise = triggerFiaStartGantry();

      const payload = {
        grid_position: parseInt(document.getElementById('f1-grid').value, 10),
        qualifying_position: parseInt(document.getElementById('f1-quali').value, 10),
        q_delta_to_pole: parseFloat(document.getElementById('f1-delta').value),
        driver_previous_points: parseFloat(document.getElementById('f1-driver-pts').value),
        constructor_previous_points: parseFloat(document.getElementById('f1-cons-pts').value),
        round: parseInt(document.getElementById('f1-round').value, 10)
      };

      try {
        const [resp] = await Promise.all([
          fetch('/api/f1/predict', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
          }),
          gantryPromise
        ]);

        const data = await resp.json();

        if (!resp.ok || data.error) {
          throw new Error(data.message || 'MODEL SERVICE UNAVAILABLE');
        }

        f1PredictedPts = data.predicted_points;
        const pts = data.predicted_points;
        document.getElementById('f1-hud').textContent = `PROJECTED RACE FINISH: ${pts.toFixed(2)} PTS (START: P${payload.grid_position})`;

        let badgeClass = 'badge-nopoints';
        let badgeText = 'NON-SCORING FINISH (P11+)';
        if (pts >= 22) {
          badgeClass = 'badge-p1';
          badgeText = 'P1 VICTORY PROJECTED';
        } else if (pts >= 14) {
          badgeClass = 'badge-podium';
          badgeText = 'PODIUM FINISH (P2 - P3)';
        } else if (pts >= 8) {
          badgeClass = 'badge-points';
          badgeText = 'STRONG POINTS (P4 - P6)';
        } else if (pts >= 1) {
          badgeClass = 'badge-points';
          badgeText = 'LOWER POINTS (P7 - P10)';
        }

        const lowerVal = data.confidence_interval?.lower ?? 0;
        const upperVal = data.confidence_interval?.upper ?? 25;
        const lowerPct = Math.max(0, Math.min(100, (lowerVal / 25) * 100));
        const upperPct = Math.max(0, Math.min(100, (upperVal / 25) * 100));
        const estPct = Math.max(0, Math.min(100, (pts / 25) * 100));
        const bandWidth = Math.max(2, upperPct - lowerPct);

        resF1.innerHTML = `
          <div class="res-card">
            <div class="res-header">
              <span class="res-label">PROJECTED FINISH POSITION</span>
              <span class="f1-podium-badge ${badgeClass}">${badgeText}</span>
            </div>
            <div class="res-main-val accent-f1">${pts.toFixed(2)} <span style="font-size: 1.2rem; color: #ff4d6d;">PTS</span></div>
            <div class="res-sub-text">Expected Championship haul from P${payload.grid_position} start, Round ${payload.round} machinery.</div>

            <!-- 95% Confidence Interval Motorsport Track Bar -->
            <div class="f1-ci-track">
              <div class="f1-ci-labels">
                <span>0 PTS (P11+)</span>
                <span>P10 (1 PT)</span>
                <span>PODIUM (15 PTS)</span>
                <span>P1 WIN (25 PTS)</span>
              </div>
              <div class="f1-track-groove">
                <div class="f1-track-band" style="left: ${lowerPct}%; width: ${bandWidth}%;"></div>
                <div class="f1-track-needle" style="left: ${estPct}%;"></div>
              </div>
            </div>

            <div class="res-metrics-grid">
              <div class="res-metric-item">
                <div class="res-metric-k">95% LOWER BOUND</div>
                <div class="res-metric-v">${lowerVal.toFixed(2)} PTS</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">95% UPPER BOUND</div>
                <div class="res-metric-v">${upperVal.toFixed(2)} PTS</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">RAW REGRESSION FIT</div>
                <div class="res-metric-v">${data.raw_fit?.toFixed(2) ?? '---'}</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">POLE DELTA GAP</div>
                <div class="res-metric-v">+${payload.q_delta_to_pole.toFixed(3)}s</div>
              </div>
            </div>
            <div style="font-size: 0.65rem; color: #64748b; margin-top: 4px; font-family: var(--font-mono);">
              OLS Engine: Grid Penalty β₁=-0.30 • Driver Form β₄=+0.037 • Test R²=0.564 (Out-of-Sample Ground Effect Era).
            </div>
          </div>
        `;
      } catch (err) {
        resF1.innerHTML = `<div class="error-msg">${err.message || 'Prediction unavailable.'}</div>`;
      } finally {
        btnF1.classList.remove('loading');
        if (f1View) f1View.classList.remove('f1-simulating');
      }
    });
  }


  // ---------------------------------------------------------------------------
  // 8. MODEL 4: STUDENT PLACEMENT (POST /api/placement/predict)
  // ---------------------------------------------------------------------------
  const formPlacement = document.getElementById('form-placement');
  const btnPlacement = document.getElementById('btn-submit-placement');
  const resPlacement = document.getElementById('result-placement');

  if (formPlacement) {
    formPlacement.addEventListener('submit', async (e) => {
      e.preventDefault();
      btnPlacement.classList.add('loading');
      resPlacement.innerHTML = '<div class="result-placeholder">EVALUATING LOGISTIC SIGMOID CURVE...</div>';

      const payload = {
        ssc_percentage: parseFloat(document.getElementById('place-ssc').value),
        hsc_percentage: parseFloat(document.getElementById('place-hsc').value),
        degree_percentage: parseFloat(document.getElementById('place-degree').value),
        work_experience: parseInt(document.getElementById('place-workex').value, 10),
        aptitude_test_percentage: parseFloat(document.getElementById('place-etest').value),
        mba_percentage: parseFloat(document.getElementById('place-mba').value),
        mba_specialisation: document.getElementById('place-spec').value,
        degree_field: document.getElementById('place-field').value
      };

      try {
        const resp = await fetch('/api/placement/predict', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        const data = await resp.json();

        if (!resp.ok || data.error) {
          throw new Error(data.message || 'MODEL SERVICE UNAVAILABLE');
        }

        placementTargetProb = data.probability;
        const isPlaced = data.prediction === 1;
        const probPct = (data.probability * 100).toFixed(1);

        document.getElementById('placement-hud').textContent = `DECISION: ${data.label.toUpperCase()} (${probPct}%)`;

        resPlacement.innerHTML = `
          <div class="res-card">
            <div class="res-header">
              <span class="res-label">EMPLOYABILITY OUTCOME</span>
              <span class="view-badge">THRESHOLD: 50.0%</span>
            </div>
            <div class="res-main-val ${isPlaced ? 'accent-placement' : 'accent-danger'}">${data.label.toUpperCase()}</div>
            <div class="res-sub-text">Predicted placement probability: <strong>${probPct}%</strong> based on academic performance and work history.</div>
            <div class="res-metrics-grid">
              <div class="res-metric-item">
                <div class="res-metric-k">PROBABILITY</div>
                <div class="res-metric-v">${probPct}%</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">BINARY CLASS</div>
                <div class="res-metric-v">${data.prediction}</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">WORK EXP ODDS</div>
                <div class="res-metric-v">9.99x</div>
              </div>
              <div class="res-metric-item">
                <div class="res-metric-k">DECISION BOUND</div>
                <div class="res-metric-v">&ge; 0.50</div>
              </div>
            </div>
          </div>
        `;
      } catch (err) {
        resPlacement.innerHTML = `<div class="error-msg">${err.message || 'Prediction unavailable.'}</div>`;
      } finally {
        btnPlacement.classList.remove('loading');
      }
    });
  }

});
