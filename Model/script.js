/**
 * AI Road Damage Detector - Main Application Logic
 * Integrates Leaflet, Canvas Overlays, WebRTC Camera, and Mock AI Data.
 */

// ==========================================
// STATE & CONFIG
// ==========================================
const STORAGE_KEY = 'road_damage_history_v1';
const SETTING_KEY = 'road_damage_settings_v1';

let appState = {
    history: [],
    settings: {
        threshold: 0.6,
        simBle: true,
        alerts: true,
        email: '',
        alertLevel: 'Low' // Low, Medium, High
    },
    isDetecting: false,
    cameraStream: null,
    detectionIntervalId: null,
    bleIntervalId: null,
    currentLocation: { lat: 37.7749, lng: -122.4194 } // Default standard location for simulation
};

const DAMAGE_CLASSES = ['Pothole', 'Crack', 'Alligator Crack'];
let leafletMap = null;
let markersLayer = null;

// ==========================================
// DOM ELEMENTS
// ==========================================
const DOM = {
    splash: document.getElementById('splash-screen'),
    app: document.getElementById('app-container'),
    navBtns: document.querySelectorAll('.nav-btn'),
    sections: document.querySelectorAll('.page-section'),
    themeToggle: document.getElementById('theme-toggle'),

    // Video/Camera
    video: document.getElementById('live-video'),
    pythonImg: document.getElementById('python-video'),
    canvas: document.getElementById('detection-overlay'),
    camMessage: document.getElementById('camera-overlay-message'),
    btnStart: document.getElementById('btn-start-detection'),
    btnStartHome: document.getElementById('btn-start-detection-home'),
    btnStop: document.getElementById('btn-stop-detection'),
    btnManualCap: document.getElementById('btn-capture-manual'),
    bleLog: document.getElementById('ble-mock-console'),
    fpsCounter: document.getElementById('cam-fps'),

    // Dashboard
    statTotal: document.getElementById('stat-total'),
    statPotholes: document.getElementById('stat-potholes'),
    statStatus: document.getElementById('stat-status'),
    homeList: document.getElementById('home-recent-alerts'),
    bleText: document.getElementById('ble-text'),
    bleDot: document.getElementById('ble-dot'),

    // Settings
    sThreshold: document.getElementById('setting-threshold'),
    sThresholdVal: document.getElementById('threshold-val'),
    sSimBle: document.getElementById('setting-sim-ble'),
    sAlerts: document.getElementById('setting-alerts'),
    sEmail: document.getElementById('setting-email'),
    sLevel: document.getElementById('setting-alert-level'),
    btnSaveSettings: document.getElementById('btn-save-settings'),

    // History
    historyBody: document.getElementById('history-tbody'),
    viewToggles: document.querySelectorAll('.toggle-btn'),
    viewTable: document.getElementById('history-table-view'),
    viewMap: document.getElementById('history-map-view'),
    btnClearHistory: document.getElementById('btn-clear-history'),
    btnExportCsv: document.getElementById('btn-export-csv'),

    // Modal
    modal: document.getElementById('detail-modal'),
    btnCloseModal: document.getElementById('btn-close-modal'),
    btnDismissModal: document.getElementById('btn-dismiss-modal'),
};

// ==========================================
// INITIALIZATION
// ==========================================
document.addEventListener('DOMContentLoaded', initApp);

function initApp() {
    loadSettings();
    loadHistory();
    setupEventListeners();

    // Simulate initial loading flow
    setTimeout(() => {
        DOM.splash.classList.remove('active');
        DOM.app.classList.remove('hidden');
        navigateTo('home');
        updateDashboard();

        if (appState.settings.simBle) {
            connectMockBle();
        }
    }, 1500);
}

