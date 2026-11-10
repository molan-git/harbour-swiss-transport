.pragma library

var BASE = "https://transport.opendata.ch/v1/";

// ---- generic GET with query params -------------------------------
function get(path, params, onDone, onFail) {
    var qs = [];
    for (var k in params) {
        var v = params[k];
        if (v !== undefined && v !== null && v !== "")
            qs.push(encodeURIComponent(k) + "=" + encodeURIComponent(v));
    }
    var xhr = new XMLHttpRequest();
    xhr.open("GET", BASE + path + (qs.length ? "?" + qs.join("&") : ""));
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try { onDone(JSON.parse(xhr.responseText)); }
                catch (e) { onFail("Bad response"); }
            } else {
                onFail("HTTP " + xhr.status);
            }
        }
    };
    xhr.send();
}

// ---- station search ----------------------------------------------
function searchStations(query, cb, err) {
    get("locations", { query: query, type: "station" },
        function(r) { cb(r.stations || []); }, err);
}

// station by id
function stationboard(stationId, limit, offset, cb, err) {
    get("stationboard", { id: stationId, limit: limit, offset: offset },
        function(r) { cb(r.stationboard || []); }, err);
}

// nearby stations around coordinates (lat, lon)
function nearby(lat, lon, cb, err) {
    get("locations", { x: lat, y: lon, type: "station" },
        function(r) { cb(r.stations || []); }, err);
}

function connections(from, to, date, time, page, cb, err) {
    get("connections",
        { from: from, to: to, date: date, time: time, page: page },
        function(r) { cb(r.connections || []); }, err);
}

// ---- date/time helpers -------------------------------------------
function pad(n) { return (n < 10 ? "0" : "") + n; }

// "2026-11-10T13:44:00+0100" -> Date
function parseIso(s) {
    if (!s) return null;
    var m = String(s).match(/^(.*)([+-])(\d{2})(\d{2})$/);
    if (m) s = m[1] + m[2] + m[3] + ":" + m[4];
    var d = new Date(s);
    return isNaN(d.getTime()) ? null : d;
}

function hhmm(s) {
    var d = parseIso(s);
    return d ? pad(d.getHours()) + ":" + pad(d.getMinutes()) : "--:--";
}

// delay in minutes from a stop object {departure, prognosis:{departure}, delay}
function delayOf(stop) {
    if (!stop) return 0;
    if (stop.delay !== undefined && stop.delay !== null) return stop.delay;
    var planned = parseIso(stop.departure);
    var actual = stop.prognosis ? parseIso(stop.prognosis.departure) : null;
    if (planned && actual)
        return Math.round((actual.getTime() - planned.getTime()) / 60000);
    return 0;
}

function fmtDuration(min) {
    var h = Math.floor(min / 60), m = min % 60;
    if (h === 0) return m + " min";
    return h + "h " + pad(m);
}

// walk duration "00:05:00" -> minutes
function walkMinutes(walk) {
    if (!walk) return 0;
    if (walk.duration) {
        var p = String(walk.duration).split(":");
        return parseInt(p[0], 10) * 60 + parseInt(p[1], 10);
    }
    return 0;
}

// distance between two stations in metres (haversine)
function distance(a, b) {
    if (!a || !b || !a.coordinate || !b.coordinate) return 0;
    var R = 6371000;
    var dLat = (b.coordinate.y - a.coordinate.y) * Math.PI / 180;
    var dLon = (b.coordinate.x - a.coordinate.x) * Math.PI / 180;
    var la1 = a.coordinate.y * Math.PI / 180;
    var la2 = b.coordinate.y * Math.PI / 180;
    var h = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(la1) * Math.cos(la2) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
    return Math.round(2 * R * Math.asin(Math.sqrt(h)));
}

function fmtDistance(m) {
    if (m < 1000) return m + " m";
    return (m / 1000).toFixed(1) + " km";
}

// line label e.g. "IC 51", "S 14", "BUS"
function lineLabel(section) {
    if (!section || !section.journey) return "";
    var j = section.journey;
    if (j.category && j.number) return j.category + " " + j.number;
    return j.category || j.name || "";
}
