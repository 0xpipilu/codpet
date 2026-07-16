const INLINED_PETS = [];

      const galleryEl = document.getElementById("gallery");
      let allPets = [];

      const FA = { frameWidth: 192, frameHeight: 208, sheetWidth: 1536, sheetHeight: 1872 };

      const DEFAULT_ROWS = [
        { rowIndex: 0, frames: 6 },
        { rowIndex: 1, frames: 8 },
        { rowIndex: 2, frames: 8 },
        { rowIndex: 3, frames: 4 },
        { rowIndex: 4, frames: 5 },
        { rowIndex: 5, frames: 8 },
        { rowIndex: 6, frames: 6 },
        { rowIndex: 7, frames: 6 },
        { rowIndex: 8, frames: 6 }
      ];

      // Dynamically load JSZip library from CDN only on demand when a download is requested
      function loadJSZip() {
        if (window.JSZip) return Promise.resolve();
        return new Promise((resolve, reject) => {
          const script = document.createElement("script");
          script.src = "https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js";
          script.onload = resolve;
          script.onerror = reject;
          document.body.appendChild(script);
        });
      }

      function esc(t) { return String(t ?? "").replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;"); }
      function getPet(s) { return allPets.find(p => p.slug === s) || null; }
      function getRows(p) {
        if (!p) return DEFAULT_ROWS;
        return Array.isArray(p.previewRows) && p.previewRows.length ? p.previewRows : DEFAULT_ROWS;
      }

      const DL_ICON = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`;

      function getMockDownloadCount(slug) {
        return parseInt(localStorage.getItem(`dl_${slug}`) || "0", 10);
      }

      function getDisplayDownloadCount(slug) {
        if (window.globalStats && window.globalStats.downloads && typeof window.globalStats.downloads[slug] === "number") {
          return window.globalStats.downloads[slug];
        }
        return getMockDownloadCount(slug);
      }

      /* ---- Sprite engine ---- */
      async function loadSprite(el, onProgress, callback) {
        if (el._loaded) {
          if (callback) callback();
          return;
        }
        const a = el._atlas;
        try {
          const response = await fetch(a.src);
          if (!response.ok) throw new Error("Network response was not ok");
          
          const contentLength = response.headers.get('content-length');
          if (!contentLength) {
            el.style.backgroundImage = `url("${encodeURI(a.src)}")`;
            el.style.backgroundSize  = a.sw * a.s + "px " + a.sh * a.s + "px";
            el._loaded = true;
            if (onProgress) onProgress(100);
            if (callback) callback();
            return;
          }
          
          const total = parseInt(contentLength, 10);
          let loaded = 0;
          const reader = response.body.getReader();
          const chunks = [];
          
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            chunks.push(value);
            loaded += value.length;
            const pct = Math.round((loaded / total) * 100);
            if (onProgress) onProgress(pct);
          }
          
          const blob = new Blob(chunks);
          const blobUrl = URL.createObjectURL(blob);
          el.style.backgroundImage = `url("${blobUrl}")`;
          el.style.backgroundSize  = a.sw * a.s + "px " + a.sh * a.s + "px";
          el._loaded = true;
          if (callback) callback();
        } catch (e) {
          console.error("Failed to load spritesheet with progress:", e);
          const img = new Image();
          img.src = a.src;
          img.onload = () => {
            el.style.backgroundImage = `url("${encodeURI(a.src)}")`;
            el.style.backgroundSize  = a.sw * a.s + "px " + a.sh * a.s + "px";
            el._loaded = true;
            if (onProgress) onProgress(100);
            if (callback) callback();
          };
        }
      }

      function showFrame(el, rowIndex, frameIndex) {
        const a = el._atlas;
        el.style.backgroundPosition =
          (-frameIndex * a.fw * a.s) + "px " + (-rowIndex * a.fh * a.s) + "px";
      }


      /* ---- Hover: accelerated all-state cycling ---- */
      function startHover(tile) {
        // 1. Cancel any existing animation loop immediately to prevent duplicate/orphan loops
        if (tile._anim) {
          cancelAnimationFrame(tile._anim);
          tile._anim = null;
        }

        // Increment hover session ID to invalidate any stale asynchronous callbacks from previous hovers
        tile._hoverSession = (tile._hoverSession || 0) + 1;
        const currentSession = tile._hoverSession;

        const el = tile._spritePlayer;
        const pet = getPet(tile.dataset.slug);
        if (!el || !pet) return;

        const rows = getRows(pet);
        if (!rows.length) return;

        const msPerRow = 350;
        const totalDur = msPerRow * rows.length;
        let t0 = null;

        function tick(now) {
          if (tile._hoverSession !== currentSession || !tile._isHovered) {
            stopHover(tile);
            return;
          }
          if (t0 === null) t0 = now;
          const elapsed = Math.max(0, now - t0) % totalDur;
          const idx = Math.floor(elapsed / msPerRow) % rows.length;
          const row = rows[idx];
          if (!row) {
            tile._anim = requestAnimationFrame(tick);
            return;
          }
          const frames = Math.max(1, row.frames);
          const rowProgress = (elapsed % msPerRow) / msPerRow;
          const fi = Math.min(frames - 1, Math.floor(rowProgress * frames));
          showFrame(el, row.rowIndex, fi);
          tile._anim = requestAnimationFrame(tick);
        }

        // Always set the loading class to trigger the elegant rising steam particles!
        tile.classList.add("loading");

        // Dynamically inject the 5 wispy steam particles to keep the initial DOM tree light and clean
        let steamContainer = tile.querySelector(".steam-container");
        if (!steamContainer) {
          const stage = tile.querySelector(".tile-stage");
          if (stage) {
            steamContainer = document.createElement("div");
            steamContainer.className = "steam-container";
            for (let i = 1; i <= 5; i++) {
              const puff = document.createElement("div");
              puff.className = `steam-puff steam-${i}`;
              steamContainer.appendChild(puff);
            }
            stage.appendChild(steamContainer);
          }
        }
        
        const colorEl = tile._spriteStaticColor;
        if (colorEl) {
          colorEl.style.animation = "none";
          colorEl.style.transition = "none";
          colorEl.style.clipPath = "inset(100% 0 0 0)";
        }

        let targetPct = el._loaded ? 100 : 0;
        const hoverStartTime = Date.now();
        const minDefrostDuration = 450; // Guarantee at least 450ms of steam & defrost visibility!

        // Smooth, mathematically guaranteed non-snapping defrost update loop
        function updateDefrost() {
          if (tile._hoverSession !== currentSession || !tile._isHovered) return;

          const elapsed = Date.now() - hoverStartTime;
          // Calculate visual progress: smooth rise from 0 to 100, capped at current download targetPct
          const currentPct = Math.min((elapsed / minDefrostDuration) * 100, targetPct);

          if (colorEl) {
            colorEl.style.clipPath = `inset(${100 - currentPct}% 0 0 0)`;
          }

          // Continue the loop only while the card is actively loading/defrosting
          if (tile.classList.contains("loading")) {
            requestAnimationFrame(updateDefrost);
          }
        }
        requestAnimationFrame(updateDefrost);

        loadSprite(
          el,
          (pct) => {
            // Cancel progress if hover session has changed
            if (tile._hoverSession !== currentSession) return;
            targetPct = pct;
          },
          async () => {
            targetPct = 100; // Guarantee target is 100% on complete

            // Wait until the minimum defrost time has elapsed (e.g. 450ms)
            const timeElapsed = Date.now() - hoverStartTime;
            const remainingTime = Math.max(0, minDefrostDuration - timeElapsed);
            await new Promise(r => setTimeout(r, remainingTime));

            // Cancel completion if hover session has changed
            if (tile._hoverSession !== currentSession) return;

            // Hide the steam container and update active rendering states
            tile.classList.remove("loading");
            const activeSteam = tile.querySelector(".steam-container");
            if (activeSteam) activeSteam.remove();
            
            // Double check hover state before starting the loop
            if (!tile._isHovered) {
              tile.classList.remove("playing");
              if (colorEl) {
                colorEl.style.animation = "";
                colorEl.style.transition = "";
                colorEl.style.clipPath = "";
              }
              return;
            }
            
            tile.classList.add("playing");
            // Double check to prevent starting another loop if one was started concurrently
            if (tile._anim) {
              cancelAnimationFrame(tile._anim);
            }
            tile._anim = requestAnimationFrame(tick);
          }
        );
      }

      function stopHover(tile) {
        tile._hoverSession = 0; // Invalidate any running session instantly
        tile.classList.remove("loading");
        tile.classList.remove("playing");
        
        // Remove steam elements from the DOM tree completely
        const activeSteam = tile.querySelector(".steam-container");
        if (activeSteam) activeSteam.remove();

        if (tile._anim) {
          cancelAnimationFrame(tile._anim);
          tile._anim = null;
        }
        const colorEl = tile._spriteStaticColor;
        if (colorEl) {
          // Snap back to grayscale instantly on leave by clearing inline styles to default CSS
          colorEl.style.animation = "";
          colorEl.style.transition = "";
          colorEl.style.clipPath = "";
        }
      }

      /* ---- Download: zip pet.json + spritesheet.webp ---- */
      async function downloadPet(pet, btn) {
        btn.classList.add("busy");
        btn.textContent = "…";

        try {
          await loadJSZip(); // Ensure JSZip library is dynamically loaded on-demand
          const jsonPath = pet.petJsonPath || `pets/${pet.slug}/pet.json`;
          const spritesheetPath = pet.spritesheetFile || `pets/${pet.slug}/spritesheet.webp`;
          const [jsonResp, imgResp] = await Promise.all([
            fetch(jsonPath),
            fetch(spritesheetPath),
          ]);

          const [jsonBlob, imgBlob] = await Promise.all([
            jsonResp.blob(),
            imgResp.blob(),
          ]);

          const ext = pet.spritesheetFile.split(".").pop() || "webp";
          const zip = new JSZip();
          zip.file("pet.json", jsonBlob);
          zip.file("spritesheet." + ext, imgBlob);

          const readmeCN = `==================================================
        Codpet (像素桌面伴侣) 安装与使用说明
==================================================

这是一只精心制作的 Codpet 互动像素桌面伴侣！请按照以下简单的步骤将其安装到您的 Codex 环境中：

【第一步：解压文件】
1. 解压下载的压缩包（建议将解压后的文件夹命名为该宠物的名字，例如：${pet.slug}）。
2. 确保文件夹内部包含核心资源文件：
   - pet.json （动作与元数据配置文件）
   - spritesheet.${ext} （动画精灵图）

【第二步：放入宠物目录】
将解压后的宠物文件夹直接移动到您的 Codex 宠物存放目录下（无需重启 Codex，客户端会自动监听目录并实时热重载识别！）：

- macOS 用户：
  📂 路径：/Users/您的用户名/.codex/pets/
  💡 快捷操作：打开终端（Terminal），运行命令：open ~/.codex/pets 即可直接打开该目录，然后把宠物文件夹拖入。

- Windows 用户：
  📂 路径：C:\\Users\\您的用户名\\.codex\\pets\\
  💡 快捷操作：按下快捷键 Win + R，输入 %USERPROFILE%\\.codex\\pets 并回车，即可直接打开目录，将宠物文件夹拖入。

- Linux 用户：
  📂 路径：~/.codex/pets/

【第三步：启用并体验】
1. 打开您的 Codex 客户端 / 应用程序。
2. 依次点击导航路径进行选择：
   📌 Codex ➔ Settings (设置) ➔ Appearance (外观) ➔ Pet (宠物)
3. 在下拉菜单中选中您刚刚下载的新宠物，您的像素伴侣就会立刻在您的桌面上动起来！

--------------------------------------------------
🌐 更多宠物尽在 Codpet 官网：https://cod.pet`;

          const readmeEN = `==================================================
      Codpet Installation Guide & README
==================================================

Thank you for downloading a beautiful animated companion from Codpet! 
Follow these simple steps to install this pet in your Codex environment:

[Step 1: Extract Files]
1. Extract the downloaded zip file into a folder (we recommend naming the folder after the pet, e.g., "${pet.slug}").
2. Make sure the folder contains these key files:
   - pet.json (state and metadata configuration)
   - spritesheet.${ext} (animation spritesheet)

[Step 2: Move to the Local Pets Directory]
Move your extracted pet folder directly into the Codex local pets folder (no client restart required—the Codex app automatically watches the directory and hot-reloads it in real-time!):

- macOS:
  📂 Path: /Users/<your-username>/.codex/pets/
  💡 Quick access: Open Terminal and run: open ~/.codex/pets

- Windows:
  📂 Path: C:\\Users\\<your-username>\\.codex\\pets\\
  💡 Quick access: Press Win + R, type %USERPROFILE%\\.codex\\pets and press Enter.

- Linux:
  📂 Path: ~/.codex/pets/

[Step 3: Launch and Enjoy]
1. Open your Codex desktop application.
2. Click through the following path:
   📌 Codex ➔ Settings ➔ Appearance ➔ Pet
3. Select your new companion from the dropdown menu, and your new desktop companion will wake up on your screen!

--------------------------------------------------
🌐 Discover more pets at: https://cod.pet`;

          zip.file("安装说明.txt", readmeCN);
          zip.file("README.txt", readmeEN);

          const zipBlob = await zip.generateAsync({ type: "blob" });
          const url = URL.createObjectURL(zipBlob);
          const a = document.createElement("a");
          a.href = url;
          a.download = pet.slug + ".zip";
          document.body.appendChild(a);
          a.click();
          a.remove();
          URL.revokeObjectURL(url);

          // Increment local download count
          const extra = parseInt(localStorage.getItem(`dl_${pet.slug}`) || "0", 10) + 1;
          localStorage.setItem(`dl_${pet.slug}`, extra);

          // Increment global download count asynchronously
          fetch(`https://countapi.mileshilliard.com/api/v1/hit/codpet_dl_${pet.slug}`)
            .then(r => r.json())
            .then(data => {
              if (data && typeof data.value === "number") {
                window.globalStats.downloads[pet.slug] = data.value;
              }
            })
            .catch(err => console.error("Global increment failed:", err));

          // Google Analytics Event Tracking for Download
          if (typeof gtag === "function") {
            gtag("event", "download_pet", {
              "pet_name": pet.displayName,
              "pet_slug": pet.slug
            });
          }
        } catch (e) {
          console.error("Download failed:", e);
        }

        btn.classList.remove("busy");
        btn.innerHTML = DL_ICON;
      }

      /* ---- Render ---- */
      let renderedCount = 0;
      let galleryObserver = null;

      function renderChunk(pets, append = false) {
        const html = pets.map((pet, idx) => {
          const overallIdx = append ? renderedCount + idx : idx;
          const isLCP = overallIdx < 6;
          const loadingAttr = isLCP ? "" : 'loading="lazy"';
          const priorityAttr = isLCP ? 'fetchpriority="high"' : "";
          const isCustom = pet.isCustom ? "custom-pet" : "";
          return `
            <div class="tile ${isCustom}" data-slug="${pet.slug}">
              <div class="tile-stage">
                <!-- Evaporating Defrost Steam is dynamically injected on hover to minimize DOM size -->
                 <img class="sprite-static sprite-static-gray" width="73" height="79" ${loadingAttr} ${priorityAttr} data-pet-slug="${pet.slug}" alt="${esc(pet.displayName)} preview">
                 <img class="sprite-static sprite-static-color" width="73" height="79" loading="lazy" data-pet-slug="${pet.slug}" alt="${esc(pet.displayName)} preview colored">
                <div class="sprite-player" data-pet-slug="${pet.slug}"></div>
              </div>
              <div class="tile-label">
                <div class="tile-name">${esc(pet.displayName)}</div>
                <button type="button" class="tile-dl" data-slug="${pet.slug}" aria-label="Download ${esc(pet.displayName)}">
                  ${DL_ICON}
                </button>
              </div>
            </div>`;
        }).join("");

        if (append) {
          const temp = document.createElement("div");
          temp.innerHTML = html;
          while (temp.firstChild) {
            galleryEl.appendChild(temp.firstChild);
          }
        } else {
          galleryEl.innerHTML = html;
        }

        /* Init sprite elements with atlas data */
        const tiles = galleryEl.querySelectorAll(".tile");
        const startIndex = append ? renderedCount : 0;

        for (let i = startIndex; i < tiles.length; i++) {
          const tile = tiles[i];
          const pet = getPet(tile.dataset.slug);
          if (!pet) continue;
          const a = pet.atlas || FA;
          const row0 = getRows(pet)[0] || { rowIndex: 0 };
          const elStaticGray = tile.querySelector(".sprite-static-gray");
          const elStaticColor = tile.querySelector(".sprite-static-color");
          const elPlayer = tile.querySelector(".sprite-player");

          /* Initialize static previews (both gray and color use lossless base.webp for high performance & Retina sharpness) */
          const imgUrl = pet.previewImage || `pets/${pet.slug}/base.webp`;
          elStaticGray.src = imgUrl;
          elStaticColor.src = imgUrl;

          /* Store atlas info directly on the element */
          elPlayer._atlas = {
            src: pet.spritesheetFile || `pets/${pet.slug}/spritesheet.webp`,
            fw: a.frameWidth, fh: a.frameHeight,
            sw: a.sheetWidth, sh: a.sheetHeight,
            s: 0.38,
            defaultRow: row0.rowIndex,
          };
          elPlayer._loaded = false;

          /* Set dimensions immediately to reserve layout space */
          elPlayer.style.width  = a.frameWidth * 0.38 + "px";
          elPlayer.style.height = a.frameHeight * 0.38 + "px";

          /* Cache sprite refs on tile */
          tile._spriteStaticGray = elStaticGray;
          tile._spriteStaticColor = elStaticColor;
          tile._spritePlayer = elPlayer;
          tile._isHovered = false;

          /* Hover handlers */
          tile.addEventListener("mouseenter", () => {
            tile._isHovered = true;
            startHover(tile);
          });
          tile.addEventListener("mouseleave", () => {
            tile._isHovered = false;
            stopHover(tile);
          });
        }

        /* Download handlers */
        const dls = galleryEl.querySelectorAll(".tile-dl");
        for (let i = startIndex; i < dls.length; i++) {
          const btn = dls[i];
          btn.addEventListener("click", e => {
            e.stopPropagation();
            const pet = getPet(btn.dataset.slug);
            if (pet) downloadPet(pet, btn);
          });
        }

        renderedCount += pets.length;
      }

      function renderGallery() {
        if (!allPets.length) {
          galleryEl.innerHTML = `<div class="empty">No pets available.</div>`;
          return;
        }

        renderedCount = 0;
        
        if (window.webkit) {
          renderChunk(allPets, false);
          if (window.codpetNativeSync && window.__codpetPayload) {
            window.codpetNativeSync(window.__codpetPayload);
          }
          return;
        }

        // 1. Render first chunk (12 pets) synchronously for instant layout & paint
        renderChunk(allPets.slice(0, 12), false);

        // 2. Setup IntersectionObserver to lazy load the remaining pets on scroll
        if (allPets.length > 12) {
          // Disconnect existing observer if it was active
          if (galleryObserver) {
            galleryObserver.disconnect();
            galleryObserver = null;
          }

          const sentinel = document.createElement("div");
          sentinel.id = "gallerySentinel";
          sentinel.style.gridColumn = "1 / -1";
          sentinel.style.height = "1px";
          sentinel.style.margin = "0";
          galleryEl.appendChild(sentinel);

          let currentIndex = 12;

          if (typeof IntersectionObserver === "function") {
            galleryObserver = new IntersectionObserver((entries) => {
              if (entries[0].isIntersecting) {
                const nextChunk = allPets.slice(currentIndex, currentIndex + 20);
                
                // Remove sentinel temporarily to append tiles cleanly
                sentinel.remove();
                
                renderChunk(nextChunk, true);
                currentIndex += 20;

                if (currentIndex < allPets.length) {
                  // Re-append sentinel to the bottom
                  galleryEl.appendChild(sentinel);
                } else {
                  // All pets rendered, disconnect observer
                  galleryObserver.disconnect();
                  galleryObserver = null;
                }
              }
            }, { rootMargin: "300px" }); // Preload next chunk 300px before user scrolls to the bottom
            
            galleryObserver.observe(sentinel);
          } else {
            // Fallback for browsers without IntersectionObserver support
            setTimeout(() => {
              renderChunk(allPets.slice(12), true);
            }, 200);
          }
        }
      }

      window.globalStats = {
        downloads: {},
        pageviews: 0
      };

      async function logGlobalPageView() {
        try {
          const res = await fetch("https://countapi.mileshilliard.com/api/v1/hit/codpet_global_pageviews");
          if (res.ok) {
            const data = await res.json();
            window.globalStats.pageviews = data.value || 0;
            if (typeof window.updateAdminPanelData === "function") window.updateAdminPanelData();
          }
        } catch (e) {
          console.error("Failed to fetch global pageviews:", e);
        }
      }

      async function loadGlobalStats() {
        for (const pet of allPets) {
          try {
            const res = await fetch(`https://countapi.mileshilliard.com/api/v1/get/codpet_dl_${pet.slug}`);
            if (res.ok) {
              const data = await res.json();
              window.globalStats.downloads[pet.slug] = data.value || 0;
              if (typeof window.updateAdminPanelData === "function") window.updateAdminPanelData();
            }
          } catch (e) {
            console.error(`Failed to load global downloads for ${pet.slug}:`, e);
          }
          // 30ms delay to prevent rate limits and CPU spikes
          await new Promise(r => setTimeout(r, 30));
        }
      }

      /* ---- Boot ---- */
      (async function boot() {
        const progressBar = document.getElementById("defrostProgressBar");
        const loader = document.getElementById("defrostLoader");
        
        function setProgress(pct) {
          if (progressBar) progressBar.style.width = pct + "%";
        }
        
        try {
          // 1. Boot started: set to 25% immediately
          setProgress(25);
          
          // 2. Mid-way boot check: set to 55%
          setProgress(55);

          let catalog = typeof window.__CODEX_PETS__ === "object" && window.__CODEX_PETS__
            ? window.__CODEX_PETS__
            : null;

          let catalogFetchNeeded = false;
          if (!catalog && typeof INLINED_PETS !== "undefined" && Array.isArray(INLINED_PETS) && INLINED_PETS.length > 0) {
            catalog = { pets: INLINED_PETS };
          }

          const inlineCatalogHasAtlas = catalog && Array.isArray(catalog.pets) &&
            catalog.pets.every(p => p && p.atlas && p.atlas.sheetHeight);

          if (!inlineCatalogHasAtlas) {
            catalogFetchNeeded = true;
            catalog = await fetch("./index.json?v=20260716-frames").then(r => { if (!r.ok) throw new Error(r.status); return r.json(); });
          }

          // 3. Catalog fetched: set to 85%
          setProgress(85);

          allPets = catalog.pets || [];
          
          // Render cards first to minimize LCP delay
          renderGallery();
          document.documentElement.classList.add("loaded");
          logGlobalPageView();
          
          // 4. Completed: set to 100%
          setProgress(100);

          // If loaded instantly, bypass/shorten timeouts to show gallery immediately
          const loaderDelay = catalogFetchNeeded ? 100 : 0;
          const transitionDelay = catalogFetchNeeded ? 250 : 100;

          if (loaderDelay > 0) {
            await new Promise(r => setTimeout(r, loaderDelay));
          }
          
          // 5. Beautiful fade out and removal of the defrost loader
          if (loader) {
            if (!catalogFetchNeeded) {
              loader.style.transitionDuration = "150ms";
            }
            loader.classList.add("fade-out");
            await new Promise(r => setTimeout(r, transitionDelay)); // wait for fade out transition
            loader.remove(); // Completely remove from DOM to prevent any rendering loops or layout shifts!
          }
          
          // Page view tracking
          const views = parseInt(localStorage.getItem("page_views") || "0", 10) + 1;
          localStorage.setItem("page_views", views);

          // Admin Panel Functions
          const adminPanel = document.getElementById("adminPanel");
          const adminCloseBtn = document.getElementById("adminCloseBtn");
          const adminCloseBtn2 = document.getElementById("adminCloseBtn2");
          const adminClearBtn = document.getElementById("adminClearBtn");
          const statPageviews = document.getElementById("statPageviews");
          const statDownloads = document.getElementById("statDownloads");
          const adminDownloadsList = document.getElementById("adminDownloadsList");

          function updateAdminPanelData() {
            if (!statPageviews) return;
            statPageviews.textContent = localStorage.getItem("page_views") || "1";
            
            // Set global pageviews
            const statPageviewsGlobal = document.getElementById("statPageviewsGlobal");
            if (statPageviewsGlobal) {
              statPageviewsGlobal.textContent = window.globalStats.pageviews || "—";
            }
            
            let totalDlsLocal = 0;
            let totalDlsGlobal = 0;
            let listHtml = "";
            
            allPets.forEach(pet => {
              const countLocal = parseInt(localStorage.getItem(`dl_${pet.slug}`) || "0", 10);
              const countGlobal = window.globalStats.downloads[pet.slug] || 0;
              
              totalDlsLocal += countLocal;
              totalDlsGlobal += countGlobal;
              
              if (countLocal > 0 || countGlobal > 0) {
                listHtml += `
                  <div class="admin-list-item">
                    <span class="admin-list-name">${esc(pet.displayName)}</span>
                    <span class="admin-list-val">
                      ${countLocal} local / <strong style="color:#4CAF50;">${countGlobal} global</strong>
                    </span>
                  </div>`;
              }
            });
            
            statDownloads.textContent = totalDlsLocal;
            const statDownloadsGlobal = document.getElementById("statDownloadsGlobal");
            if (statDownloadsGlobal) {
              statDownloadsGlobal.textContent = totalDlsGlobal || "0";
            }
            
            adminDownloadsList.innerHTML = listHtml || `<div style="text-align:center; color:rgba(0,0,0,0.4); font-size:12px; padding:12px 0;">No downloads recorded yet.</div>`;
          }

          window.updateAdminPanelData = updateAdminPanelData;

          function openAdminPanel() {
            updateAdminPanelData();
            adminPanel.classList.add("active");
            loadGlobalStats();
          }

          function closeAdminPanel() {
            adminPanel.classList.remove("active");
          }

          if (adminCloseBtn) adminCloseBtn.addEventListener("click", closeAdminPanel);
          if (adminCloseBtn2) adminCloseBtn2.addEventListener("click", closeAdminPanel);
          
          if (adminClearBtn) {
            adminClearBtn.addEventListener("click", () => {
              if (confirm("Are you sure you want to reset all local pageviews and download statistics?")) {
                allPets.forEach(pet => localStorage.removeItem(`dl_${pet.slug}`));
                localStorage.setItem("page_views", "1");
                closeAdminPanel();
                location.reload();
              }
            });
          }

          // Show panel if ?admin=true is in URL
          if (new URLSearchParams(window.location.search).get("admin") === "true") {
            setTimeout(openAdminPanel, 500);
          }

          // Secret double-click trigger on the footer logo
          const footerLogo = document.querySelector(".footer .logo");
          if (footerLogo) {
            footerLogo.addEventListener("click", (e) => {
              // Prevent standard click navigation to allow dblclick to fire cleanly
              e.preventDefault();
            });
            footerLogo.addEventListener("dblclick", (e) => {
              e.preventDefault();
              openAdminPanel();
            });
            footerLogo.title = "Double-click to open local Admin Dashboard";
          }
        } catch (e) {
          console.error(e);
          galleryEl.innerHTML = `<div class="empty">Could not load catalog.</div>`;
        }
      })();