// ==========================================
// NAVIGATION & UI
// ==========================================
function setupEventListeners() {
    // Nav
    DOM.navBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            const target = btn.getAttribute('data-target');
            navigateTo(target);

            // Auto-start camera when navigating to the Live Detection tab
            if (target === 'camera') {
                startDetectionSystem();
            }
        });
    });

    // Theme
    DOM.themeToggle.addEventListener('click', toggleTheme);

    // Settings
    DOM.sThreshold.addEventListener('input', (e) => DOM.sThresholdVal.innerText = parseFloat(e.target.value).toFixed(2));
    DOM.btnSaveSettings.addEventListener('click', saveSettings);

    // Camera actions
    DOM.btnStart.addEventListener('click', startDetectionSystem);
    DOM.btnStartHome.addEventListener('click', () => {
        navigateTo('camera');
        startDetectionSystem();
    });
    DOM.btnStop.addEventListener('click', stopDetectionSystem);
    DOM.btnManualCap.addEventListener('click', triggerManualCapture);

    // History Actions
    DOM.viewToggles.forEach(btn => {
        btn.addEventListener('click', () => switchHistoryView(btn.dataset.view));
    });
    DOM.btnClearHistory.addEventListener('click', clearHistory);
    DOM.btnExportCsv.addEventListener('click', exportCsv);

    // Modal
    DOM.btnCloseModal.addEventListener('click', closeModal);
    DOM.btnDismissModal.addEventListener('click', closeModal);
}

function navigateTo(sectionId) {
    // Update active nav button
    DOM.navBtns.forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-target') === sectionId);
    });

    // Update active section
    DOM.sections.forEach(sec => {
        sec.classList.remove('active');
        if (sec.id === sectionId) {
            sec.classList.add('active');

            // Re-render map if activating history tab to fix Leaflet size bug
            if (sectionId === 'history') {
                setTimeout(() => {
                    if (!leafletMap) initMap();
                    else leafletMap.invalidateSize();
                }, 100);
            }
        }
    });
}

function toggleTheme() {
    const html = document.documentElement;
    const currentTheme = html.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', newTheme);
    DOM.themeToggle.innerHTML = newTheme === 'dark' ? '<i class="fa-solid fa-moon"></i>' : '<i class="fa-solid fa-sun"></i>';
}

function showToast(message, type = 'success') {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;

    let icon = 'fa-check-circle';
    if (type === 'error') icon = 'fa-circle-xmark';
    if (type === 'warning') icon = 'fa-triangle-exclamation';

    toast.innerHTML = `<i class="fa-solid ${icon}"></i> <span>${message}</span>`;
    container.appendChild(toast);

    // Animate in
    setTimeout(() => toast.classList.add('show'), 10);

    // Remove after 3s
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// ==========================================
// CORE LOGIC: CAMERA & AI OVERLAY
// ==========================================
async function startDetectionSystem() {
    if (appState.isDetecting) return;

    try {
        // Trigger Python to start OpenCV camera
        const response = await fetch('/start_engine', { method: 'POST' });
        if (!response.ok) throw new Error("Ensure 'app.py' Flask server is running!");

        // Start MJPEG stream
        DOM.pythonImg.src = '/video_feed';
        DOM.pythonImg.classList.remove('hidden');
        if (DOM.video) DOM.video.classList.add('hidden');

        DOM.pythonImg.onload = () => {
            DOM.canvas.width = DOM.pythonImg.clientWidth;
            DOM.canvas.height = DOM.pythonImg.clientHeight;
        };

        DOM.camMessage.classList.add('hidden');
        DOM.btnStart.disabled = true;
        DOM.btnStop.disabled = false;
        DOM.btnManualCap.disabled = false;

        appState.isDetecting = true;
        DOM.statStatus.innerText = 'Detecting';
        DOM.statStatus.className = 'text-warning text-sm title-case';

        showToast('Native Python Camera and AI systems online');

        // Main AI detection loop (Simulation)
        appState.detectionIntervalId = setInterval(processFrame, 2000); // Process every 2 seconds

        // Handle Location (Real GPS or Simulated ESP32)
        if (!appState.settings.simBle && navigator.geolocation) {
            navigator.geolocation.watchPosition((pos) => {
                appState.currentLocation.lat = pos.coords.latitude;
                appState.currentLocation.lng = pos.coords.longitude;
                DOM.bleLog.innerHTML = `<span class="text-success">[REAL GPS] Lat: ${pos.coords.latitude.toFixed(4)}, Lng: ${pos.coords.longitude.toFixed(4)}</span>`;
            }, (err) => {
                DOM.bleLog.innerHTML = `<span class="text-error">[GPS ERR] Unable to fetch real location</span>`;
            }, { enableHighAccuracy: true });
        } else if (appState.settings.simBle) {
            animateSimulatedBleConsole();
        }

    } catch (err) {
        console.error("Camera access denied or unavailable", err);
        showToast('Camera access denied or unavailable! Is the Flask server running?', 'error');
    }
}

async function stopDetectionSystem() {
    if (!appState.isDetecting) return;

    // Trigger Python to release the camera
    try {
        await fetch('/stop_engine', { method: 'POST' });
    } catch (e) { console.warn("Failed to ping stop_engine backend", e); }

    // Clear MJPEG stream to stop constant loading
    DOM.pythonImg.src = '';
    DOM.pythonImg.classList.add('hidden');

    clearInterval(appState.detectionIntervalId);
    appState.isDetecting = false;

    // Clear canvas
    const ctx = DOM.canvas.getContext('2d');
    ctx.clearRect(0, 0, DOM.canvas.width, DOM.canvas.height);

    DOM.camMessage.classList.remove('hidden');
    DOM.btnStart.disabled = false;
    DOM.btnStop.disabled = true;
    DOM.btnManualCap.disabled = true;

    DOM.statStatus.innerText = 'Standby';
    DOM.statStatus.className = 'text-success text-sm title-case';
    showToast('Detection system stopped');
}

async function processFrame() {
    // Native python uses CV2 FPS which is around 30 usually
    DOM.fpsCounter.innerText = `Native FPS`;

    // Ensure canvas matches image bounds (handles resize)
    DOM.canvas.width = DOM.pythonImg.clientWidth;
    DOM.canvas.height = DOM.pythonImg.clientHeight;
    const ctx = DOM.canvas.getContext('2d');
    ctx.clearRect(0, 0, DOM.canvas.width, DOM.canvas.height);

    // Fetch real inferences from the Python server
    try {
        const res = await fetch('/latest_detections');
        if (res.ok) {
            const data = await res.json();
            if (data.detections && data.detections.length > 0) {
                // Since Python draws the bounding box, we won't draw it on canvas.
                // We just log the detection in history.
                data.detections.forEach(det => {
                    // Throttle identical registrations for same item to avoid spam
                    if (Math.random() > 0.8) {
                        registerDetection(det.class, det.confidence, captureFrame(), det.severity);
                    }
                });
            }
        }
    } catch (e) {
        console.error("Failed to fetch latest detections: ", e);
    }
}

function triggerManualCapture() {
    if (!appState.isDetecting) return;
    registerDetection('Manual Flag', 1.0, captureFrame());
    showToast('Manual damage flag recorded');
}

// Capture current frame as base64
function captureFrame() {
    const tmpCanvas = document.createElement('canvas');
    tmpCanvas.width = DOM.pythonImg.naturalWidth || 1280;
    tmpCanvas.height = DOM.pythonImg.naturalHeight || 720;
    const tmpCtx = tmpCanvas.getContext('2d');
    tmpCtx.drawImage(DOM.pythonImg, 0, 0, tmpCanvas.width, tmpCanvas.height);

    // Scale down image to save storage space (localStorage limit)
    const scaleCanvas = document.createElement('canvas');
    scaleCanvas.width = 400;
    scaleCanvas.height = Math.floor(400 * (tmpCanvas.height / tmpCanvas.width));
    scaleCanvas.getContext('2d').drawImage(tmpCanvas, 0, 0, scaleCanvas.width, scaleCanvas.height);

    return scaleCanvas.toDataURL('image/jpeg', 0.6);
}

function registerDetection(type, confidence, imgData, severityOverride = null) {
    // Estimate depth randomly based on type
    let mockDepth = 0;
    if (type.toLowerCase().includes('pothole')) mockDepth = (Math.random() * (15 - 3) + 3).toFixed(1); // 3-15 cm
    else mockDepth = (Math.random() * 3).toFixed(1); // 0-3 cm

    // Calculate severity
    let severity = 'Low';
    if (severityOverride) {
        severity = severityOverride;
    } else {
        if (mockDepth > 8) severity = 'High';
        else if (mockDepth > 4) severity = 'Medium';
    }

    const detectionData = {
        id: Date.now().toString(36) + Math.random().toString(36).substr(2),
        timestamp: new Date().toISOString(),
        type: type,
        confidence: confidence,
        depth: mockDepth,
        severity: severity,
        lat: appState.currentLocation.lat.toFixed(6),
        lng: appState.currentLocation.lng.toFixed(6),
        image: imgData
    };

    appState.history.unshift(detectionData); // prepent

    // Keep max 50 items to prevent storage bloat
    if (appState.history.length > 50) appState.history.pop();

    saveHistory();
    updateDashboard();
    checkAlerts(detectionData);
}

function checkAlerts(det) {
    if (!appState.settings.alerts) return;

    let shouldAlert = false;
    const lvl = appState.settings.alertLevel;

    if (lvl === 'Low') shouldAlert = true;
    else if (lvl === 'Medium' && (det.severity === 'Medium' || det.severity === 'High')) shouldAlert = true;
    else if (lvl === 'High' && det.severity === 'High') shouldAlert = true;

    if (shouldAlert) {
        showToast(`${det.severity} severity ${det.type} logged at Lat: ${det.lat}`, 'warning');

        // Mock email logic
        if (appState.settings.email) {
            console.log(`[SIMULATION] Email sent to ${appState.settings.email} regarding ${det.id}`);
        }
    }
}

// ==========================================
// MOCK BLE (ESP32)
// ==========================================
function connectMockBle() {
    DOM.bleDot.className = 'status-dot connected';
    DOM.bleText.innerText = 'ESP32 Connected';
    DOM.bleLog.innerHTML = `<span class="text-success">>> Connection established. Receiving GPS...</span>`;
}

function animateSimulatedBleConsole() {
    setInterval(() => {
        if (!appState.isDetecting) return;

        // Small random walk for mock GPS
        appState.currentLocation.lat += (Math.random() - 0.5) * 0.001;
        appState.currentLocation.lng += (Math.random() - 0.5) * 0.001;

        const dateStr = new Date().toISOString().split('T')[1].slice(0, 8);
        const logLine = `[${dateStr}] GPS: ${appState.currentLocation.lat.toFixed(4)}, ${appState.currentLocation.lng.toFixed(4)}`;

        DOM.bleLog.innerText = logLine;
    }, 1500);
}

// ==========================================
// MAP & HISTORY MANANGEMENT
// ==========================================
function initMap() {
    leafletMap = L.map('map-container').setView([37.7749, -122.4194], 13);

    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OpenStreetMap contributors & CARTO',
        subdomains: 'abcd',
        maxZoom: 20
    }).addTo(leafletMap);

    markersLayer = L.layerGroup().addTo(leafletMap);
    populateMap();
}

function populateMap() {
    if (!leafletMap || !markersLayer) return;
    markersLayer.clearLayers();

    // Map severities to colors using custom HTML marker icon
    appState.history.forEach(det => {
        let markerColor = '#10b981'; // low
        if (det.severity === 'Medium') markerColor = '#f59e0b';
        if (det.severity === 'High') markerColor = '#ef4444';

        const customIcon = L.divIcon({
            className: 'custom-div-icon',
            html: `<div style="background-color:${markerColor}; width:16px; height:16px; border-radius:50%; border:2px solid white; box-shadow: 0 0 4px rgba(0,0,0,0.5);"></div>`,
            iconSize: [16, 16],
            iconAnchor: [8, 8]
        });

        const latlng = [parseFloat(det.lat), parseFloat(det.lng)];

        L.marker(latlng, { icon: customIcon })
            .bindPopup(`<b>${det.type}</b><br>Severity: ${det.severity}<br><button class="btn btn-primary btn-sm mt-2" onclick="openDetailModal('${det.id}')">View Details</button>`)
            .addTo(markersLayer);
    });

    if (appState.history.length > 0) {
        const latest = appState.history[0];
        leafletMap.setView([parseFloat(latest.lat), parseFloat(latest.lng)], 14);
    }
}

function switchHistoryView(viewId) {
    DOM.viewToggles.forEach(b => b.classList.remove('active'));
    document.querySelector(`[data-view="${viewId}"]`).classList.add('active');

    if (viewId === 'table') {
        DOM.viewTable.classList.add('active');
        DOM.viewTable.classList.remove('hidden');
        DOM.viewMap.classList.add('hidden');
        DOM.viewMap.classList.remove('active');
    } else {
        DOM.viewMap.classList.add('active');
        DOM.viewMap.classList.remove('hidden');
        DOM.viewTable.classList.add('hidden');
        DOM.viewTable.classList.remove('active');
        // trigger map resize correction
        setTimeout(() => leafletMap.invalidateSize(), 50);
        populateMap();
    }
}

function updateDashboard() {
    // Top stats
    DOM.statTotal.innerText = appState.history.length;
    DOM.statPotholes.innerText = appState.history.filter(d => d.type === 'Pothole').length;

    // Build Table
    DOM.historyBody.innerHTML = '';
    DOM.homeList.innerHTML = '';

    if (appState.history.length === 0) {
        DOM.historyBody.innerHTML = `<tr><td colspan="6" class="text-center text-secondary py-4">No detections recorded yet.</td></tr>`;
        DOM.homeList.innerHTML = `<li class="empty-state text-secondary text-sm text-center py-4">No recent detections</li>`;
        return;
    }

    appState.history.forEach((det, index) => {
        const dDate = new Date(det.timestamp).toLocaleString();

        // Populate Table
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td class="text-sm">${dDate}</td>
            <td class="font-bold">${det.type}</td>
            <td>${(det.confidence * 100).toFixed(1)}%</td>
            <td class="font-mono text-xs">${det.lat}, ${det.lng}</td>
            <td class="sev-${det.severity.toLowerCase()}">${det.severity}</td>
            <td>
                <button class="btn btn-outline btn-sm" onclick="openDetailModal('${det.id}')">View</button>
            </td>
        `;
        DOM.historyBody.appendChild(tr);

        // Populate Home Recent Alerts (limit to 5)
        if (index < 5) {
            const li = document.createElement('li');
            li.className = 'alert-item';
            let iconCode = 'fa-crack';
            let colorCode = 'text-warning';
            if (det.severity === 'High') {
                colorCode = 'text-error';
                iconCode = 'fa-triangle-exclamation';
            }
            li.innerHTML = `
                <div class="icon-btn bg-dark-dim"><i class="fa-solid ${iconCode} ${colorCode}"></i></div>
                <div style="flex:1;">
                    <h4 class="text-sm">${det.type} - <span class="sev-${det.severity.toLowerCase()}">${det.severity}</span></h4>
                    <p class="text-xs text-secondary">${dDate}</p>
                </div>
            `;
            DOM.homeList.appendChild(li);
        }
    });

    if (leafletMap && DOM.viewMap.classList.contains('active')) {
        populateMap();
    }
}

// ==========================================
// DETAILS MODAL
// ==========================================
window.openDetailModal = function (id) {
    const detail = appState.history.find(d => d.id === id);
    if (!detail) return;

    document.getElementById('modal-title').innerText = `Detection Record: ${id.substring(0, 8)}`;
    document.getElementById('det-class').innerText = detail.type;
    document.getElementById('det-conf').innerText = `${(detail.confidence * 100).toFixed(1)}%`;
    document.getElementById('det-depth').innerText = `${detail.depth} cm`;
    document.getElementById('det-sev').innerText = detail.severity;
    document.getElementById('det-sev').className = `sev-${detail.severity.toLowerCase()}`;
    document.getElementById('det-loc').innerText = `${detail.lat}, ${detail.lng}`;
    document.getElementById('det-time').innerText = new Date(detail.timestamp).toLocaleString();

    const imgEl = document.getElementById('modal-img');
    const phEl = document.getElementById('modal-img-placeholder');
    if (detail.image) {
        imgEl.src = detail.image;
        imgEl.classList.remove('hidden');
        phEl.classList.add('hidden');
    } else {
        imgEl.classList.add('hidden');
        phEl.classList.remove('hidden');
    }

    DOM.modal.classList.remove('hidden');
}

function closeModal() {
    DOM.modal.classList.add('hidden');
}

// ==========================================
// DATA MANAGEMENT (STORAGE)
// ==========================================
function loadSettings() {
    const storedOpts = localStorage.getItem(SETTING_KEY);
    if (storedOpts) appState.settings = JSON.parse(storedOpts);

    DOM.sThreshold.value = appState.settings.threshold;
    DOM.sThresholdVal.innerText = parseFloat(appState.settings.threshold).toFixed(2);
    DOM.sSimBle.checked = appState.settings.simBle;
    DOM.sAlerts.checked = appState.settings.alerts;
    DOM.sEmail.value = appState.settings.email;
    DOM.sLevel.value = appState.settings.alertLevel;
}

function saveSettings() {
    appState.settings = {
        threshold: parseFloat(DOM.sThreshold.value),
        simBle: DOM.sSimBle.checked,
        alerts: DOM.sAlerts.checked,
        email: DOM.sEmail.value,
        alertLevel: DOM.sLevel.value
    };

    localStorage.setItem(SETTING_KEY, JSON.stringify(appState.settings));
    showToast('Settings successfully updated.');

    // Toggle BLE status indicators
    if (appState.settings.simBle && !DOM.bleDot.classList.contains('connected')) connectMockBle();
    else if (!appState.settings.simBle) {
        DOM.bleDot.className = 'status-dot disconnected';
        DOM.bleText.innerText = 'ESP32 Disconnected';
        DOM.bleLog.innerHTML = '> Mock disabled via settings...';
    }
}

function loadHistory() {
    const storedLogs = localStorage.getItem(STORAGE_KEY);
    if (storedLogs) {
        appState.history = JSON.parse(storedLogs);
    }
}

function saveHistory() {
    // Optional: stringify without the image base64 if quota exceeded, but for now try to keep it.
    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(appState.history));
    } catch (e) {
        showToast('Storage quota exceeded, could not save image data. Trying without image...', 'warning');
        const strippedHistory = appState.history.map(d => ({ ...d, image: null }));
        localStorage.setItem(STORAGE_KEY, JSON.stringify(strippedHistory));
    }
}

function clearHistory() {
    if (confirm("Are you sure you want to permanently delete all detection logs?")) {
        appState.history = [];
        saveHistory();
        updateDashboard();
        showToast('Detection history cleared.', 'success');
        if (markersLayer) markersLayer.clearLayers();
    }
}

function exportCsv() {
    if (appState.history.length === 0) {
        showToast('No data to export.', 'warning');
        return;
    }

    const headers = ['ID', 'Timestamp', 'Type', 'Confidence', 'EstimatedDepth_cm', 'Severity', 'Latitude', 'Longitude'];
    const rows = appState.history.map(d => [
        d.id, d.timestamp, d.type, d.confidence, d.depth, d.severity, d.lat, d.lng
    ]);

    let csvContent = "data:text/csv;charset=utf-8,"
        + headers.join(',') + "\n"
        + rows.map(e => e.join(",")).join("\n");

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `road_damage_report_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link); // Required for FF
    link.click();
    link.remove();
}
